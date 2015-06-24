###
#
# Tracks a particular page's history depending on the particular tab it comes from. 
#
###

getContentAndTokenize = (tabId, page) ->
  chrome.tabs.get tabId, (tab) ->
    Logger.debug "TOK:\n" + tab.url
    chrome.tabs.executeScript tabId, {code: 'window.document.documentElement.innerHTML'}, (results) ->
      html = results[0]
      if html? and html.length > 10
        $.ajax(
          type: 'POST',
          url: 'http://104.131.7.171/lda',
          data: { 'data': JSON.stringify( {'html': html} ) }
        ).success( (results) ->
          Logger.debug 'lda'
          results = JSON.parse results
          vector = results['vector']
          page = _.extend(page,{vector: results['vector'], topics: results['topics'], topic_vector: results['topic_vector'], size: results['size']})
          page.save().catch (err) ->
            Logger.error err
        ).fail (a, t, e) ->
          Logger.debug "fail tokenize\n" + t
          
          
# TODO ezhu what was this for??           
#    chrome.tabs.query {}, (tabs) ->
#      tabs.forEach (t) ->
#        chrome.tabs.sendMessage t.id, newTab: newTab

#####
#
# When a page is "loaded" enough, we can then perform any processing on it's content
#
#####
chrome.webNavigation.onDOMContentLoaded.addListener (details) ->
  return if details.frameId != 0
  uri = new URI(details.url)
  fragment = uri.fragment()
  uri.fragment("")
  return Logger.debug("Chrome internal page -- ignorning") if uri.protocol() == "chrome"
  Promise.resolve(Tab.findByTabId(details.tabId)).then (tab) ->
    throw new RecordMissingError("Can't find tab for id #{details.tabId}") if !tab
    return [
      chrome.tabs.getAsync details.tabId
      chrome.tabs.executeScriptAsync details.tabId, {code: 'window.scrollY'}
      chrome.tabs.executeScriptAsync details.tabId, {code: 'window.innerHeight'}
    ]
  .spread (tab, depth, height) ->
    db.transaction 'rw', db.Page, () ->
      db.Page.where('url').equals(uri.toString()).first().then (page) ->
        throw new RecordMissingError("Can't find page for url #{details.url}") if !page
        return page
      .then (page) ->
        #Update our page b/c we might have new information
        page.favicon = tab.favIconUrl
        page.depth = depth
        page.height = height
        page.save()
  .then (page) ->
    getContentAndTokenize(details.tabId, page)
  .catch RecordMissingError, (err) ->
    Logger.info(err)
  .catch (err) ->
    Logger.error(err)
    
# TODO ezhu I removed a couple of parameters b/c I wasnt sure what they were for: loc, and position. Maybe
# we can talk about it on slack?
    
chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
#  console.log(changeInfo)
  return if !changeInfo.url
  uri = new URI(changeInfo.url)
  fragment = uri.fragment()
  uri.fragment("")
  db.transaction 'rw', db.Tab, db.Page, db.PageVisit, () ->
    db.Page.where('url').equals(uri.toString()).first().then (page) -> #First we find (or create) the page 
      if page
        return Dexie.Promise.all([Tab.findByTabId(tabId), page])
      else
        page = new Page({url: uri.toString(), domain: uri.domain()})
        return Dexie.Promise.all([Tab.findByTabId(tabId), page.save()])
    .then (args) ->
      [tab, page] = args
      throw new RecordMissingError("Can't find Tab record for id #{tabId}") if !tab
      #Assume navigation and referrer, and correct it if we are wrong
      pageVisit = new PageVisit({page: page.id, tab: tab.id, task: tab.task, fragment: fragment, type: 'navigation'})
      if tab.pageVisit
        pageVisit.referrer = tab.pageVisit
        return Dexie.Promise.all([tab, pageVisit.save()])
      else 
        return PageVisit.forTab(tab.openerTab).mostRecent().then (link) ->
          pageVisit.referrer = link.id
          return Dexie.Promise.all([tab, pageVisit.save()])
    .then (args) ->
      [tab, pageVisit] = args
      Logger.info "Visited #{changeInfo.url} in tab #{tab.id}"
      tab.pageVisit = pageVisit.id
      tab.save()
  .catch RecordMissingError, (err) ->
    Logger.info(err)
  .catch (err) ->
    Logger.error(err)
    
#####
#
# The user has made a navigation that is considered to a particular navigation -- we want to track this transition
#
#####
chrome.webNavigation.onCommitted.addListener (details) ->
  return if details.frameId != 0
  Logger.info "page load nav: #{details.tabId} -> #{details.url}"
  uri = new URI(details.url)
  fragment = uri.fragment()
  uri.fragment("")
  db.transaction 'r', db.Page, () ->
    db.Page.where('url').equals(uri.toString()).first()
  .then (page) ->
    throw new RecordMissingError("Can't find Page record for url #{details.url}") if !page
    db.transaction 'rw', db.PageVisit, db.Tab, db.Task, () ->
      Tab.findByTabId(details.tabId).then (tab) ->
        throw new RecordMissingError("Can't find Tab record for id #{details.tab}") if !tab
        #Find the PageVisit created in the tabs.onUpdated function
        return Dexie.Promise.all([tab, page, db.PageVisit.get(tab.pageVisit)])
      .then (args) ->
        [tab, page, pageVisit] = args
        #Make sure we found the one we just created
        throw new RecordMissingError("Can't find Visit record for #{details.tab}") if !pageVisit or pageVisit.page is not page.id
        if details.transitionQualifiers.indexOf("forward_back") >= 0 #We used the navigation arrows -- simple visit
          #We probably want this to be the task it was before?? (the tab's task might have switched)
          return PageVisit.forId(pageVisit.referrer).then (oldVisit) ->
            pageVisit.task = oldVisit.task
            #TODO figure out more specificially if we went back?
            pageVisit.type = "forward_back"
            return Dexie.Promise.all([tab, pageVisit.save()])
        else
          switch details.transitionType
            when "link" or "auto_bookmark" # If this is a link -- record the reference and keep the same task
              pageVisit.type = if details.transitionType is "link" then "linked" else "navigation"
            when "typed" # If this was type, generate a new task
              pageVisit.task = Task.generateTask()
              pageVisit.type = "typed"
              pageVisit.referrer = ''
              #TODO -- we could possible infer that the user opened this up from their history?? IDK
            when "reload" #We really don't want to record this in this instance -- find the last page visit and record it
              #TODO manage reload here
              console.log('reload?')
            when "start_page" #Don't record this.....
              throw new Promise.CancellationError('Detected start page -- ignoring')
            when "form_submit" #Not sure what to do here exactly... 
              pageVisit.type = "linked"
            when "generated" # in this case the user is probably typing in what they want? Close to a task
              throw new Promise.CancellationError('Detected generated -- ignoring')
            else
              throw new Promise.CancellationError("Unknown navigation #{details.transitionType}")
          return Dexie.Promise.all([tab, pageVisit.save()])
      .then (args) ->
        [tab, pageVisit] = args
        tab.task = pageVisit.task
        tab.save()
  .catch Promise.CancellationError, (err) ->
    Logger.info "#{err}"
  .catch RecordMissingError, (err) ->
    Logger.info(err)
  .catch (err) ->
    Logger.error(err)
    


    
 ####
 #
 # TODO onTabReplaced for chrome instant pre-rendered content?
 #
 ####
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

###
# Updates the page information with callback info about the dom
###
domInfo = (url, tab) ->
  Promise.all([
      chrome.tabs.getAsync tab.tab
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.scrollY'}
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.innerHeight'}
  ]).spread (tab, depth, height) ->  
    db.transaction 'rw', db.Page, () ->
      db.Page.where('url').equals(url).first().then (page) ->
        throw new RecordMissingError("Can't find page for url #{url}") if !page
        return page
      .then (page) ->
        #Update our page b/c we might have new information
        page.favicon = tab.favIconUrl
        page.depth = depth
        page.height = height
        page.save()
  .delay(500).then (page) ->
    getContentAndTokenize(tab.tab, page)
    
###
# When a page is "loaded" enough, we can then perform any processing on it's content
###
chrome.webNavigation.onDOMContentLoaded.addListener (details) ->
  return if details.frameId != 0
  uri = new URI(details.url)
  return Logger.debug("Chrome internal page -- ignorning") if uri.protocol() == "chrome"
  Promise.resolve(Tab.findByTabId(details.tabId)).then (tab) ->
    throw new RecordMissingError("Can't find tab for id #{details.tabId}") if !tab
    domInfo(details.url, tab)
  .catch RecordMissingError, (err) ->
    Logger.info(err)
  .catch ChromeError, (err) ->
    Logger.info(err)
  .catch (err) ->
    Logger.error(err)
    
# TODO ezhu I removed a couple of parameters b/c I wasnt sure what they were for: loc, and position. Maybe
# we can talk about it on slack?
    
chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
#  console.log(changeInfo)
  return if !changeInfo.url
  Logger.debug "Visited #{changeInfo.url} in tab #{tab.id}"
  db.transaction 'rw', db.Tab, db.Page, db.PageVisit, db.Task, () ->
    db.Page.where('url').equals(changeInfo.url).first().then (page) -> #First we find (or create) the page 
      Dexie.Promise.all([Tab.findByTabId(tabId), if page then page else Page.generatePage(changeInfo.url)])
    .then (args) ->
      [tab, page] = args
      throw new RecordMissingError("Can't find Tab record for id #{tabId}") if !tab
      #Assume navigation and referrer, and correct it if we are wrong
      return Dexie.Promise.all([Task.generateTask(tab, page), tab, page])
    .then (args) ->
      [task, tab, page] = args
      pageVisit = new PageVisit({page: page.id, tab: tab.id, task: task.id, type: 'navigation'})
      if !tab.pageVisit and tab.openerTab 
        return PageVisit.forTab(tab.openerTab).mostRecent().then (link) ->
          pageVisit.referrer = link.id
          return Dexie.Promise.all([tab, pageVisit.save()])
      else
        pageVisit.referrer = tab.pageVisit
        return Dexie.Promise.all([tab, pageVisit.save()])
    .then (args) ->
      [tab, pageVisit] = args
      tab.pageVisit = pageVisit.id
      tab.save()
  .catch RecordMissingError, (err) ->
    Logger.info(err)
  .catch (err) ->
    Logger.error(err)   
 
###
# The user has made a navigation that is considered to a particular navigation -- we want to track this transition
###
chrome.webNavigation.onCommitted.addListener (details) ->
  return if details.frameId != 0
  Logger.debug "page nav: #{details.tabId} -> #{details.url}"
  console.log(details)
  
  addDetails(details)
    
chrome.webNavigation.onReferenceFragmentUpdated.addListener (details) ->
  return if details.frameId != 0
  Logger.debug "fragment nav: #{details.tabId} -> #{details.url}"
  addDetails(details)

#####
#
# Add additional details to the navigation event
#
#####

addDetails = (details) ->
  db.transaction 'rw', db.PageVisit, db.Tab, db.Task, db.Page, () ->
    Dexie.Promise.all([
      Tab.findByTabId(details.tabId)
      db.Page.where('url').equals(details.url).first()
    ]).then (args) ->
      [tab, page] = args
      if !tab #We have a chrome instant tab in this case -- generate a temporary one for it
        tab = new Tab({tab: details.tabId, openerTab: -1, status: 'temp'})
        return Dexie.Promise.all([tab.save(), Page.generatePage(details.url)]).then (args) ->
          [tab, page] = args
          pageVisit = new PageVisit({page: page.id, tab: tab.id, task: '', type: 'generated'})
          return Dexie.Promise.all([tab, page, pageVisit.save()])
        .then (args) ->
          [tab, page, pageVisit] = args
          tab.pageVisit = pageVisit.id
          return Dexie.Promise.all([tab.save(), page, pageVisit])
      else 
        throw new RecordMissingError("Can't find Page record for url #{details.url}") if !page
        #Find the PageVisit created in the tabs.onUpdated function
        return Dexie.Promise.all([tab, page, db.PageVisit.get(tab.pageVisit)])
    .then (args) ->
      [tab, page, pageVisit] = args
      #Make sure we found the one we just created
      throw new RecordMissingError("Can't find Visit record for #{details.tab}") if !pageVisit or pageVisit.page is not page.id
      if details.transitionQualifiers.indexOf("forward_back") >= 0 #We used the navigation arrows -- simple visit
        #We probably want this to be the task it was before?? (the tab's task might have switched)
        return PageVisit.find(pageVisit.referrer).then (oldVisit) ->
          pageVisit.task = oldVisit.task
          #TODO figure out more specificially if we went back?
          pageVisit.type = "forward_back"
          return Dexie.Promise.all([tab, pageVisit.save()])
      else
        switch details.transitionType
          when "link" # If this is a link -- record the reference and keep the same task
            pageVisit.type = "link"
          when "typed" # If this was type, generate a new task
            pageVisit.type = "typed"
            pageVisit.referrer = ''
            return Task.generateTask(tab, page, true).then (task) ->
              pageVisit.task = task.id
              return Dexie.Promise.all([tab, pageVisit.save()])
            #TODO -- we could possible infer that the user opened this up from their history?? IDK
          when "auto_bookmark"
            pageVisit.type = "bookmark"
            pageVisit.referrer = ''
            return Task.generateTask(tab, page, true).then (task) ->
              pageVisit.task = task.id
              return Dexie.Promise.all([tab, pageVisit.save()])
          when "reload" #We really don't want to record this in this instance -- find the last page visit and record it
            #TODO manage reload here
            console.log('reload?')
          when "start_page" #Don't record this.....
            throw new Promise.CancellationError('Detected start page -- ignoring')
          when "form_submit" #Not sure what to do here exactly... 
            pageVisit.type = "link"
          when "generated" # in this case the user is probably typing in what they want? Close to a task
            pageVisit.type = "typed"
            pageVisit.referrer = ''
            return Task.generateTask(tab, page, true).then (task) ->
              pageVisit.task = task.id
              return Dexie.Promise.all([tab, pageVisit.save()])          
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
# Fill in any information if we have visted 
#
####
chrome.webNavigation.onTabReplaced.addListener (details) ->
  Logger.debug "Replacing tab #{details.replacedTabId} with #{details.tabId}"
  db.transaction 'rw', db.PageVisit, db.Tab, db.Task, db.Page, () ->
    db.Tab.where('tab').equals(details.tabId).and((tab) -> tab.status is 'temp').first().then (newTab) ->
      throw new RecordMissingError("Can't find instant tab for #{details.tabId}") if !newTab
      Dexie.Promise.all([newTab, Tab.findByTabId(details.replacedTabId), db.PageVisit.get(newTab.pageVisit)])
    .then (args) ->
      [newTab, replacedTab, pageVisit] = args
      throw new RecordMissingError("Can't find existing tab for #{details.replacedTabId}") if !replacedTab
      Dexie.Promise.all([newTab, replacedTab, pageVisit, db.Page.get(pageVisit.page)])
    .then (args) ->
      [newTab, replacedTab, pageVisit, page] = args
      replacedTab.tab = newTab.tab
      pageVisit.tab = replacedTab.id
      if !newTab.task
        return Task.generateTask(tab, page, true).then (task) ->
          pageVisit.task = task.id
          replacedTab.task = task.id
          Dexie.Promise.all([replacedTab.save(), pageVisit.save(), newTab])
      if pageVisit.type == "link"
        pageVisit.task = newTab.task
        replacedTab.task = newTab.task
      else
        pageVisit.task = replacedTab.task
      Dexie.Promise.all([replacedTab.save(), pageVisit.save(), newTab])
    .then (args) ->
      [replacedTab, pageVisit, newTab] = args
      return Dexie.Promise.all([newTab.delete(), Page.find(pageVisit.page), replacedTab])
  .then (args) ->
    [oldTab, page, curTab] = args
    domInfo(page.url, curTab)
  .catch Promise.CancellationError, (err) ->
    Logger.warn "#{err}"
  .catch (err) ->
    Logger.error(err)
    
chrome.history.onVisited.addListener (item) ->
  console.log(item)
    
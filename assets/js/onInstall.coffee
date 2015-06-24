#####
#
# File for methods executed on installation of this extension (or refresh)
# TODO DRY this up some how.... 
#
#####

(() ->
  # Record all of the currently open tabs that we haven't mentioned before.
  chrome.runtime.onInstalled.addListener () ->
    startupCheck()
  chrome.runtime.onStartup.addListener () ->
    console.log('extension started!')
    startupCheck()
  document.addEventListener "DOMContentLoaded", (event) ->
    startupCheck()

  #Method called when either our extension is installed, or reloaded
  startupCheck = () ->
    chrome.tabs.queryAsync({}).then (tabs) ->
      Promise.map tabs, (tab) ->
        Tab.findByTabId(tab.id).then (existingTab) ->
          return Promise.resolve(if existingTab then existingTab else createTabEntry(tab)).then (tab) ->
            checkPageVisit(tab) 
      .then (tabs) ->
        #Do something with the newly created tabs here
        
  #Create an entry for a tab that isn't being tracked yet
  createTabEntry = (chromeTab) ->
    resolve = []
    tab = new Tab({
      tab: chromeTab.id
      windowId: chromeTab.windowId
      position: chromeTab.index
    })
    resolve.push Task.generateTask().then (task) ->
      return task.id

    Promise.all(resolve).spread (task) ->
      tab.task = task
      tab.save()
    .then (tab) ->
      recordAction(tab, 'created', tab.openerTab, tab.id)
      return tab
    .catch RecordMissingError, (err) ->
      Logger.warn(err)

  #Check if we have the most up-to-date PageVisit associated with our tab
  checkPageVisit = (tab) ->
    chrome.tabs.getAsync(Number.parseInt(tab.tab)).then (chromeTab) ->
      uri = new URI(chromeTab.url)
      fragment = uri.fragment()
      uri.fragment("")
      if tab.pageVisit
        Promise.resolve(PageVisit.forId(tab.pageVisit)).then (pageVisit) ->
          [pageVisit, Page.forId(pageVisit.page)]
        .spread (pageVisit, page) ->
          #check if we are on the right page
          if page.url != uri.toString() or pageVisit.fragment != fragment
            createPageVisit(tab, chromeTab, uri, fragment)
      else
        createPageVisit(tab, chromeTab, uri, fragment)

  #Create PageVisits for any tabs that aren't up to date
  createPageVisit = (tab, chromeTab, uri, fragment) ->
    Promise.resolve(db.Page.where('url').equals(uri.toString()).first()).then (page) -> #First we find (or create) the page 
      return page if page
      page = new Page({url: uri.toString(), domain: uri.domain()})
      if uri.protocol() == "chrome" then Logger.debug("Chrome internal page -- ignorning") else getContentAndTokenize(chromeTab, page)
      return page.save()
    .then (page) ->
      throw new RecordMissingError("Can't find Tab record for id #{tabId}") if !tab
      #Assume navigation and referrer, and correct it if we are wrong
      pageVisit = new PageVisit({page: page.id, tab: tab.id, task: tab.task, fragment: fragment, type: 'navigation'})
      return [tab, pageVisit.save()]
    .spread (tab, pageVisit) ->
      Logger.info "Visited #{chromeTab.url} in tab #{tab.id}"
      tab.pageVisit = pageVisit.id
      tab.save()
    #Find the page
    
  # Get the content (async) of any new pages we added to the DB
  getContentAndTokenize = (tab, page) ->
    Logger.debug "TOK:\n" + tab.url
    chrome.tabs.executeScript tab.id, {code: 'window.document.documentElement.innerHTML'}, (results) ->
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

)()
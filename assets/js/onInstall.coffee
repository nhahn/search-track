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
        Promise.all([
          db.Page.where('url').equals(tab.url).first().then (page) -> #First we find (or create) the page 
            return page if page
            return Page.generatePage(tab.url)
          Tab.findByTabId(tab.id)
        ]).spread (page, existingTab) ->
          return Promise.resolve(if existingTab then existingTab else createTabEntry(tab, page)).then (tab) ->
            if page.url.match(/^chrome/) then Logger.debug("Chrome internal page -- ignorning") else getContentAndTokenize(tab, page)
            checkPageVisit(tab, page)
      .then (tabs) ->
        #Do something with the newly created tabs here
        
  #Create an entry for a tab that isn't being tracked yet
  createTabEntry = (chromeTab, page) ->
    resolve = []
    tab = new Tab({
      tab: chromeTab.id
      windowId: chromeTab.windowId
      position: chromeTab.index
    })
    resolve.push Task.generateBaseTask(tab, page, true).then (task) ->
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
  checkPageVisit = (tab, page) ->
    chrome.tabs.getAsync(Number.parseInt(tab.tab)).then (chromeTab) ->
      if tab.pageVisit
        Promise.resolve(PageVisit.find(tab.pageVisit)).then (pageVisit) ->
          #check if we are on the right page
          if page.url != chromeTab.url
            createPageVisit(tab, chromeTab, page)
      else
        createPageVisit(tab, chromeTab, page)

  #Create PageVisits for any tabs that aren't up to date
  createPageVisit = (tab, chromeTab, page) ->
    #Assume navigation and typed
    pageVisit = new PageVisit({page: page.id, tab: tab.id, task: tab.task, type: 'typed'})
    pageVisit.save().then (pageVisit) ->
      Logger.info "Visited #{chromeTab.url} in tab #{tab.id}"
      tab.pageVisit = pageVisit.id
      tab.save()
    #Find the page
    
  # Get the content (async) of any new pages we added to the DB
  getContentAndTokenize = (tab, page) ->
    Logger.debug "TOK:\n" + page.url
    Promise.all([
      chrome.tabs.getAsync tab.tab
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.document.documentElement.innerHTML'}
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.scrollY'}
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.innerHeight'}
    ]).spread (chromeTab, results, depth, height) ->
      html = results[0]
      page.favicon = chromeTab.favIconUrl
      page.depth = depth
      page.height = height
      page.title = chromeTab.title
      if tab.task
        db.transaction 'rw', db.Task, () ->
          db.Task.get(tab.task).then (task) ->
            task.nameTempTask(page)
      page.save().then (page) ->
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
              console.log(page)
              Logger.error err
          ).fail (a, t, e) ->
            Logger.debug "fail tokenize\n" + t

)()

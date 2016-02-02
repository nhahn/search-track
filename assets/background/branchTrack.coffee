####
# This is where we update a URL for a tab we are tracking. Any change in a tab's URL happens here
####
chrome.webNavigation.onCommitted.addListener (details) ->
  return if details.frameId != 0
  db.transaction 'rw', db.Branch, db.Tab, db.PageVisit, db.Page, () =>
    Tab.findByTabId(details.tabId).then (tab) =>
      #If we can't find the tab, create a temporary one
      return Dexie.Promise.all([
        if tab then tab else Tab.createTemp(details), 
        Page.findOrCreate(details.url)
      ])
    .then (args) ->
      [tab, page] = args
      #figure out what branch we should be on
      tab.determineBranch(details, page)
    #If that tab doesn't exist, we are doing some background loading temp tab nonsense
    #these tabs might be switched to, but there is no guarantee.
  .catch (err) ->
    console.error(err)
  
####
# Alternative to onCommitted when we are just updating part of a web page
####
chrome.webNavigation.onReferenceFragmentUpdated.addListener (details) ->
  return if details.frameId != 0
  db.transaction 'rw', db.Branch, db.Tab, db.PageVisit, db.Page, () =>
    Dexie.Promise.all([
      Tab.findByTabId(details.tabId)
      Page.findOrCreate(details.url)
    ]).then (args) =>
      [tab, page] = args
      tab.determineBranch(details, page)
      # Reference fragment updates don't send a dom content loaded -- 
      # make sure to capture new content information for the URL
      domInfo(page, tab)
  .catch (err) ->
    console.error(err)
####
# Take a temporary tab, and replace an existing tab with it
####
chrome.webNavigation.onTabReplaced.addListener (details) ->
  db.transaction 'rw', db.Branch, db.Tab, db.PageVisit, db.Page, () =>
    Dexie.Promise.all([
      Tab.findByTabId(details.tabId),
      Tab.findByTabId(details.replacedTabId)
    ]).then (args) ->
      [newTab, originalTab] = args
      originalTab.replace(newTab)
    .then (args) ->
      [tab] = args
      Dexie.Promise.all([tab, PageVisit.find(tab.pageVisit)])
    .then (args) ->
      [tab, pageVisit] = args
      Dexie.Promise.all([tab, Page.find(pageVisit.page)])
    .then (args) ->
      [tab, page] = args
      domInfo(page, tab) #Do the page processing for on the replaced page
  .catch (err) ->
    console.error(err)
####
# Link a new tab to an existing tab's stream as a parent
####
chrome.webNavigation.onCreatedNavigationTarget.addListener (details) ->
  db.transaction 'rw', db.Branch, db.Tab, db.PageVisit, db.Page, () =>
    Dexie.Promise.all([
      Tab.findByTabId(details.tabId),
      Tab.findByTabId(details.sourceTabId)
    ]).then (args) ->
      [tab, originalTab] = args
      tab.forkTab(originalTab)
  .catch (err) ->
    console.error(err)  
####
# When the page has finished loading -- we can get some of the content and parse it
####
chrome.webNavigation.onDOMContentLoaded.addListener (details) ->
  return if details.frameId != 0
  uri = new URI(details.url)
  return console.debug("Chrome internal page -- ignorning") if uri.protocol() == "chrome"
  Dexie.Promise.all([
    Tab.findByTabId(details.tabId)
    Page.findByUrl(details.url)
  ]).then (args) ->
    [tab, page] = args
    throw new RecordMissingError("Can't find tab for id #{details.tabId}") if !tab
    throw new RecordMissingError("Temp tabs ignored") if tab.status is 'temp' #Don't process temporary tabs -- chrome won't let us
    throw new RecordMissingError("Can't find page for url #{details.url}") if !page
    domInfo(page, tab)
  .catch RecordMissingError, (err) ->
    console.info(err)
  .catch ChromeError, (err) ->
    console.info(err)
  .catch (err) ->
    console.error(err)  
  

getContentAndTokenize = (tabId, page) ->
  chrome.tabs.get tabId, (tab) ->
    console.debug "TOK:\n" + tab.url
    chrome.tabs.executeScriptAsync(tabId, {code: 'window.document.documentElement.innerHTML'}).then (results) ->
      html = results[0]
      if html? and html.length > 10
        $.ajax(
          type: 'POST',
          url: 'http://104.131.7.171/lda',
          data: { 'data': JSON.stringify( {'html': html} ) }
        ).success( (results) ->
          console.debug 'lda'
          results = JSON.parse results
          vector = results['vector']
          page = _.extend(page,{vector: results['vector'], topics: results['topics'], topic_vector: results['topic_vector'], size: results['size']})
          page.time = Date.now()
          page.save().catch (err) ->
            console.info "Tokenize error on obj"
            console.info page
        ).fail (a, t, e) ->
          console.debug "fail tokenize\n" + t
    .catch (err) ->
      console.info("Tokenize error!")

###
# Updates the page information with callback info about the dom
###
domInfo = (page, tab) ->
  chrome.tabs.getAsync(tab.tab).then (chromeTab) ->
    page.favicon = chromeTab.favIconUrl
    page.title = chromeTab.title
    page.save().then (page) ->
      if page.time > Date.now() - 3600000 #Dont bother getting the content if we have done this in the past hour
        getContentAndTokenize(tab.tab, page)
    

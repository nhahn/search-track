###
	Background page for the Forager part of the extension 
###

# user marks tab as "for later"

add = (importance) ->
  console.log SavedInfo.db().get()
  tab = {}
  chrome.tabs.query {
    currentWindow: true
    active: true
  }, (tabs) ->
    chromeTab = tabs[0]
    tab.time = Date.now()
    tab.timeElapsed = 0
    # Find first empty spot to place tab
    db = SavedInfo.db().filter(importance: importance).get()
    locs = []
    i = 0
    while i < db.length
      locs.push db[i].loc
      i++
    tab.loc = 0
    for i of locs.sort()
      `i = i`
      if locs[i] == tab.loc
        tab.loc++
    tab.tabId = chromeTab.id
    tab.favicon = chromeTab.favIconUrl
    ttl = chromeTab.title
    if ttl.length == 0
      ttl = prompt('Please name this page', 'Untitled')
    tab.title = ttl
    tab.url = chromeTab.url
    tab.note = ''
    tab.color = 'rgba(219,217,219,1)'
    tab.importance = importance
    tab.depth = window.scrollY
    tab.height = window.innerHeight
    console.log 'My Depth: ' + tab.depth
    console.log 'Total Depth: ' + document.body.clientHeight
    # for the drag-and-drop list (could be adapted for 2D manipulation)
    tab.position = SavedInfo.db().count()
    # will be able to "favorite" tabs
    tab.favorite = false
    # is it a reference tab?
    tab.ref = false
    #TODO: TASK DB, then get the right task. Where do I record the current task? I'll have to send a message?
    tab.task = ''
    # add to DB.
    annotation = SavedInfo.db().get()[0].annotation
    SavedInfo.db.insert tab
    # Tell tabs
    chrome.tabs.query {}, (tabs) ->
      tabs.forEach (t) ->
        chrome.tabs.sendMessage t.id, newTab: tab
        return
      return
    return
  # Originally was using a context script here to get page depth information and user highlights on page

  ### chrome.tabs.executeScript(
    null, {file: '/vendor/taffydb/taffy-min.js', runAt: "document_start"}, function() {
    chrome.tabs.executeScript(
    null, {file: '/vendor/underscore/underscore-min.js', runAt: "document_start"}, function() {
    chrome.tabs.executeScript(
    null, {file: '/js/trackAPI.js', runAt: "document_start"}, function() {
    chrome.tabs.executeScript(
    null, {file: '/js/content/content.js', runAt: "document_start"}, function() {
    chrome.tabs.query({'currentWindow': true, 'active': true}, function(tabs) {
      activeId = tabs[0].id;
          // chrome.tabs.remove(activeId);
     });});});});}); 
  ###

  return

open = ->
  console.log 'triggered'
  # Opens or closes the sidebar in the current page.
  chrome.tabs.executeScript null,
    file: '/js/content/openclose.js'
    runAt: 'document_start'
  return

task = 'default'
console.log task
currentTab = undefined
lastTab = undefined
SavedInfo.db.insert(annotation: '').callback ->
  SavedInfo.db().update annotation: ''
  # Inject sidebar to every updated page
  # Unfortunately, it does so a few times because onUpdated gets called a bunch of times
  chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
    Promise.all([
      chrome.tabs.insertCSSAsync(null, {file: '/css/sidebar.css', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/vendor/jquery/dist/jquery.min.js', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/vendor/taffydb/taffy-min.js', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/vendor/underscore/underscore-min.js', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/js/trackAPI.js', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/vendor/angular/angular.js', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/vendor/bootstrap/dist/js/bootstrap.min.js', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/js/interact.min.js', runAt: 'document_start'})
      chrome.tabs.executeScriptAsync(null, {file: '/js/content/injectsidebar.js', runAt: 'document_start'})
    ]).then () ->
      return chrome.tabs.queryAsync({
        currentWindow: true
        active: true
      })
    .then (tabs) ->
      chrome.tabs.sendMessage tabs[0].id, {
        currentDb:
          tabs: SavedInfo.db().get()
           annotation: SavedInfo.db().get()[0].annotation
          tabId: tabs[0].id
      }
      
# Message passing from content scripts and new tab page
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log if sender.tab then 'from a content script:' + sender.tab.url else 'from the extension'
  if request.newTask
    task = request.task

    ###
      } else if (request.newVisual) {
    	chrome.runtime.sendMessage({task: task}, function(response) {
    		console.log('sent current task'); // doesn't work 
       		});
    ###

  else if request.changedAnnotation
    # annotation changed
    chrome.tabs.query {}, (tabs) ->
      # changed a tab's note - tell others
      tabs.forEach (tab) ->
        chrome.tabs.sendMessage tab.id, newAnnotation: request.changedAnnotation
        return
      sendResponse farewell: 'changed'
      return
  else if request.changedLoc
    # dragged tab to new location on some page - tell others
    chrome.tabs.query {}, (tabs) ->
      tabs.forEach (tab) ->
        chrome.tabs.sendMessage tab.id, newLoc: request.changedLoc
        return
      sendResponse farewell: 'moved'
      return
  else if request.deleted
    # deleted a tab - tell others
    chrome.tabs.query {}, (tabs) ->
      tabs.forEach (tab) ->
        chrome.tabs.sendMessage tab.id, delTab:
          'id': request.deleted.id
          'tabId': request.deleted.tabId
        return
      # Potentially can remove tab from window as well
      sendResponse farewell: 'deleted'
      return
  else if request.changeUrl
    chrome.tabs.update request.changeUrl[0], { selected: true }, ->
      if chrome.runtime.lastError
        chrome.tabs.create 'url': request.changeUrl[1]
      return
  else if request.changedNote
    chrome.tabs.query {}, (tabs) ->
      # changed a tab's note - tell others
      tabs.forEach (tab) ->
        chrome.tabs.sendMessage tab.id, newNote: request.changedNote
        return
      sendResponse farewell: 'new note'
      return
  else if request.changedColor
    # changed a tab's color - tell others
    chrome.tabs.query {}, (tabs) ->
      tabs.forEach (tab) ->
        chrome.tabs.sendMessage tab.id, newColor: request.changedColor
        return
      sendResponse farewell: 'new color'
      return

  ### TODO: automatic scroll down on a page that's re-opened	
  		else if (request.scrollDown != 0) {
  setTimeout(function() {
  	chrome.tabs.executeScript(
  		null, {file: '/js/scroll.js', runAt: "document_start"}, function() {});
  	chrome.runtime.sendMessage({down: request.scrollDown}, function() {});
    }, 5000);
  		}
  ###

  return
chrome.commands.onCommand.addListener (command) ->
  # Call 'update' with an empty properties object to get access to the current
  # tab (given to us in the callback function).
  chrome.tabs.update {}, (tab) ->
    if command == 'add-importance-1'
      add 1
    else if command == 'add-importance-2'
      add 2
    else if command == 'open'
      open()
    return
  return
# Max at 9 tabs
chrome.tabs.onCreated.addListener (tab) ->
  chrome.tabs.query { currentWindow: true }, (tabs) ->
    if tabs.length > 9
      alert 'Too many tabs!'
      chrome.tabs.remove tab.id, ->
    return
  return

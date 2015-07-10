###
	Background page for the Forager part of the extension 
###

chrome.storage.sync.set({bottom: true})

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

open = ->
  console.log 'triggered'
  # Opens or closes the sidebar in the current page.
  chrome.tabs.query {currentWindow:true, active:true}, (tabs) ->
    chrome.tabs.sendMessage tabs[0].id, {changeSize: true}

addToBlacklist = (url) ->
  uri = new URI(url)
  base = uri.protocol() + "://" + uri.host() + "/" + uri.pathname().split("/")[0]
  chrome.storage.sync.get('blacklist', (items) ->
    if typeof items.blacklist == 'undefined'
      chrome.storage.sync.set({'blacklist': [base]})
    else
      chrome.storage.sync.set(
        {'blacklist': items.blacklist.concat([base])}
      )
  )

removeFromBlacklist = (url) ->
  uri = new URI(url)
  base = uri.protocol() + "://" + uri.host() + "/" + uri.pathname().split("/")[0]
  chrome.storage.sync.get('blacklist', (items) ->
    if items.blacklist.indexOf(base) == -1
      return
    else
      console.log items.blacklist.splice(items.blacklist.indexOf(base), 1)
      chrome.storage.sync.set(
        {'blacklist': items.blacklist.splice(items.blacklist.indexOf(base), 1)}
      )
  )

chrome.contextMenus.create({contexts: ['browser_action'], title: "Blacklist this site", onclick: (info, tab) ->
  addToBlacklist (tab.url)
  chrome.tabs.executeScript(tab.id, {code: "$('#injectedsidebar').hide(); delete injected", runAt: "document_start"})
})

chrome.contextMenus.create({contexts: ['browser_action'], title: "Remove this site from blacklist", onclick: (info, tab) ->
  # TODO add sidebar to this page
  removeFromBlacklist (tab.url)
  chrome.tabs.query {currentWindow: true, active: true}, (tabs) ->
    chrome.tabs.executeScript(tabs[0].id, {file:"/vendor/jquery/dist/jquery.min.js", runAt: "document_start"}, () ->
      chrome.tabs.executeScript(tabs[0].id, {file:"/js/content/injectsidebar.js", runAt: "document_start"})
    )
})

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  # Check if bar is set to top or bottom
  chrome.storage.sync.get('bottom', (items) ->
    chrome.tabs.query({active: true, currentWindow: true}, (tabs) ->
      if !items.bottom
        chrome.tabs.sendMessage(tabs[0].id, {tOp: true})
    )
  )

  # Check if page is on blacklist
  chrome.storage.sync.get "blacklist", (items) ->
    return if typeof items.blacklist == 'undefined'
    # can't figure out how to do this with a comprehension
    for item in items.blacklist
      if tab.url.includes(item)
        # race condition?
        chrome.tabs.executeScript(tabId, {code: "$('#injectedsidebar').hide(); delete injected", runAt: "document_start"})

  # Make bar full size if in fullscreen mode
  chrome.windows.getCurrent({}, (window) ->
    console.log window.state
    if window.state == 'fullscreen'
      chrome.tabs.query {currentWindow:true, active:true}, (tabs) ->
        # TODO this is too slow!
        chrome.tabs.sendMessage tabs[0].id, {changeSize: true}
  )

chrome.tabs.onCreated.addListener (tabId, changeInfo, tab) ->
  # Max at 9 tabs
#  chrome.tabs.query { currentWindow: true }, (tabs) ->
#    if tabs.length > 9
#      alert 'Too many tabs! ' + tab.id
#      chrome.tabs.remove tab.id

  # Check if bar is set to top or bottom
  chrome.storage.sync.get('bottom', (items) ->
    chrome.tabs.query({active: true, currentWindow: true}, (tabs) ->
      if !items.bottom
        chrome.tabs.sendMessage(tabs[0].id, {tOp: true})
    )
  )

  # Check if page is on blacklist
  chrome.storage.sync.get "blacklist", (items) ->
    console.log items

    return if typeof items.blacklist == 'undefined'
    for item in items.blacklist
      if tab.url.includes(item)
        # race condition?
        chrome.tabs.executeScript(tabId, {code: "$('#injectedsidebar').hide(); $('body').css('margin-top', '0px'); $('#viewport').css('top','0'); $('body').css('padding-bottom',0); delete injected", runAt: "document_start"})

  # Make bar full size if in fullscreen mode
  chrome.windows.getCurrent({}, (window) ->
    console.log window.state
    if window.state == 'fullscreen'
      chrome.tabs.query {currentWindow:true, active:true}, (tabs) ->
        chrome.tabs.sendMessage tabs[0].id, {changeSize: true}
  )


adjustHeight = (height, tabId) ->
  chrome.tabs.executeScript(tabId, {code: "$('#injectedsidebar').height(#{height}); $('body').css('padding-bottom', #{height} + $('body').css('padding-bottom'));", runAt: "document_start"})

  # Check if bar is set to top or bottom
  chrome.storage.sync.get('bottom', (items) ->
    chrome.tabs.query({active: true, currentWindow: true}, (tabs) ->
      if items.bottom
        chrome.tabs.executeScript(tabId, {code: "$('body').css('padding-bottom',#{height})", runAt: "document_start"})
      else
        chrome.tabs.executeScript(tabId, {code: "$('body').css('margin-top', '#{height}px'); $('#viewport').css('top','#{height}px');", runAt: "document_start"})
    )
  )


# Message passing from content scripts and new tab page
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log if sender.tab then 'from a content script:' + sender.tab.url else 'from the extension'
  if request.blacklist
    addToBlacklist(sender.tab.url)
    console.log "blacklisted " + sender.tab.url
  else if request.removeSidebar
    chrome.tabs.executeScript(sender.tab.id, {code: "$('#injectedsidebar').hide(); delete injected", runAt: "document_start"})
    chrome.tabs.executeScript(sender.tab.id, {code: "$('body').css('margin-top', '0px'); $('#viewport').css('top','0'); $('body').css('padding-bottom',0)", runAt: "document_start"})
  else if request.minimize
    adjustHeight(28, sender.tab.id)
  else if request.maximize
    adjustHeight(129, sender.tab.id)
  else if request.changeLocation
    # Check if bar is set to top or bottom
    chrome.storage.sync.get('bottom', (items) ->
      console.log items.bottom
      chrome.storage.sync.set(
        {'bottom': !items.bottom}
      )
      chrome.tabs.query({active: true, currentWindow: true}, (tabs) ->
        if !items.bottom # do opposite
          chrome.tabs.sendMessage(tabs[0].id, {bottom: true})
        else
          chrome.tabs.sendMessage(tabs[0].id, {tOp: true})
      )
    )
  else if request.getCurrentTab
    chrome.tabs.query({active: true, currentWindow: true}, (tabs) ->
      sendResponse(tabs)
    )
    return true
    
 
###
  if request.newTask
    task = request.task

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
    return 
  return


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

###

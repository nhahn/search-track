recordAction = (tab, action, from, to) ->
  data = new TabEvent({type: action, tab: tab.id, from: from, to: to})
  data.save()

# Update this in searchTrack?? TODO
#chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
#  if not changeInfo.status?
#    console.log changeInfo
#    return
#  # TODO: google doc pages will never finish loading
#  if not changeInfo.url? and tab.url.match(/https:\/\/docs.google.com\/.*\/edit.*/)?
#    return
#
#  takeSnapshot('updated:' + changeInfo.status)

# Update this in searchTrack?? TODO
#chrome.webNavigation.onCreatedNavigationTarget.addListener (details) ->
#  console.log 'nav: ' + details.sourceTabId + ' -> ' + details.tabId
#  data = new NavInfo({from: details.sourceTabId, to: details.tabId, time: Date.now()})
#  data.save()

chrome.tabs.onAttached.addListener (tabId, attachInfo) ->
  oldWindow = ''
  db.transaction 'rw', db.Tab, () ->
    Tab.findByTabId(tabId).then (tab) ->
      throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
      oldPosition = tab.position
      oldWindow = tab.windowId
      tab.windowId = attachInfo.newWindowId 
      tab.position = attachInfo.newPosition
      tab.save()
  .then (tab) ->
    recordAction(tab, 'attached', oldWindow, attachInfo.newWindowId)
  .catch RecordMissingError, (err) ->
    console.warn(err)
  .catch (err) ->
    console.error(err)

chrome.tabs.onMoved.addListener (tabId, moveInfo) ->
  db.transaction 'rw', db.Tab, () ->
    Tab.findByTabId(tabId).then (tab) ->
      throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
      oldPosition = tab.position
      tab.position = moveInfo.toIndex
      tab.save()
  .then (tab) ->
    console.debug("Moved tab #{tab.tab}")
    recordAction(tab, 'moved', tab.fromIndex, tab.position)
  .catch RecordMissingError, (err) ->
    console.warn(err)
  .catch (err) ->
    console.error(err)

##TODO improve this logic / make this more robust
chrome.tabs.onRemoved.addListener (tabId, removeInfo) ->
  db.transaction 'rw', db.Tab, db.Branch, () ->
    console.debug("Removing tab #{tabId}")
    if removeInfo.isWindowClosing
      return db.Tab.filter((val) -> val.windowId is removeInfo.windowId).and((val) -> val.status is 'active').toArray().then (res) ->
        save = []
        for tab in res
          save.push(tab.close())
        Dexie.Promise.all(save)
    else
      return Tab.findByTabId(tabId).then (tab) ->
        throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
        Dexie.Promise.all([tab.close()])
  .then (tabs) ->
    for tab in tabs
      recordAction(tab, 'removed', tab.tab, -1)
  .catch RecordMissingError, (err) ->
    console.warn(err)
  .catch (err) ->
    console.error(err)

chrome.tabs.onActivated.addListener (activeInfo) ->
  Promise.all([
    Tab.findByTabId(activeInfo.tabId)
    db.TabEvent.where('type').equals('tabFocus').mostRecent()
  ]).spread (newTab, oldTab) ->
    throw new RecordMissingError("Can't find tab for id #{activeInfo.tabId}") if !newTab
    oldTab = {to: -1} if !oldTab
    if newTab.id != oldTab.to
      console.debug("Activated tab #{newTab.tab}")
      recordAction(newTab, 'tabFocus', oldTab.to, newTab.id).then () ->
  .catch RecordMissingError, (err) ->
    console.warn(err)
  .catch (err) ->
    console.error(err)

chrome.windows.onFocusChanged.addListener (windowId) ->
  #Chrome has lost focus -- record that?
  if windowId == chrome.windows.WINDOW_ID_NONE
    db.TabEvent.orderBy('time').reverse().and((val) -> val.type == 'windowFocus').first().then (oldTab) ->
      throw new RecordMissingError("No older focus events") if !oldTab
      recordAction({id: -1}, 'windowFocus', oldTab.to, -1)
    .catch RecordMissingError, (err) ->
      console.warn(err)
    .catch (err) ->
      console.error("Error watching window change #{err}")
  else
    chrome.tabs.queryAsync({active: true, windowId: windowId, currentWindow: true}).then (tabs) ->
      if tabs.length > 0
        Promise.all([
          db.TabEvent.where('type').equals('windowFocus').mostRecent()
          Tab.findByTabId(tabs[0].id)
        ]).spread (oldFocus, tab) ->
          throw new RecordMissingError("Can't find tab for id #{tabs[0].id}") if !tab
          oldFocus = {to: -1} if !oldFocus
          return if windowId == oldFocus.to # This happens if we devtools
          recordAction(tab, 'windowFocus', oldFocus.to, windowId)
    .catch RecordMissingError, (err) ->
      console.warn(err)
    .catch (err) ->
      console.error(err)

chrome.tabs.onCreated.addListener (chromeTab) ->
  ###
  # OpernerTabId is undefined for a new window. It is defined if you created a new tab (either from a link
  # manual new tab). 
  ###
  resolve = []
  tab = new Tab({
    tab: chromeTab.id
    windowId: chromeTab.windowId
    position: chromeTab.index
  })
  db.transaction 'rw', db.Tab, db.Branch, () ->
    console.debug("creating tab for id #{chromeTab.id}")
    tab.save()
  .then (tab) ->
    recordAction(tab, 'created', tab.openerTab, tab.id)
  .catch RecordMissingError, (err) ->
    console.warn(err)
  .catch (err) ->
    console.error(err)
    


#chrome.tabs.onReplaced.addListener (addedTabId, removedTabId) ->
#  db.transaction 'rw', db.Tab, () ->
#    Tab.findByTabId(removedTabId).then (tab) ->
#      throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
#      tab.tab = addedTabId
#      tab.save()
#  .then (tab) ->
#    recordAction(tab, 'replaced', removedTabId, addedTabId) #Not sure if we really care about this
#  .catch RecordMissingError, (err) ->
#    console.warn(err)
#  .catch (err) ->
#    console.error(err)

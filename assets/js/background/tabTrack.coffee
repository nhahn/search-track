recordAction = (tab, action, from, to) ->
  data = new TabEvent({type: action, tab: tab.id, from: from, to: to})
  data.save()

createTabEntry = (tab) ->
  #We opened this from another tab -- associate it with that task
  resolve = []
  tab = new Tab({
    tab: tab.id
    windowId: tab.windowId
    position: tab.index
  })
  if (tab.openerTabId >= 0)
    resolve.push Tab.findByTabId(tab.openerTabId).then (existingTab) ->
      throw new RecordMissingError("Can't find tab for id #{tab.openerTabId}") if !tab
      return existingTab.task
  else
    resolve.push tab.generateTask().then (task) ->
      return task.id
      
  Promise.all(resolve).spread (task) ->
    tab.task = task
    tab.save()
  .then (tab) ->
    recordAction(tab, 'created', tab.openerTabId, '')
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error("Error adding new tab #{err}")


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
    Logger.warn(err)
  .catch (err) ->
    Logger.error("Error recording tab move to new window #{err}")

chrome.tabs.onMoved.addListener (tabId, moveInfo) ->
  Tab.findByTabId(tabId).then (tab) ->
    throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
    oldPosition = tab.position
    tab.position = attachInfo.toIndex
    tab.save()
  .then (tab) ->
    recordAction(tab, 'moved', tab.fromIndex, tab.position)
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error("Error recording tab move #{err}")

chrome.tabs.onRemoved.addListener (tabId, removeInfo) ->
  Tab.findByTabId(tabId).then (tab) ->
    throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
    tab.windowId = -1
    tab.tab = -1
    tab.status = 'closed'
    tab.save()
  .then (tab) ->
    recordAction(tab, 'removed', tab.tab, -1)
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error("Error recording tab removal #{err}")

chrome.tabs.onActivated.addListener (activeInfo) ->
  Promise.all([
    Tab.findByTabId(activeInfo.tabId)
    db.TabEvent.orderBy('time').reverse().and((val) -> val.action == 'focus').first()
  ]).spread (newTab, oldTab) ->
    throw new RecordMissingError("Can't find tab for id #{activeInfo.tabId}") if !newTab
    oldTab = {id: -1} if !oldTab
    if newTab.id != oldTab.id
      recordAction(newTab, 'tabFocus', oldTab.id, newTab.id).then () ->
        
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error("Error recording focus change #{err}")

chrome.windows.onFocusChanged.addListener (windowId) ->
  #Chrome has lost focus -- record that?
  if windowId == chrome.windows.WINDOW_ID_NONE
    db.TabEvent.orderBy('time').reverse().and((val) -> val.action == 'focus').first().then (oldTab) ->
      throw new RecordMissingError("No older focus events") if !oldTab
      recordAction({id: -1}, 'windowFocus', oldTab.to, -1)
    .catch RecordMissingError, (err) ->
      Logger.warn(err)
    .catch (err) ->
      Logger.error("Error watching window change #{err}")
  else
    chrome.tabs.queryAsync({active: true, windowId: windowId, currentWindow: true}).then (tabs) ->
      if tabs.length > 0
        Promise.all([
          db.TabEvent.orderBy('time').reverse().and((val) -> val.action == 'focus').first()
          Tab.findByTabId(tabs[0].id)
        ]).spread (oldFocus, tab) ->
          throw new RecordMissingError("Can't find tab for id #{tabs[0].id}") if !tab
          oldFocus = {to: -1} if !oldFocus
          recordAction(tab, 'windowFocus', oldFocus.to, windowId)
    .catch RecordMissingError, (err) ->
      Logger.warn(err)
    .catch (err) ->
      Logger.error("Error watching window change #{JSON.stringify(err)}")

chrome.tabs.onCreated.addListener (tab) ->
  createTabEntry(tab)
  
# Record all of the currently open tabs that we haven't mentioned before.
chrome.runtime.onInstalled.addListener () ->
  startupCheck()
chrome.runtime.onStartup.addListener () ->
  console.log('extension started!')
  startupCheck()
document.addEventListener "DOMContentLoaded", (event) ->
  startupCheck()
  
startupCheck = () ->
  chrome.tabs.queryAsync({}).then (tabs) ->
    Promise.map tabs, (tab) ->
      Tab.findByTabId(tab.id).then (existingTab) ->
        if existingTab
          return existing Tab
        else
          createTabEntry(tab)
    .then (tabs) ->
      #Do something with the newly created tabs here
    


#chrome.tabs.onReplaced.addListener (addedTabId, removedTabId) ->
#  trackReplace(removedTabId, addedTabId)

takeSnapshot = (action) ->
  snapshotId = generateUUID()
  time = Date.now()
  chrome.tabs.query {windowType: 'normal'}, (tabs) ->
    console.log '========== BEGIN SNAPSHOT =========='
    console.log 'track - ' + action
    saveTabs = []
    for tab in tabs
      tabInfo = new TabInfo(_.extend({
        action: action
        domain: URI(tab.url).domain()
        urlHash: CryptoJS.MD5(tab.url).toString(CryptoJS.enc.Base64)
        domainHash: CryptoJS.MD5(tab.domain).toString(CryptoJS.enc.Base64)
        tabId: tab.id
        snapshotId: snapshotId
      }, tab))
      
      saveTabs.push tabInfo

    compare = (x, y) ->
      if (x == y)
        return 0
      return x > y ? 1 : -1;
    saveTabs.sort (x, y) ->
      if x.windowId == y.windowId
        return compare x.index, y.index
      return compare x.windowId, y.windowId
    globalIndex = 0
    for tab in saveTabs
      tab.globalIndex = globalIndex++
    console.log saveTabs

    tab.save() for tab in saveTabs
    console.log saveTabs
    console.log '========== END   SNAPSHOT =========='

recordAction = (tab, action, from, to) ->
  db.Tab.where('tabId').equald(tabId).and((val) -> val.status is 'active').first().then (tab) ->
    data = new TabEvent({action: action, tabId: tab.id, from: from, to: to})
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
  db.Tab.where('tabId').equald(tabId).and((val) -> val.status is 'active').first().then (tab) ->
    oldPosition = tab.position
    oldWindow = tab.windowId
    tab.windowId = attachInfo.newWindowId 
    tab.position = attachInfo.newPosition
    tab.save()
  .then (tab) ->
    recordAction(tab, 'attached', oldWindow, attachInfo.newWindowId)

chrome.tabs.onMoved.addListener (tabId, moveInfo) ->
  db.Tab.where('tabId').equald(tabId).and((val) -> val.status is 'active').first().then (tab) ->
    oldPosition = tab.position
    tab.position = attachInfo.toIndex
    tab.save()
  .then (tab) ->
    recordAction(tab, 'moved', tab.fromIndex, tab.position)

chrome.tabs.onRemoved.addListener (tabId, removeInfo) ->
  db.Tab.where('tabId').equald(tabId).and((val) -> val.status is 'active').first().then (tab) ->
    tab.windowId = -1
    tab.tabId = -1
    tab.status = 'closed'
    tab.save()
  .then (tab) ->
    recordAction(tab, 'removed', tab.tabId, -1)

chrome.tabs.onActivated.addListener (activeInfo) ->
  trackFocus('tabChange', activeInfo.windowId, activeInfo.tabId)

chrome.windows.onFocusChanged.addListener (windowId) ->
  chrome.tabs.query {active: true, windowId: windowId, currentWindow: true}, (tabs) ->
    if tabs.length > 0
      tab = tabs[0]
      trackFocus('windowChange', windowId, tab.id)

chrome.tabs.onCreated (tab) ->
  #We opened this from another tab -- associate it with that task
  resolve = []
  tab = new Tab({
    tabId: tab.id
    windowId: tab.windowId
    position: tab.index
  })
  if (openerTabId)
    resolve.push db.Tab.where('tabId').equald(tabId).and((val) -> val.status is 'active').first().then (existingTab) ->
      tab.task = existingTab.task
  
  Promise.all(resolve).then () ->
    tab.save()

#chrome.tabs.onReplaced.addListener (addedTabId, removedTabId) ->
#  trackReplace(removedTabId, addedTabId)

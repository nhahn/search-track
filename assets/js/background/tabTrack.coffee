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
    Logger.warn(err)
  .catch (err) ->
    Logger.error(err)

chrome.tabs.onMoved.addListener (tabId, moveInfo) ->
  db.transaction 'rw', db.Tab, () ->
    Tab.findByTabId(tabId).then (tab) ->
      throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
      oldPosition = tab.position
      tab.position = moveInfo.toIndex
      tab.save()
  .then (tab) ->
    recordAction(tab, 'moved', tab.fromIndex, tab.position)
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error(err)

##TODO improve this logic / make this more robust
chrome.tabs.onRemoved.addListener (tabId, removeInfo) ->
  #Check if we just closed a tab, or if we closed an entire window
  chrome.sessions.getRecentlyClosedAsync().then (sessions) ->
    if removeInfo.isWindowClosing and sessions[0].window
      return sessions[0].window.tabs
    else
      return [sessions[0].tab]
  .then (session_tabs) ->
    db.transaction 'rw', db.Tab, () ->
      Logger.debug("Removing tab #{tabId}")
      if removeInfo.isWindowClosing
        return db.Tab.filter((val) -> val.windowId is removeInfo.windowId).and((val) -> val.status is 'active').toArray().then (res) ->
          save = []
          for tab in res
            tab.session = session_tabs[tab.position].sessionId 
            tab.status = 'closed'
            save.push(tab)
          Dexie.Promise.all(save)
      else
        return Tab.findByTabId(tabId).then (tab) ->
          throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
          tab.status = 'closed'
          tab.session = session_tabs[0].sessionId
          Dexie.Promise.all([tab.save()])
    .then (tabs) ->
      for tab in tabs
        recordAction(tab, 'removed', tab.tab, -1)
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error(err)

chrome.tabs.onActivated.addListener (activeInfo) ->
  Promise.all([
    Tab.findByTabId(activeInfo.tabId)
    db.TabEvent.where('type').equals('tabFocus').mostRecent()
  ]).spread (newTab, oldTab) ->
    throw new RecordMissingError("Can't find tab for id #{activeInfo.tabId}") if !newTab
    oldTab = {to: -1} if !oldTab
    if newTab.id != oldTab.to
      recordAction(newTab, 'tabFocus', oldTab.to, newTab.id).then () ->
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error(err)

chrome.windows.onFocusChanged.addListener (windowId) ->
  #Chrome has lost focus -- record that?
  if windowId == chrome.windows.WINDOW_ID_NONE
    db.TabEvent.orderBy('time').reverse().and((val) -> val.type == 'windowFocus').first().then (oldTab) ->
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
          db.TabEvent.where('type').equals('windowFocus').mostRecent()
          Tab.findByTabId(tabs[0].id)
        ]).spread (oldFocus, tab) ->
          throw new RecordMissingError("Can't find tab for id #{tabs[0].id}") if !tab
          oldFocus = {to: -1} if !oldFocus
          return if windowId == oldFocus.to # This happens if we devtools
          recordAction(tab, 'windowFocus', oldFocus.to, windowId)
    .catch RecordMissingError, (err) ->
      Logger.warn(err)
    .catch (err) ->
      Logger.error(err)

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
  db.transaction 'rw', db.Tab, db.Task, () ->
    Logger.debug("creating tab for id #{chromeTab.id}")
    if chromeTab.openerTabId
      return Tab.findByTabId(chromeTab.openerTabId).then (oldTab) ->
        #Whoops -- we can't find the original tab (or something like that XD) ... temp task time
        throw new RecordMissingError("Can't find tab for id #{chromeTab.openerTabId}") if !oldTab or oldTab.windowId != tab.windowId
        return db.Task.get(oldTab.task)
      .then (oldTask) ->
        #copy the parent task in this case, and use a temporary base task
        Task.generateNewTabTemp(oldTask.parent)                
      .catch RecordMissingError, (err) ->
        #We want to get them to define the task they are working on -- otherwise (for now) give 
        #them a temporary parent task
        Task.generateParentTemp().then (parent) ->
          Task.generateNewTabTemp(parent.id)
      .then (task) ->
        tab.task = task.id
        tab.save()
    else
      return Task.generateParentTemp().then (parent) ->
        Task.generateNewTabTemp(parent.id)
      .then (task) ->
        tab.task = task.id
        tab.save()
  .then (tab) ->
    recordAction(tab, 'created', tab.openerTab, tab.id)
  .catch RecordMissingError, (err) ->
    Logger.warn(err)
  .catch (err) ->
    Logger.error(err)
    


#chrome.tabs.onReplaced.addListener (addedTabId, removedTabId) ->
#  db.transaction 'rw', db.Tab, () ->
#    Tab.findByTabId(removedTabId).then (tab) ->
#      throw new RecordMissingError("Can't find tab for id #{tabId}") if !tab
#      tab.tab = addedTabId
#      tab.save()
#  .then (tab) ->
#    recordAction(tab, 'replaced', removedTabId, addedTabId) #Not sure if we really care about this
#  .catch RecordMissingError, (err) ->
#    Logger.warn(err)
#  .catch (err) ->
#    Logger.error(err)

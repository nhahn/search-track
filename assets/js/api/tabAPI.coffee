class Tab
  constructor: (params) ->
    properties = _.extend({
      tabId: -1
      windowId: -1
      openerTabId: -1
      position: 0
      session: '' #the 
      page: '' #The page ID of the current page it is on
      status: 'active' # This is an enum: ['active', 'stored', 'closed']
      task: '' #The ID of the task this tab is associated with
      date: Date.now()
    }, params)
    @tabId = properties.tabId
    @windowId = properties.windowId
    @openerTabId = properties.openerTabId
    @position = properties.position
    @session = properties.session
    @status = properties.status
    @date = properties.date

  save: () ->
    db.Tab.put(this).then (id) =>
      return this
    
  store: () ->
    chrome.tabs.removeAsync(@tabId).then () =>
      chrome.session.getRecentlyClosedAsync({maxResults: 1})
    .then (sessions) =>
      @session = sessions[0]
      this.save()
    
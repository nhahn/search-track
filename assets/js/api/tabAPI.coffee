#####
#
# Table for tab-based page tracking. Helps organizing searches and history
#
#####

class Tab extends Base
  constructor: (params) ->
    properties = _.extend({
      tab: -1
      windowId: -1
      openerTabId: -1
      position: 0
      session: '' #the 
      page: '' #The page ID of the current page it is on
      status: 'active' # This is an enum: ['active', 'stored', 'closed']
      task: '' #The ID of the task this tab is associated with
      date: Date.now()
    }, params)
    @tab = properties.tab
    @windowId = properties.windowId
    @openerTabId = properties.openerTabId
    @position = properties.position
    @session = properties.session
    @status = properties.status
    @date = properties.date
    
  store: () ->
    chrome.tabs.removeAsync(@tab).then () =>
      chrome.session.getRecentlyClosedAsync({maxResults: 1})
    .then (sessions) =>
      @session = sessions[0]
      this.save()
      
  @findByTabId: (tabId) ->
    db.Tab.where('tab').equals(tabId).and((val) -> val.status is 'active').first()
    
  #TODO have more complex heuristics, etc for getting an existing task
  generateTask: () ->
    task = new Task({name: 'Unknown'+Math.random()*10000, hidden: true})
    task.save()
  
    
    
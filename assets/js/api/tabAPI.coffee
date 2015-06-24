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
      openerTab: -1
      position: 0
      session: '' #the 
      pageVisit: '' #The pageVisit that is currently active
      status: 'active' # This is an enum: ['active', 'stored', 'closed']
      task: '' #The ID of the task this tab is associated with (TODO blank is newTab page i guess??)
      date: Date.now()
    }, params)
    @tab = properties.tab
    @windowId = properties.windowId
    @openerTabId = properties.openerTabId
    @position = properties.position
    @session = properties.session
    @pageVisit = properties.pageVisit
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
   
  
  
    
    
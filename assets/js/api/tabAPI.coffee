#####
#
# Table for tab-based page tracking. Helps organizing searches and history
#
#####

class Tab extends Base
  constructor: (params) ->
    super {
      tab: undefined
      windowId: -1
      openerTab: -1
      position: 0
      session: '' #the 
      pageVisit: '' #The pageVisit that is currently active
      status: 'active' # This is an enum: ['active', 'stored', 'closed', 'temp']
      task: '' #The ID of the task this tab is associated with (TODO blank is newTab page i guess??)
      date: Date.now()
    }, params
    
  store: () ->
    chrome.tabs.removeAsync(@tab).then () =>
      chrome.session.getRecentlyClosedAsync({maxResults: 1})
    .then (sessions) =>
      @session = sessions[0]
      this.save()
      
  @findByTabId: (tabId) ->
    db.Tab.where('tab').equals(tabId).and((val) -> val.status is 'active').first()
   
  
  
    
    
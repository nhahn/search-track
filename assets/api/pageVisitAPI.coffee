###
#
# Table individual web-page visits. This is created whenever someone visits a page by navigating to its URL
# (think of it as a history event).
#
###

class PageVisit extends Base
  constructor: (params) ->
    super {
      page: undefined # The page visited
      tab: undefined # The tab this page was visited from
      task: '' #The "task" this particular visit was associated with. A page could be associated with different tasks!!
      referrer: '' #If a another page "referred" us here, we record the previous pageEvent that did so (so we keep track of tasks)
      type: '' #Enum of navigation ['forward', 'back', 'link', 'typed', 'navigation']
      time: Date.now() #When this visit occured
    }, params
    
  @forPage: (pageId) ->
    db.PageVisit.where('page').equals(pageId)
  
  @forTab: (tabId) ->
    db.PageVisit.where('tab').equals(tabId)
    
  # Returns the path of PageVisits required to get to this point
  getPath: () ->
    if @referrer
      db.PageVisit.get(@referrer).then (visit) ->
        return [visit, visit.getPath()]
      .spread (visit,arr) ->
        return [visit].concat(arr)
    else
      return this
    
# Sidenote: for a possible graph in order to visualize these @see: https://github.com/cpettitt/dagre-d3/wiki
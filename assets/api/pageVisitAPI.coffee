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
      type: '' #Enum of navigation ['forward', 'back', 'link', 'typed', 'navigation']
      time: Date.now() #When this visit occured
    }, params
    
  @forPage: (pageId) ->
    db.PageVisit.where('page').equals(pageId)
    
# Sidenote: for a possible graph in order to visualize these @see: https://github.com/cpettitt/dagre-d3/wiki
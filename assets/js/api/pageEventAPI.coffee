###
#
# Table for tracking page level events. We associated this with a pageVisit -- b/c someone could be using a page differently # between different visits 
#
###

class PageEvent extends Base
  constructor: (params) ->
    super {
      type: 'scrollPostion' # Enum of ['scrollPosition']
      pageVisit: undefined # The particular visit to a page we are recording events for 
      data: '' #Field depends on the above type
      time: Date.now()
    }, params
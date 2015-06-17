###
#
# Table for tracking page level events. 
#
###

class PageEvent extends Base
  constructor: (params) ->
    properties = _.extend({
      type: 'scrollPostion' # Enum of ['scrollPosition']
      page: '' # Page this is associated with 
      data: '' #Field depends on the above type
      time: Date.now()
    }, params)
    @type = properties.type
    @page = properties.page
    @data = properties.data
    @time = properties.time
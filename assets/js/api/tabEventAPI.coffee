###
#
# Table for tracking individual tab events 
#
###

class TabEvent extends Base
  constructor: (params) ->
    properties = _.extend({
      type: 'updated' # Enum of ['windowFocus', 'tabFocus', 'moved', 'removed', 'attached', 'updated']
      tab: '' # Tab this is associated with
      from: '' #Field depends on the above type
      to: '' #Field depends on the above type
      time: Date.now()
    }, params)
    @type = properties.type
    @tab = properties.tab
    @from = properties.from
    @to = properties.to
    @time = properties.time

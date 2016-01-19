###
#
# Table for tracking individual tab events 
#
###

class TabEvent extends Base
  constructor: (params) ->
    super {
      type: 'updated' # Enum of ['windowFocus', 'tabFocus', 'moved', 'removed', 'attached', 'updated']
      tab: undefined # Tab this is associated with
      from: '' #Field depends on the above type
      to: '' #Field depends on the above type
      time: Date.now()
    }, params

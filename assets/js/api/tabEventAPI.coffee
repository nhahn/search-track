class TabEvent
  constructor: (params) ->
    properties = _.extend({
      type: 'updated' # Enum of ['windowFocus', 'tabFocus', 'moved', 'removed', 'attached', 'updated']
      tabId: '' # Tab this is associated with
      from: '' #Field depends on the above type
      to: '' #Field depends on the above type
      date: Date.now()
    }, params)
    @name = properties.name
    @dateCreated = properties.dateCreated
    @order = properties.order

  save: () ->
    db.TabEvent.put(this).then (id) =>
      return this
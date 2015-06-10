###
#
# Table for tracking searches we've performed
#
###

class Search
  constructor: (params) ->
    properties = _.extend({
      name: ''
      tabs: []
      date: Date.now()
      visits: 1
    }, params)
    @name = properties.name
    @tabs = properties.tabs
    @date = properties.date
    @visits = properties.visits

  save: () ->
    db.Search.put(this).then (id) =>
      return this
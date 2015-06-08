###
#
# Table for tracking searches we've performed
#
###

window.Search = (params) ->
  properties = _.extend({
    name: ''
    tabs: []
    date: Date.now()
    visits: 1
  }, params)
  this.name = properties.name
  this.tabs = properties.tabs
  this.date = properties.date
  this.visits = properties.visits

window.Search.prototype.save = () ->
  self = this
  db.Search.put(this).then (id) ->
    self.id = id
    return sel
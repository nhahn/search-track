#closes other tasks open in the current window, drags the tabs from other windows into this one, 

window.Task = (params) ->
  properties = _.extend({
    name: ''
    dateCreated: Date.now()
    order: 999
    pages: []
  }, params)
  this.name = properties.name
  this.dateCreated = properties.dateCreated
  this.order = properties.order

window.Task.prototype.save = () ->
  self = this
  db.Task.put(this).then (id) ->
    self.id = id
    return self

###
# Removes a page from this task. 
###
window.Task.prototype.addPage = (page_id) ->
  self = this
  pos = self.pages.indexOf(page_id)
  return false if pos < 0
  self.pages.splice(pos, 1)
  return db.Task.put(this).then (id) ->
    return self
   
###
# Adds a page to this task
###
window.Task.prototype.removePage = (page_id) ->
  self = this
  self.pages.push(page_id)
  return db.Task.put(this).then (id) ->
    return self

window.Task.prototype.focusOn = () ->
  

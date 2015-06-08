###
#
# Table for tracking individual web pages we want to monitor in searches / tasks. 
#
###

window.Page = (params) ->
  properties = _.extend({
    loc: 0
    favicon: ''
    timeElapsed: 0
    isSERP: false
    url: ''
    query: ''
    tab: -1
    date: Date.now()
    visits: 1
    referrer: null
    title: ''
    vector: {} 
    topics: ''
    topic_vector: []
    size: 0
    note: ''
    color: 'rgba(219,217,219,1)'
    importance: 1
    depth: 0
    height: 0 # for the drag-and-drop list (could be adapted for 2D manipulation)
    position: -1 #TODO
    favorite: false   # will be able to "favorite" newTabs
    ref: false   # is it a reference newTab?
  }, params)
  this.loc = properties.loc
  this.favicon = properties.favicon
  this.timeElapsed = properties.timeElapsed
  this.isSERP = properties.isSERP
  this.query = properties.query
  this.url = properties.url
  this.tab = properties.tab
  this.date = properties.date
  this.visits = properties.visits
  this.title = properties.title
  this.referrer = properties.referrer
  this.vector = properties.vector
  this.topics = properties.topics
  this.topic_vector = properties.topic_vector
  this.size = properties.size
  this.note = properties.note
  this.color = properties.color
  this.importance = properties.importance
  this.depth = properties.depth
  this.height = properties.height
  this.position = properties.position
  this.favorite = properties.favorite
  this.ref = properties.ref

Page.prototype.save = () ->
  self = this
  db.Page.put(this).then (id) ->
    self.id = id
    return self
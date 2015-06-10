###
#
# Table for tracking individual web pages we want to monitor in searches / tasks. 
#
###

class Page
  constructor: (params) ->
    properties = _.extend({
      loc: 0
      favicon: ''
      timeElapsed: 0
      isSERP: false
      url: ''
      query: ''
      tab: '' #Tab ID we are associated with
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
    @loc = properties.loc
    @favicon = properties.favicon
    @timeElapsed = properties.timeElapsed
    @isSERP = properties.isSERP
    @query = properties.query
    @url = properties.url
    @tab = properties.tab
    @date = properties.date
    @visits = properties.visits
    @title = properties.title
    @referrer = properties.referrer
    @vector = properties.vector
    @topics = properties.topics
    @topic_vector = properties.topic_vector
    @size = properties.size
    @note = properties.note
    @color = properties.color
    @importance = properties.importance
    @depth = properties.depth
    @height = properties.height
    @position = properties.position
    @favorite = properties.favorite
    @ref = properties.ref

  save: () ->
    db.Page.put(this).then (id) =>
      return this
###
#
# Table for tracking individual web pages we want to monitor in searches / tasks. 
#
###

# TODO define some of these parameters????? 

class Page extends Base
  constructor: (params) ->
    properties = _.extend({
      favicon: ''
      isSearch: false
      query: ''
      url: ''
      domain: ''
      time: Date.now()
      title: ''
      vector: {} 
      topics: ''
      topic_vector: []
      size: 0
      notes: ''
      color: 'rgba(219,217,219,1)'
      depth: 0
      height: 0 # for the drag-and-drop list (could be adapted for 2D manipulation)
      favorite: false   # will be able to "favorite" newTabs
    }, params)
    @favicon = properties.favicon
    @isSearch = properties.isSearch
    @query = properties.query
    @url = properties.url
    @domain = properties.domain
    @time = properties.time
    @title = properties.title
    @vector = properties.vector
    @topics = properties.topics
    @topic_vector = properties.topic_vector
    @size = properties.size
    @notes = properties.notes
    @color = properties.color
    @depth = properties.depth
    @height = properties.height
    @favorite = properties.favorite

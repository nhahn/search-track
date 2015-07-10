###
#
# Table for tracking individual web pages we want to monitor in searches / tasks. 
#
###

# TODO define some of these parameters?

class Page extends Base
  constructor: (params) ->
    properties = _.extend({
      favicon: ''
      isSearch: false
      blacklisted: false
      query: ''
      url: ''
      domain: ''
      fragmentless: ''
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
      favorite: false   # will be able to "favorite" tabs
    }, params)
    @favicon = properties.favicon
    @isSearch = properties.isSearch
    @blacklisted = properties.blacklisted
    @query = properties.query
    @url = properties.url
    @domain = properties.domain
    @fragmentless = properties.fragmentless
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

  @generatePage: (url) ->
    uri = new URI(url)
    fragment = uri.fragment()
    uri.fragment("")
    query = ''
    #Check if it is a Google search
    matches = url.match(/www\.google\.com\/.*q=(.*?)($|&)/)
    if matches != null
      query = decodeURIComponent(matches[1].replace(/\+/g, ' '))
    
    page = new Page({url: url, domain: uri.domain(), fragmentless: uri.toString(), query: query, isSearch: if query != "" then true else false})
    page.save()

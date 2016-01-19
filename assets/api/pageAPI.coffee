###
#
# Table for tracking individual web pages we want to monitor in searches / tasks. 
#
###

# TODO define some of these parameters?

class Page extends Base
  constructor: (params) ->
    super {
      favicon: ''
      isSearch: false
      blacklisted: false
      query: ''
      url: undefined
      domain: ''
      fragmentless: ''
      time: Date.now()
      title: ''
      vector: {}
      topics: ''
      topic_vector: []
    }, params

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

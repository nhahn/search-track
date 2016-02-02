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

  ###
  # Extract the redirect URL from google results
  ###
  @extractGoogleRedirectURL: (url) ->
    matches = url.match(/www\.google\.com\/.*url=(.*?)($|&)/)
    if matches == null
      return url
    url = decodeURIComponent(matches[1].replace(/\+/g, ' '))
    return url

  @findOrCreate: (url) ->
    db.transaction 'rw', db.Page, () ->
      db.Page.where('url').equals(url).first().then (page) ->
        return if page then page else Page.generatePage(url)

  @findByUrl: (url) ->
    url = Page.extractGoogleRedirectURL(url)
    db.Page.where('url').equals(url).first()
        
  @generatePage: (url) ->
    url = Page.extractGoogleRedirectURL(url)
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
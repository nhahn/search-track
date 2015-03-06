###
# This file keeps track of the Google searches a person performs in the background. It saves them
# in the local storage in the "queries" variable
###
searchTrack = {}
searchTrack.addPageRelation = (url, query, tabId) ->

searchTrack.removeTab = (searchInfo, ___id) ->
  tabs = searchInfo.tabs
  idx = tabs.indexOf(___id)
  tabs.splice(idx, 1) if idx > -1
  SearchInfo.db(searchInfo).update({tabs: tabs})
  
searchTrack.addTab = (searchInfo, ___id) ->
  tabs = searchInfo.tabs
  tabs.push(___id) if tabs.indexOf(___id) < 0
  SearchInfo.db(searchInfo).update({tabs: tabs, date: Date.now()})

extractGoogleRedirectURL = (url) ->
  matches = url.match(/www\.google\.com\/.*url=(.*?)($|&)/)
  if matches == null
    return url
  url = decodeURIComponent(matches[1].replace(/\+/g, ' '))
  return url


createOrUpdateSearchInfo = (tabId, tab, query) ->
  searchInfo = SearchInfo.db([{name: query}]).order("date desc").first()
  if !searchInfo
    #First time finding this
    console.log 'creating for: ' + tab.url
    data = {url: tab.url, query: query, tab: tabId, date: Date.now(), referrer: null, visits: 1, title: tab.title}
    PageInfo.db.insert(data)
    pageInfo = PageInfo.db(data).order("date desc").first()
    SearchInfo.db.insert({tabs: [pageInfo.___id], date: Date.now(), name: query})
  else
    pageInfo = PageInfo.db({url: tab.url, query: query}).order("date desc").first()
    # dont add dup search page
    if !pageInfo
      data = {url: tab.url, query: query, tab: tabId, date: Date.now(), referrer: null, visits: 1, title: tab.title}
      PageInfo.db.insert(data)
      pageInfo = PageInfo.db(data).order("date desc").first()
      console.log 'add tab for: '
      console.log pageInfo
      console.log 'to: '
      console.log searchInfo
      searchTrack.addTab(searchInfo, pageInfo.___id)
      console.log 'result: '
      console.log searchInfo

getContentAndTokenize = (tabId, tab, pageInfo) ->
  console.log "TOK:"
  console.log tab.url
  chrome.tabs.executeScript tabId, {code: 'window.document.documentElement.innerHTML'}, (results) ->
    html = results[0]
    if html? and html.length > 10
      $.ajax(
        type: 'POST',
        url: 'http://104.131.7.171/tokenize',
        data: { 'data': JSON.stringify( {'html': html} ) }
      ).success( (results) ->
        console.log 'tokenized'
        results = JSON.parse results
        vector = results['vector']
        insert_obj = {vector: vector, title: tab.title, url: tab.url}
        PageInfo.db(pageInfo).update(insert_obj, true)
      ).fail (a, t, e) ->
        console.log 'fail tokenize'
        console.log t


chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  # TODO think about multiple completes from server-side redirections
  if changeInfo.status != 'complete'
    return

  console.log 'onUpdated ' + tabId
  console.log changeInfo

  matches = tab.url.match(/www\.google\.com\/.*q=(.*?)($|&)/)
  if matches != null
    query = decodeURIComponent(matches[1].replace(/\+/g, ' '))
    if query != ""
      createOrUpdateSearchInfo(tabId, tab, query)

  else
    pageInfo = PageInfo.db({tab: tabId}).order("date desc").first()
    if pageInfo
      # TODO check for dup here
      getContentAndTokenize(tabId, tab, pageInfo)

chrome.webNavigation.onCompleted.addListener (details) ->
  # subframe navigation
  if details.frameId != 0
    return

  console.log 'onCompleted:'
  console.log details
  console.log details.url


chrome.webNavigation.onCreatedNavigationTarget.addListener (details) ->
  console.log 'onNav: ' + details.sourceTabId + ' -> ' + details.tabId
  details.url = extractGoogleRedirectURL details.url
  chrome.tabs.get details.sourceTabId, (sourceTab) ->
    pageInfo = PageInfo.db({url: sourceTab.url}).order("date desc").first()
    searchInfo = SearchInfo.db({tabs: {has: pageInfo.___id}}).order("date desc").first()
    if searchInfo
      PageInfo.db.insert({tab: details.tabId, query: searchInfo.name})
      # TODO add referrer here
      pageInfo = PageInfo.db({tab: details.tabId, query: searchInfo.name}).order("date desc").first()
      searchTrack.addTab(searchInfo, pageInfo.___id)


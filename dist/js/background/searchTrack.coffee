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
    data = {isSERP: true, url: tab.url, query: query, tab: tabId, date: Date.now(), referrer: null, visits: 1, title: tab.title}
    PageInfo.db.insert(data)
    pageInfo = PageInfo.db(data).order("date desc").first()
    SearchInfo.db.insert({tabs: [pageInfo.___id], date: Date.now(), name: query})
  else
    pageInfo = PageInfo.db({url: tab.url, query: query}).order("date desc").first()
    # dont add dup search page
    if !pageInfo
      data = {isSERP: true, url: tab.url, query: query, tab: tabId, date: Date.now(), referrer: null, visits: 1, title: tab.title}
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
        url: 'http://104.131.7.171/lda',
        data: { 'data': JSON.stringify( {'html': html} ) }
      ).success( (results) ->
        console.log 'lda'
        results = JSON.parse results
        vector = results['vector']
        update_obj = {title: tab.title, url: tab.url, vector: results['vector'], topics: results['topics'], topic_vector: results['topic_vector'], size: results['size']}
        PageInfo.db(pageInfo).update(update_obj, true)
      ).fail (a, t, e) ->
        console.log 'fail tokenize'
        console.log t

  # add to SavedInfo as well
  console.log tab
  newTab = {}
  newTab.time = Date.now()
  newTab.timeElapsed = 0
  # Find first empty spot to place newTab
  db = SavedInfo.db().filter(importance: 1).get()
  locs = []
  i = 0
  while i < db.length
    locs.push db[i].loc
    i++
  newTab.loc = 0
  for i of locs.sort()
    `i = i`
    if locs[i] == newTab.loc
      newTab.loc++
  newTab.newTabId = tab.id
  newTab.favicon = tab.favIconUrl
  ttl = tab.title
  if ttl.length == 0
    ttl = prompt('Please name this page', 'Untitled')
  newTab.title = ttl
  newTab.url = tab.url
  newTab.note = ''
  newTab.color = 'rgba(219,217,219,1)'
  newTab.importance = 1
  newTab.depth = window.scrollY
  newTab.height = window.innerHeight
  console.log 'My Depth: ' + newTab.depth
  console.log 'Total Depth: ' + document.body.clientHeight
  # for the drag-and-drop list (could be adapted for 2D manipulation)
  newTab.position = SavedInfo.db().count()
  # will be able to "favorite" newTabs
  newTab.favorite = false
  # is it a reference newTab?
  newTab.ref = false
  #TODO: TASK DB, then get the right task. Where do I record the current task? I'll have to send a message?
  newTab.task = ''
  # add to DB.
  annotation = SavedInfo.db().get()[0].annotation
  SavedInfo.db.insert newTab
  # Tell newTabs
  chrome.tabs.query {}, (tabs) ->
    tabs.forEach (t) ->
      chrome.tabs.sendMessage t.id, newTab: newTab
      return
    return
  return

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  # TODO what if the page keeps loading while the user is reading it?
  # if SearchInfo is created after some link is clicked, the page is not tracked
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
    console.log('added')
    pageInfo = PageInfo.db({tab: tabId}).order("date desc").first()
    if pageInfo
      # check for dup here
      searchInfo = SearchInfo.db({tabs: {has: pageInfo.___id}}).order("date desc").first()
      dup_pageInfo = PageInfo.db({title: tab.title, url: tab.url, query: searchInfo.name}).first()
      if dup_pageInfo
        PageInfo.db(pageInfo).remove()
      else
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
      # add referrer here
      PageInfo.db.insert({isSERP: false, tab: details.tabId, query: searchInfo.name, referrer: pageInfo.___id})
      pageInfo = PageInfo.db({tab: details.tabId, query: searchInfo.name}).order("date desc").first()
      searchTrack.addTab(searchInfo, pageInfo.___id)

###
# This file keeps track of the Google searches a person performs in the background. It saves them
# in the local storage in the "queries" variable
###
searchTrack = {}
searchTrack.addPageRelation = (url, query, tabId) ->

searchTrack.removeTab = (searches, tabId) ->
  tabs = searches.first().tabs
  idx = tabs.indexOf(tabId)
  tabs.splice(idx, 1) if idx > -1
  searches.update({tabs: tabs})
  
searchTrack.addTab = (searches, tabId) ->
  tabs = searches.first().tabs
  tabs.push(tabId) if tabs.indexOf(tabId) < 0
  searches.update({tabs: tabs, date: Date.now()})
    
chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  if changeInfo.url?
    matches = changeInfo.url.match(/www\.google\.com\/.*q=(.*?)($|&)/)
    #We have found a new search -- we need to track this
    if matches != null
      query = decodeURIComponent(matches[1].replace(/\+/g, ' '))

      #Remove any existing references to this particular tabId
      searchInfo = SearchInfo.db({tabs: {has: tabId}})
      searchTrack.removeTab(searchInfo, tabId) if searchInfo.first()

      #Have we had this query before?
      searchInfo = SearchInfo.db([{name: query}])
      if !searchInfo.first()
        #First time finding this
        SearchInfo.db.insert({tabs: [tabId], date: Date.now(), name: query})
        PageInfo.db.insert({url: changeInfo.url, query: query, tab: tabId, date: Date.now(), referrer: null, visits: 1, title: tab.title})
      else
        searchTrack.addTab(searchInfo, tabId)

chrome.webNavigation.onDOMContentLoaded.addListener((details) ->
  searchInfo = SearchInfo.db({tabs: {has: details.tabId}})
  if searchInfo.first()
    chrome.tabs.get details.tabId, (tab) ->
      pages = PageInfo.db({tab: details.tabId}).order("date desc")
      if pages.first()
        chrome.tabs.executeScript details.tabId, {code: 'window.document.documentElement.innerHTML'}, (results) ->
          insert_obj = {html: results[0], title: tab.title}
          pages.update(insert_obj, true)
)
  
chrome.webNavigation.onCommitted.addListener((details) ->
  #see what searches have been performed in this tab before
  searchInfo = SearchInfo.db({tabs: {has: details.tabId}})
  #We typed in a URL of some type -- need to remove this from tracking
  if details.transitionQualifiers.indexOf("from_address_bar") > -1
    if searchInfo.first()
      searchTrack.removeTab(searchInfo, details.tabId)
  else if details.transitionType == "link" or details.transitionType == "form_submit"
    #This is a navigation attempt we are doing
    if details.transitionQualifiers.indexOf("forward_back") > -1
      if searchInfo.first()
        pages = PageInfo.db({tab: details.tabId},{query: searchInfo.first().name},{url: details.url})
        if pages.first()
          pages.update({visits: pages.first().visits + 1, date: Date.now()}, false)
    else
      if searchInfo.first()
        if details.transitionQualifiers.indexOf("client_redirect") > -1
          chrome.tabs.get details.tabId, (tab) ->
            pages = PageInfo.db({tab: details.tabId}).order("date desc")
            if pages.first()
              insert_obj = {url: details.url, title: tab.title}
              pages.update(insert_obj, false)
        else
          chrome.tabs.get details.tabId, (tab) ->
            insert_obj = {url: details.url, query: searchInfo.first().name, tab: details.tabId, date: Date.now(), referrer: null, visits: 1, title: tab.title}
            pages = PageInfo.db({tab: details.tabId}).order("date desc")
            #Try to track down an associated page by tab and window info (order them by the soonest one first)
            if pages.first()
              insert_obj.referrer = pages.first().___id
            #Insert what we found
            PageInfo.db.insert(insert_obj)
  else if details.transitionType == "auto_bookmark" or details.transitionType == "typed" or details.transitionType == "keyword"
    #Lets identify if this URL is part of our search already
    pages = PageInfo.db({tab: details.tabId}, {url: details.url})
    #Remove this from this list -- we've started to do something else on this tab
    if pages.first()
      #we've gone back or somethings -- we need to restore this
      search = SearchInfo.db({name: pages.first().query})
      searchTrack.addTab(search, details.tabId)
    else if searchInfo.first()
      searchTrack.removeTab(searchInfo, details.tabId)
)

#Track the creation of tabs from links -- aka new tab / window from link
chrome.webNavigation.onCreatedNavigationTarget.addListener((details) ->
  #see what searches have been performed in this tab before
  searchInfo = SearchInfo.db({tabs: {has: details.sourceTabId}})
  if searchInfo.first()
    chrome.tabs.get details.tabId, (tab) ->
      insert_obj = {url: details.url, query: searchInfo.first().name, tab: details.tabId, date: Date.now(), referrer: null, visits: 1, title: tab.title}
      pages = PageInfo.db({tab: details.sourceTabId}).order("date desc")
      #Try to track down an associated page by tab and window info (order them by the soonest one first)
      if pages.first()
        insert_obj.referrer = pages.first().___id
      #Insert what we found
      PageInfo.db.insert(insert_obj)
)
  
#TODO remove tab if detected to be a change

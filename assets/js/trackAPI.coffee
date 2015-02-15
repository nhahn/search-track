###
#
# API used for parsing the information stored in chrome.storage for searches
#
###

###
# Structure of our storage
# queries: { 
#     name: _Name / query term used
#     date: _last time the query was performed
#  }
# tab
###

      
generateUUID = ->
  d = (new Date).getTime()
  uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    r = (d + Math.random() * 16) % 16 | 0
    d = Math.floor(d / 16)
    (if c == 'x' then r else r & 0x3 | 0x8).toString 16
  )
  uuid
  
window.SearchInfo = (() ->
  obj = {}
  obj.db = TAFFY()
  #Lets us track which running version of this file is actually updating the DB
  updateID = generateUUID()
  updateFunction = null
  settings =
    template: {}
    onDBChange: () ->
      chrome.storage.local.set {'queries': {db: this, updateId: updateID}}
  
  #Grab the info from localStorage and lets update it
  chrome.storage.onChanged.addListener (changes, areaName) ->
    if changes.queries? 
      if !changes.queries.newValue?
        obj.db = TAFFY()
        obj.db.settings(settings)
        updateFunction() if updateFunction?
      else if changes.queries.newValue.updateid != updateID
        obj.db = TAFFY(changes.queries.newValue.db, false)
        obj.db.settings(settings)
        updateFunction() if updateFunction?
        
  chrome.storage.local.get 'queries', (retVal) ->
    if retVal.queries?
      obj.db = TAFFY(retVal.queries.db)
    obj.db.settings(settings)
    updateFunction() if updateFunction?
      
  obj.clearDB = () ->
    chrome.storage.local.remove('queries')
    obj.db = TAFFY()
      
  obj.db.settings(settings)
  obj.updateFunction = (fn) -> updateFunction = fn

  return obj
)()

window.PageInfo = (() ->
  
  obj = {}
  obj.db = TAFFY()
  #Lets us track which running version of this file is actually updating the DB
  updateID = generateUUID()
  updateFunction = null
  settings =
    template: {}
    onDBChange: () ->
      chrome.storage.local.set {'pages': {db: this, updateId: updateID}}
    onUpdate: (before, changes) ->
      after = this
      if changes.vector? and after.vector? and after.query.length > 2
        # SearchInfo.db {tabs: {has: after.tab}} is unreliable
        tabs = PageInfo.db({query: after.query}).get()
        tabs = _.filter tabs, (tab) -> tab.vector?
        vectors = _.map tabs, (tab) -> tab.vector
        if vectors.length < 2
          return
          
        $.ajax(
          type: 'POST',
          url: 'http://127.0.0.1:5000/searchInfo',
          data: { 'data': JSON.stringify( {'vectors': vectors} ) }
        ).success( (results) ->
          results = JSON.parse results
          tfidfs = results['tfidfs']
          lda = results['lda']
          lda_vector = results['lda_vector']
          # workaround for bug: SearchInfo.db {tabs: {has: after.tab}} != SearchInfo.db {name: after.query}
          searchInfo = SearchInfo.db {name: after.query}
          searchInfo.update {lda: lda, lda_vector: lda_vector}
          _.map( _.zip(tabs, tfidfs), (tab_tfidf) -> 
            tab = tab_tfidf[0]
            tfidf = tab_tfidf[1]
            _tab = PageInfo.db {tab: tab.tab}
            _tab.update {keywords: tfidf}
          )
        )

  
  #Grab the info from localStorage and lets update it
  chrome.storage.onChanged.addListener (changes, areaName) ->
    if changes.pages?
      if !changes.pages.newValue?
        obj.db = TAFFY()
        obj.db.settings(settings)
        updateFunction() if updateFunction?
      else if changes.pages.newValue.updateid != updateID
        obj.db = TAFFY(changes.pages.newValue.db, false)
        obj.db.settings(settings)
        updateFunction() if updateFunction?
        
  chrome.storage.local.get 'pages', (retVal) ->
    if retVal.pages?
      obj.db = TAFFY(retVal.pages.db)
    obj.db.settings(settings)
    updateFunction() if updateFunction?

  obj.clearDB = () ->
    chrome.storage.local.remove('pages')
    obj.db = TAFFY()
      
  obj.db.settings(settings)
  obj.updateFunction = (fn) -> updateFunction = fn

  return obj

)()

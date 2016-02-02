###
#
# Sets-up our DB tables (using Dexie.js). There are 5 different tables, specified below (along with their definitions). 
# For each table, there is an additional section that describes an object it maps to. 
#
###
   
###
#
# Database that keeps track of the searches we have performed with Google
#
#
###

db_changes = chrome.runtime.connect {name: 'db_changes'}
window.db = new Dexie('searchTrack')
db.version(1).stores({
  Search: '++id,&name,*tabs,task' #Searches from Google we are tracking
  Branch: '++id,name,dateCreated,parent' #table of tasks
  Page: '++id,url' #Pages we are keeping info on
  PageVisit: '++id,page' #Visits to individual pages
  PageEvent: '++id,pageVisit,type,time' #Events for a specific visit to a page
  Tab: '++id,tab,task' # Tabs we are watching
  TabEvent: '++id,tab,type,time' #Tab-specific events
  # SavedInfo: '$$id,importance,time' # database for information that user marks as "for later"
})

db.Page.mapToClass(window.Page)
db.Search.mapToClass(window.Search)
db.Branch.mapToClass(window.Branch)
db.Tab.mapToClass(window.Tab)
db.TabEvent.mapToClass(window.TabEvent)
db.PageEvent.mapToClass(window.PageEvent)
db.PageVisit.mapToClass(window.PageVisit)

db.open()
  
###
#
# Promisify stuff from chrome API
#
###

promisifyChrome = (api) ->
  _.each _.functions(api), (func) ->
    api[func+"Async"] = (params...) ->
      return new Promise (resolve, reject) ->
        cb = (res...) ->
          reject(new ChromeError(chrome.runtime.lastError.message)) if chrome.runtime.lastError
          resolve(res...)
        params.push(cb)
        api[func].apply(null, params)


promisifyChrome(chrome.windows)
promisifyChrome(chrome.tabs)
promisifyChrome(chrome.sessions)
promisifyChrome(chrome.history)

class RecordMissingError extends Error
  constructor: (@message) ->
    @name = 'RecordMissingError'
    Error.captureStackTrace(this, RecordMissingError)

class ChromeError extends Error
  constructor: (@message) ->
    @name = 'ChromeError'
    Error.captureStackTrace(this, RecordMissingError)

#db.on 'changes', (changes) ->
#  for change in changes
#    switch change.type
#      when 1 #CREATED
#        db_changes.postMessage({type: 'created', table: change.table, key: change.key, obj: change.obj})
#      when 2 #UPDATED
#        db_changes.postMessage({type: 'updated', table: change.table, key: change.key, obj: change.obj})
#      when 3 #DELETED
#        db_changes.postMessage({type: 'deleted', table: change.table, key: change.key, obj: change.oldObj})

#Dexie.Promise.on 'error', (err) ->
#  Logger.error("Uncaught error: " + err)



###
#
# Sets-up our DB tables (using Dexie.js). There are 5 different tables, specified below (along with their definitions). 
# For each table, there is an additional section that describes an object it maps to. 
#
###
   
###
#
# Optional (not currently used) methods to persist DB info to file
#
###
dbMethods = (() -> 
  obj = {}
  obj.generateUUID = ->
    d = (new Date).getTime()
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
      r = (d + Math.random() * 16) % 16 | 0
      d = Math.floor(d / 16)
      (if c == 'x' then r else r & 0x3 | 0x8).toString 16
    )
    uuid

  objects2csv = (objects, attributes) ->
    csvData = new Array()
    csvData.push '"' + attributes.join('","') + '"'
    for object in objects
      row = []
      for attribute in attributes
        row.push ("" + object[attribute]).replace(/\\/g, "\\\\").replace(/"/g, '\\"') #'
      csvData.push '"' + row.join('","') + '"'
    return csvData.join('\n') + '\n'


  persistToFile = (filename, csv) ->
    onInitFs = (fs) ->
      fs.root.getFile(filename, {create:true}, (fileEntry) ->
        fileEntry.createWriter( (writer) ->
          blob = new Blob([csv], {type: 'text/csv'});
          writer.seek(writer.length)
          writer.write(blob)
        , errorHandler)
      , errorHandler)
    window.webkitRequestFileSystem(window.PERSISTENT, 50*1024*1024, onInitFs, errorHandler);
  
  errorHandler = (e) ->
    msg = ''

    switch (e.code)
      when FileError.QUOTA_EXCEEDED_ERR
        msg = 'QUOTA_EXCEEDED_ERR'
      when FileError.NOT_FOUND_ERR
        msg = 'NOT_FOUND_ERR'
      when FileError.SECURITY_ERR
        msg = 'SECURITY_ERR'
      when FileError.INVALID_MODIFICATION_ERR
        msg = 'INVALID_MODIFICATION_ERR'
      when FileError.INVALID_STATE_ERR
        msg = 'INVALID_STATE_ERR'
      else
        msg = 'Unknown Error'

    console.log('Error: ' + msg)
  return obj
)()

###
#
# Database that keeps track of the searches we have performed with Google
#
#
###

db_changes = chrome.runtime.connect {name: 'db_changes'}
window.db = new Dexie('searchTrack')
db.version(1).stores({
  Search: '$$id,&name,*tabs,task' #Searches from Google we are tracking
  Task: '$$id,name,dateCreated' #table of tasks
  Page: '$$id,url' #Pages we are keeping info on
  PageVisit: '$$id,tab,task,page,referrer' #Visits to individual pages
  PageEvent: '$$id,pageVisit,type,time' #Events for a specific visit to a page
  Tab: '$$id,tab,task' # Tabs we are watching
  TabEvent: '$$id,tab,type,time' #Tab-specific events
  # SavedInfo: '$$id,importance,time' # database for information that user marks as "for later"
})

db.Page.mapToClass(window.Page)
db.Search.mapToClass(window.Search)
db.Task.mapToClass(window.Task)
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
    chrome.tabs[func+"Async"] = (params...) ->
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



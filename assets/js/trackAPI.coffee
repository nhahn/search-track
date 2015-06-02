###
#
# API used for parsing the information stored in chrome.storage for searches
#
###
   
###
#
# Methods used for setting up and managing databases / tables. These should not really
# be interacted with 
#
###
throttle = null
window.dbMethods = (() -> 

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
  SearchInfo: '$$id,&name,*tabs'
  PageInfo: '$$id,url,query,tab'
  PageEvents: '$$id,&page'
  TabEvents: '$$id,tab,action'
  TaskInfo: '$$id,name' #table of tasks
  SavedInfo: '$$id,importance,time' # database for information that user marks as "for later"
})

window.SearchInfo = (params) ->
  properties = _.extend({
    name: ''
    tabs: []
    date: Date.now()
    visits: 1
  }, params)
  this.name = properties.name
  this.tabs = properties.tabs
  this.date = properties.date
  this.visits = properties.visits

window.SearchInfo.prototype.save = () ->
  self = this
  db.SearchInfo.put(this).then (id) ->
    self.id = id
    return self

window.SavedInfo = (params) ->
  properties = _.extend({
    timeElapsed: 0
    time: Date.now()
    loc: 0
    favicon: ''
    newTabId: -1
    title: ''
    url: ''
    note: ''
    color: 'rgba(219,217,219,1)'
    importance: 1
    depth: 0
    height: 0 # for the drag-and-drop list (could be adapted for 2D manipulation)
    position: -1 #TODO
    favorite: false   # will be able to "favorite" newTabs
    ref: false   # is it a reference newTab?
    task: ''
  }, params)
  this.timeElapsed = properties.timeElapsed
  this.time = properties.time
  this.loc = properties.loc
  this.favicon = properties.favicon
  this.newTabId = properties.newTabId
  this.title = properties.title
  this.note = properties.note
  this.color = properties.color
  this.importance = properties.importance
  this.depth = properties.depth
  this.height = properties.height
  this.position = properties.position
  this.favorite = properties.favorite
  this.ref = properties.ref
  this.task = properties.task

window.SavedInfo.prototype.save = () ->
  self = this
  db.SavedInfo.put(this).then (id) ->
    self.id = id
    return self

window.TaskInfo = (params) ->
  properties = _.extend({
    name: ''
    dateCreated: Date.now()
    order: 999
  }, params)
  this.name = properties.name
  this.dateCreated = properties.dateCreated
  this.order = properties.order

window.TaskInfo.prototype.save = () ->
  self = this
  db.TaskInfo.put(this).then (id) ->
    self.id = id
    return self

window.PageInfo = (params) ->
  properties = _.extend({
    isSERP: false
    url: ''
    query: ''
    tab: -1
    date: Date.now()
    visits: 1
    referrer: null
    title: ''
    vector: {} 
    topics: ''
    topic_vector: []
    size: 0
  }, params)
  this.isSERP = properties.isSERP
  this.query = properties.query
  this.url = properties.url
  this.tab = properties.tab
  this.date = properties.date
  this.visits = properties.visits
  this.title = properties.title
  this.referrer = properties.referrer
  this.vector = properties.vector
  this.topics = properties.topics
  this.topic_vector = properties.topic_vector
  this.size = properties.size

PageInfo.prototype.save = () ->
  self = this
  db.PageInfo.put(this).then (id) ->
    self.id = id
    return self

db.PageInfo.mapToClass(window.PageInfo)
db.SearchInfo.mapToClass(window.SearchInfo)
db.SavedInfo.mapToClass(window.SavedInfo)
db.Task.mapToClass(window.TaskInfo)

db.open()
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

Logger.useDefaults()

window.AppSettings = (() ->
  obj = {}
  settings = ['trackTab', 'trackPage', 'hashTracking', 'logLevel']
  handlers = {}
  get_val = _.map settings, (itm) ->
    return 'setting-'+itm
    
  chrome.storage.local.get get_val, (items) ->
    for own key, val of items
      obj[key] = val
    for handler in handlers.ready
      handler.call(obj)
    
  
  for setting in settings
    ((setting) ->
      Object.defineProperty obj, setting, {
        set: (value) ->
          hsh = {}
          hsh['setting-'+setting] = value
          obj['setting-'+setting] = value
          chrome.storage.local.set hsh, () ->
            if handlers[setting]
              for handler in handlers[setting]
                handler.call()
            
        get: () ->
          return obj['setting-'+setting]
      }
    )(setting)

  obj.on = (types..., func) ->
    for type in types
      console.log ("Invalid Event!") if settings.indexOf(type) < 0 && ['ready'].indexOf(type) < 0
      if handlers[type]
        handlers[type].push(func)
      else
        handlers[type] = [func]
  
  obj.listSettings = () ->
    return settings
     
  chrome.storage.onChanged.addListener (changes, areaName) ->
    for own key, val of changes
      if obj.hasOwnProperty(key)
        obj[key] = val.newValue
    
  return obj
)()

AppSettings.on 'logLevel', 'ready', (settings) ->
  Logger.setLevel(AppSettings.logLevel)

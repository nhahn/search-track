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
window.db = new Dexie('searchTrack').version(1)
.stores({
  SearchInfo: '$$id,&name'
  PageInfo: '$$id,url,query,tab'
  PageEvents: '$$id,&page'
  TabInfo: '$$id,tab'
})
.on 'changes', (changes) ->
  db_changes.postMessage
  for change in changes
    switch change.type
      when 1 #CREATED
        db_changes.postMessage({type: 'created', table: change.table, key: change.key, obj: change.obj})
      when 2 #UPDATED
        db_changes.postMessage({type: 'updated', table: change.table, key: change.key, obj: change.obj})
      when 3 #DELETED
        db_changes.postMessage({type: 'deleted', table: change.table, key: change.key, obj: change.oldObj})
.open()

Dexie.Proise.on 'error', (err) ->
  Logger.error("Uncaught error: " + err)

Logger.useDefaults()
AppSettings.on 'logLevel', 'ready', (settings) ->
  Logger.setLevel(settings.logLevel)

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
            for handler in handlers.setting
              handler.call(obj)
            
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
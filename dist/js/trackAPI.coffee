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
    
  obj.createTable = (name, attributes) ->
    obj_ret = {}
    obj_ret.db = TAFFY()
    #Lets us track which running version of this file is actually updating the DB
    updateID = dbMethods.generateUUID()
    updateFunction = null
    onDBChange = (_this) ->
      if this.length >= 1250
          console.log 'persisting to file'
          old = obj_ret.db().order('time asec').limit(250).get()

          tabs = _.filter(old, (e) -> e.type == 'tab')
          if tabs.length > 0
            attributes = ['snapshotId', 'windowId', 'id', 'openerTabId', 'index', 'status', 'snapshotAction', 'domain', 'url', 'domainHash', 'urlHash', 'favIconUrl', 'time']
            tabCsv = objects2csv(tabs, attributes)
            persistToFile('_tabLogs.csv', tabCsv)

          focuses = _.filter(old, (e) -> e.type == 'focus')
          if focuses.length > 0
            attributes = ['action', 'windowId', 'tabId', 'time']
            focusCsv = objects2csv(focuses, attributes)
            persistToFile('_focusLogs.csv', focusCsv)

          obj_ret.db(old).remove()
        hsh = {}
        hsh[name] = {db: _this, updateId: updateID}
        chrome.storage.local.set hsh

    settings =
      template: {}
      onDBChange: () ->
        console.log 'onDBChange throttle'
        chrome.runtime.sendMessage({updated:true})
        clearTimeout(throttle)
        _this = this
        _exec = () -> onDBChange(_this)
        throttle = setTimeout(_exec, 500)
        
    #Grab the info from localStorage and lets update it
    chrome.storage.onChanged.addListener (changes, areaName) ->
      if changes[name]? 
        if !changes[name].newValue?
          obj_ret.db = TAFFY()
          obj_ret.db.settings(settings)
          updateFunction() if updateFunction?
        else if changes[name].newValue.updateid != updateID
          obj_ret.db = TAFFY(changes[name].newValue.db, false)
          obj_ret.db.settings(settings)
          updateFunction() if updateFunction?

    chrome.storage.local.get name, (retVal) ->
      if retVal[name]?
        obj_ret.db = TAFFY(retVal[name].db)
      obj_ret.db.settings(settings)
      updateFunction() if updateFunction?

    obj_ret.clearDB = () ->
      chrome.storage.local.remove(name)
      obj_ret.db = TAFFY()
      console.log 'deleting spill files'
      window.webkitRequestFileSystem(window.PERSISTENT, 50*1024*1024, (fs) ->

        fs.root.getFile('_tabLogs.csv', {create: false}, (fileEntry) ->
          fileEntry.remove(() -> 
            console.log('File removed.')
          , errorHandler)
        , errorHandler)

        fs.root.getFile('_focusLogs.csv', {create: false}, (fileEntry) ->
          fileEntry.remove(() ->
            console.log('File removed.')
          , errorHandler)
        , errorHandler)

      , errorHandler)

    obj_ret.db.settings(settings)
    obj_ret.updateFunction = (fn) -> updateFunction = fn

    return obj_ret
  
  return obj
)()

###
#
# Database that keeps track of the searches we have performed with Google
#
#
###
window.SearchInfo = (() ->
  return dbMethods.createTable('queries',{})
)()

###
# Structure of our storage
# queries: { 
#     name: _Name / query term used
#     date: _last time the query was performed
#  }
# tab
###
window.PageInfo = (() ->
  return dbMethods.createTable('pages',{})
)()

#DB for tracking behavior through page events 
window.PageEvents = (() ->
  return dbMethods.createTable('page_events', [])
)()

window.TabInfo = (() ->
  return dbMethods.createTable('page_events', [])
)()

# database for information that user marks as "for later"
window.SavedInfo = (() ->
  return dbMethods.createTable('tabs', [])
)()

# database for user's tasks
window.TaskInfo = (() ->
  return dbMethods.createTable('tasks', [])
)()

window.AppSettings = (() ->
  obj = {}
  settings = ['trackTab', 'trackPage', 'hashTracking']
  
  get_val = _.map settings, (itm) ->
    return 'setting-'+itm
    
  chrome.storage.local.get get_val, (items) ->
    for own key, val of items
      obj[key] = val
  
  for setting in settings
    ((setting) ->
      Object.defineProperty obj, setting, {
        set: (value) ->
          hsh = {}
          hsh['setting-'+setting] = value
          obj['setting-'+setting] = value
          chrome.storage.local.set hsh, () ->
        get: () ->
          return obj['setting-'+setting]
      }
    )(setting)

  obj.listSettings = () ->
    return settings
   
  chrome.storage.onChanged.addListener (changes, areaName) ->
    for own key, val of changes
      if obj.hasOwnProperty(key)
        obj[key] = val.newValue
    
  return obj
)()

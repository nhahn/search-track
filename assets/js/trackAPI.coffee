###!!!
#! This file is autogenerated. To modify please change the appropriate file in
#! the js/api folder
###


###
#
# Superclass for all of our object classes. This has some default methods we can use for organization
#
###

class Base
  table: () ->
    db[this.constructor.name]
  @table: () ->
    db[this.name]
  
  ## TODO if i really want this -- could be stupidly complicated :/
  associationHash: () ->
    for own prop, val of this
      if _.isObject(val) and val instanceof Base #Check this is a populated value we want to deconstruct
       {prop: prop, obj: val, table: this.table()}
       
  save: () ->
    this.table().put(this).then (id) =>
      @id = id
      return this
     
  fillAssociation: (name) ->
   this.table().get(this[name.capitalize()]).then (obj) =>
      this[name] = obj
    .catch (err) =>
      Error.warn(err)
      
  @fillAssociations: (objs, name) ->
    Promise.map(objs, (obj) -> obj.fillAssociation(name))
    
  capitalize = (s) ->
    s.charAt(0).toUpperCase() + s.substring(1).toLowerCase()
  
  @forId: (id) ->
    return this.table().get(id).then (obj) ->
      return obj
  
  delete: () ->
    this.table().delete(@id)
###
#
# Table for tracking individual web pages we want to monitor in searches / tasks. 
#
###

# TODO define some of these parameters????? 

class Page extends Base
  constructor: (params) ->
    properties = _.extend({
      favicon: ''
      isSearch: false
      query: ''
      url: ''
      domain: ''
      time: Date.now()
      title: ''
      vector: {} 
      topics: ''
      topic_vector: []
      size: 0
      notes: ''
      color: 'rgba(219,217,219,1)'
      depth: 0
      height: 0 # for the drag-and-drop list (could be adapted for 2D manipulation)
      favorite: false   # will be able to "favorite" newTabs
    }, params)
    @favicon = properties.favicon
    @isSearch = properties.isSearch
    @query = properties.query
    @url = properties.url
    @domain = properties.domain
    @time = properties.time
    @title = properties.title
    @vector = properties.vector
    @topics = properties.topics
    @topic_vector = properties.topic_vector
    @size = properties.size
    @notes = properties.notes
    @color = properties.color
    @depth = properties.depth
    @height = properties.height
    @favorite = properties.favorite

###
#
# Table for tracking page level events. We associated this with a pageVisit -- b/c someone could be using a page differently # between different visits 
#
###

class PageEvent extends Base
  constructor: (params) ->
    properties = _.extend({
      type: 'scrollPostion' # Enum of ['scrollPosition']
      pageVisit: '' # The particular visit to a page we are recording events for 
      data: '' #Field depends on the above type
      time: Date.now()
    }, params)
    @type = properties.type
    @pageVisit = properties.pageVisit
    @data = properties.data
    @time = properties.time
###
#
# Table individual web-page visits. This is created whenever someone visits a page by navigating to its URL
# (think of it as a history event).
#
###

class PageVisit extends Base
  constructor: (params) ->
    properties = _.extend({
      page: '' # The page visited
      tab: '' # The tab this page was visited from
      task: '' #The "task" this particular visit was associated with. A page could be associated with different tasks!!
      referrer: '' #If a another page "referred" us here, we record the previous pageEvent that did so (so we keep track of tasks)
      type: '' #Enum of navigation ['forward', 'back', 'link', 'typed', 'navigation']
      time: Date.now() #When this visit occured
      fragment: '' #The hash(#) fragment we 
    }, params)
    @page = properties.page
    @tab = properties.tab
    @task = properties.task
    @referrer = properties.referrer
    @type = properties.type
    @time = properties.time
    @fragment = properties.fragment
    
  @forPage: (pageId) ->
    db.PageVisit.where('page').equals(pageId)
  
  @forTab: (tabId) ->
    db.PageVisit.where('tab').equals(tabId)
    
  # Returns the path of PageVisits required to get to this point
  getPath: () ->
    if @referrer
      db.PageVisit.get(@referrer).then (visit) ->
        return [visit, visit.getPath()]
      .spread (visit,arr) ->
        return [visit].concat(arr)
    else
      return this
    
# Sidenote: for a possible graph in order to visualize these @see: https://github.com/cpettitt/dagre-d3/wiki
###
#
# Table for tracking searches we've performed
#
###

class Search extends Base
  constructor: (params) ->
    properties = _.extend({
      name: ''
      tabs: []
      date: Date.now()
      visits: 1
    }, params)
    @name = properties.name
    @tabs = properties.tabs
    @date = properties.date
    @visits = properties.visits

###
#
# Global Application settings hash (that auto-updates in the backend and refreshes stuff elsewhere)
#
# AppSettings.on (setting..., func()) : 
#   * Takes and array of settings, and a function. Will call the function when the setting is updated.
#   * Note the special "setting", 'ready', that will be called when it has finished fetching the settings
#   from chrome storage. 
#
# AppSettings.listSettings :
#   * Returns an array of all of the different setting types 
#
# To add a new setting -- create a new entry in the 'settings' array, and then it will become available for use
###
Logger.useDefaults()

window.AppSettings = (() ->
  obj = {}
  settings = ['trackTab', 'trackPage', 'hashTracking', 'logLevel'] #Add a setting name here to make it available for use
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
#####
#
# Table for tab-based page tracking. Helps organizing searches and history
#
#####

class Tab extends Base
  constructor: (params) ->
    properties = _.extend({
      tab: -1
      windowId: -1
      openerTab: -1
      position: 0
      session: '' #the 
      pageVisit: '' #The pageVisit that is currently active
      status: 'active' # This is an enum: ['active', 'stored', 'closed']
      task: '' #The ID of the task this tab is associated with (TODO blank is newTab page i guess??)
      date: Date.now()
    }, params)
    @tab = properties.tab
    @windowId = properties.windowId
    @openerTabId = properties.openerTabId
    @position = properties.position
    @session = properties.session
    @pageVisit = properties.pageVisit
    @status = properties.status
    @date = properties.date
    
  store: () ->
    chrome.tabs.removeAsync(@tab).then () =>
      chrome.session.getRecentlyClosedAsync({maxResults: 1})
    .then (sessions) =>
      @session = sessions[0]
      this.save()
      
  @findByTabId: (tabId) ->
    db.Tab.where('tab').equals(tabId).and((val) -> val.status is 'active').first()
   
  
  
    
    
###
#
# Table for tracking individual tab events 
#
###

class TabEvent extends Base
  constructor: (params) ->
    properties = _.extend({
      type: 'updated' # Enum of ['windowFocus', 'tabFocus', 'moved', 'removed', 'attached', 'updated']
      tab: '' # Tab this is associated with
      from: '' #Field depends on the above type
      to: '' #Field depends on the above type
      time: Date.now()
    }, params)
    @type = properties.type
    @tab = properties.tab
    @from = properties.from
    @to = properties.to
    @time = properties.time

#closes other tasks open in the current window, drags the tabs from other windows into this one, 

class Task extends Base
  constructor: (params) ->
    properties = _.extend({
      name: ''
      dateCreated: Date.now()
      order: 999
      hidden: false
      tabs: [] # used to maintain searches
    }, params)
    @name = properties.name
    @dateCreated = properties.dateCreated
    @order = properties.order
    @tabs = properties.tabs


  ###
  # Adds a page from this task. 
  ###
  addPage: (page_id) ->
    pos = @pages.indexOf(page_id)
    return false if pos < 0
    @pages.splice(pos, 1)
    return db.Task.put(this).then (id) =>
      return this

  ###
  # Removes a page from this task
  ###
  removePage: (page_id) ->
    @pages.push(page_id)
    return db.Task.put(this).then (id) =>
      return this

    #TODO have more complex heuristics, etc for getting an existing task
  @generateTask: () ->
    task = new Task({name: 'Unknown'+Math.random()*10000, hidden: true})
    task.save()

  cleanUp: () ->
    chrome.windows.getCurrentAsync({populate: true}).then (window) =>
      # Record the position of each tab in the window
      ids = _.map window.tabs, (t) -> t.id
      db.Tab.where('tabId').anyOf(ids).and((val) -> val.status is 'active')
    .then(tabs) =>
      Promise.map tabs, (tab) =>
        if @tabs.indexOf(tab.id) >= 0
          return tab
          #keep the tab in the window
        else
          return tab.store()
      
  

#####
#
# Theses are shortcut scopes for managing tables
#
####

(->
  ScopeAddons = (db) ->
  
    #Will get the most recent record for a given collection
    db.Collection.prototype.mostRecent = () ->
      return this.reverse().sortBy('time').then (coll) ->
        return coll[0]
        
    db.Collection.prototype.previousOne = () ->
      return this.reverse().sortBy('time').then (coll) ->
        return coll[1]
  
  Dexie.addons.push(ScopeAddons)
)()
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
  Task: '$$id,name,*pages' #table of tasks
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



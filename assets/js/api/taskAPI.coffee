class Task extends Base
  #jQuery-esque constructor (you only speciy the parameters in a hash that you don't want to be default / are required
  constructor: (params) ->
    super {
      name: undefined                  #Task name (required)
      dateCreated: Date.now()   #Date task was created
      order: 999                #Order of the task?
      isTemp: false             #Are we using a temporary name? try and fill it in if we are
      hidden: false             #Whether the task is visible or not to the user TODO get rid of me??
      isSearch: false           #Whether the task spawned from a search or not
      parent: ''                #The parent task for this task
      level: 1                  #The nested "level" of the task (1 being the child of the tree)
      annotation: "Annotate Here. (Tip: Use Command+Period to minimize)"
    }, params 

  # Doesn't work
  changeName: (name) ->
    console.log name
    console.log @name
    console.log this
    console.log this.table()
    @name = name
    return db.Task.put(this).then (id) =>
      return this

  #TODO have more complex heuristics, etc for getting an existing task
  ###
  # Generate or reuse a task based on the page, tab, etc.
  # param tab - a Tab object that we want to find / or create a task for
  # param page - the Page object we want to find / or create a task for
  # param foce - Forcible generate a new task for the page and tab
  ###
  @generateBaseTask: (tab, page, force) ->
    throw new ReferenceError("Tab is not defined for creating a new task #{tab}") if !tab 
    if page and page.isSearch
      return Dexie.Promise.all([db.Task.where('name').equals(page.query).first(), db.Task.get(tab.task)]).then (args) ->
        [searchTask, curTask] = args
        return searchTask if searchTask #We've done this search before -- keep it under the same parent task before
        task = new Task({name: page.query, hidden: false, isSearch: true, parent: curTask.parent}) #We haven't done this before -- assign it to our current parent
        return task.save()
    else if force or !tab.task
      return db.PageVisit.where('page').equals(page.id).mostRecent().then (pageVisit) ->
        if pageVisit
          return Task.find(pageVisit.task) #We will, by default, try and use the most recent task for this page (child and parent)
        else
          if tab.task
            return db.Task.get(tab.task).then (task) ->
              Task.generateNewTabTemp(curTask.parent)
          else
            return Task.generateParentTemp().then (par) ->
              Task.generateNewTabTemp(par)
    else
      return Task.find(tab.task)
      
  ###
  # Generate a temporary low level task for the given parent that will be filled in later
  # param parent - The parent task we want to generate a base task for
  ###
  @generateNewTabTemp: (parent) ->
    task = new Task({name: "Temp"+Math.floor(Math.random()*10000), parent: parent.id, level: 1, isTemp: true})
    task.save()
    
  ###
  # Generate a temporary parent when a new window is created
  ###
  @generateParentTemp: () ->
    task = new Task({name: "Temp"+Math.floor(Math.random()*10000), level: 2, isTemp: true})
    task.save()
    
  removeTempTask: () ->
    if @isTemp and @parent
      return @delete().then () =>
        db.Task.get(@parent)
      .then (parent) ->
        if parent.isTemp
          parent.removeTempTask()
    else
      return @delete()
      
  #Renames temporary base tasks, and collapses those tasks that
  #have the same titles into each other (within the same detected task)
  nameTempTask: (name) ->
    return this if !@isTemp
    self = this
    db.transaction 'rw!', db.Task, db.Tab, db.PageVisit, () ->
      #Loopup other tasks that might have the same name
      Dexie.Promise.all([
        db.Task.where('name').equals(name).toArray()
        db.Task.get(self.parent)
      ]).then (args) ->
        [res, parent] = args
        if res.length > 0
          #Find one with a matching parent
          match = _.find(res, (val) -> val.parent == self.parent)
          if !match and parent.isTemp #In this case -- we want to find any other ones with temp parents as well (and collapse them)
            match = db.Task.where('id').anyOf(_.map(res, (val) -> val.parent)).and((val) -> val.isTemp).first()
          return Dexie.Promise.all([match, parent])
        else
          throw new RecordMissingError("No existing task with that name")
      .then (args) ->
        [existingTask, parent] = args
        throw new RecordMissingError("No existing task with a shared temporary parent") if !existingTask
        db.Tab.where('task').equals(self.id).toArray().then (res) ->
          for tab in res
            tab.task = existingTask.id
            db.Tab.update(tab.id, {task: existingTask.id})
        db.PageVisit.where('task').equals(self.id).toArray().then (res) ->
          for pageVisit in res
            pageVisit.task = existingTask.id
            db.PageVisit.update(pageVisit.id, {task: existingTask.id})
        self.delete()
        parent.delete() if parent.isTemp
        return existingTask
      .catch RecordMissingError, (err) ->
        Logger.debug(err)
        self.name = name
        self.isTemp = false
        self.save()
  

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
      
  getChildren: () ->
    db.Task.where('parent').equals(@id)
    
  @getTopLevelTasks: () ->
    db.Task.where('parent').equals('')

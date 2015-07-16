#closes other tasks open in the current window, drags the tabs from other windows into this one, 

class Task extends Base
  constructor: (params) ->
    properties = _.extend({
      name: ''                  #Task name
      dateCreated: Date.now()   #Date task was created
      order: 999                #Order of the task?
      hidden: false             #Whether the task is visible or not to the user
      isSearch: false           #Whether the task spawned from a search or not
      parent: ''                #The parent task for this task
      level: 1                  #The nested "level" of the task (1 being the child of the tree)
      annotation: "Annotate Here. (Tip: Use Command+Period to minimize)"
    }, params)
    @name = properties.name
    @dateCreated = properties.dateCreated
    @order = properties.order
    @hidden = properties.hidden
    @isSearch = properties.isSearch
    @parent = properties.parent
    @level = properties.level
    @annotation = properties.annotation

  # Doesn't work
  changeName: (name) ->
    console.log name
    console.log @name
    console.log this
    console.log this.table
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
    if page and page.isSearch
      return db.Task.where('name').equals(page.query).first().then (task) ->
        return task if task
        task = new Task({name: page.query, hidden: false, isSearch: true, annotation:"Annotate Here. (Tip: Use Command+Period to minimize)"})
        return task.save()
    else if force or !tab or !tab.task
      task = new Task({name: 'Unknown'+Math.floor(Math.random()*10000), hidden: true, annotation:"Annotate Here. (Tip: Use Command+Period to minimize)"})
      return task.save()
    else
      return Task.find(tab.task)
      
  @generateParentTask: () ->
    #TODO

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

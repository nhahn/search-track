#closes other tasks open in the current window, drags the tabs from other windows into this one, 

class Task extends Base
  constructor: (params) ->
    properties = _.extend({
      name: ''
      dateCreated: Date.now()
      order: 999
      hidden: false
    }, params)
    @name = properties.name
    @dateCreated = properties.dateCreated
    @order = properties.order


  ###
  # Removes a page from this task. 
  ###
  addPage: (page_id) ->
    pos = @pages.indexOf(page_id)
    return false if pos < 0
    @pages.splice(pos, 1)
    return db.Task.put(this).then (id) =>
      return this

  ###
  # Adds a page to this task
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
      
  
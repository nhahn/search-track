class Branch extends Base
  #jQuery-esque constructor (you only speciy the parameters in a hash that you don't want to be default / are required
  constructor: (params) ->
    super {
      name: ''           #Optional branch name
      dateCreated: Date.now()   #Date branch was born
      isTemp: false             #Permenant branch we want to monitor or temporary branch 
      hidden: false             #A visible or hidden branch
      isSearch: false           #Whether the task spawned from a search or not
      parent: ''                #The parent branch
      pageVisits: []            #The list of page visits (in the order visited)
    }, params

  changeName: (name) ->
    @name = name
    return db.Branch.put(this).then (id) =>
      return this
      
  getChildren: () ->
    db.Branch.where('parent').equals(@id)
  
  #Splits a branch at a current visit, so you save the existing items
  split: (visitId) ->
    #generate a parent to stick all of the existing stuff under, and then
    #branch accordingly
    visitId = _.last(@pageVisits)
    parent = new Branch({
                parent: @parent, 
                pageVisits: @pageVisits.splice(0, @pageVisits.indexOf(visitId) + 1)
               })
    @parent = parent
    Dexie.Promise.all([
      this.save(),
      parent.save(),
      (new Branch({parent: parent})).save()
    ]).then (args) ->
      return args[2]
  
  populatedVisits: () ->
    db.transaction 'rw', db.PageVisit, () =>
      Dexie.Promise.all(@pageVisits.map((visit) =>
        PageVisit.find(visit)
      ))
    
  @getTopLevelBranches: () ->
    db.Branch.where('parent').equals('')
    
  

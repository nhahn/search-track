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
  
  @find: (id) ->
    return this.table().get(id).then (obj) ->
      return obj
  
  delete: () ->
    this.table().delete(@id)
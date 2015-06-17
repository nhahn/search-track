###
#
# Superclass for all of our object classes. This has some default methods we can use for organization
#
###
capitalize: (s) ->
  s.charAt(0).toUpperCase() + s.substring(1).toLowerCase()

class Base
  table: () ->
    db[this.constructor.name]
  save: () ->
    resolv = []
    for own prop, val of this
      if _.isObject(val) and val instanceof Base #Check this is a populated value we want to deconstruct
        do (val) ->
          resolv.push val.save().then (res) ->
            val = res.id #This reverts any populated values to their normal IDs for saving
    Promise.all(resolv).bind(this).then () ->
      this.table().put(this)
    .then (id) ->
      @id = id
      return this
      
  fillAssociation: (name) ->
    this.table().get(this[name.capitalize()]).then (obj) =>
      this[name] = obj
    .catch (err) =>
      Error.warn(err)
      
  @fillAssociations: (objs, name) ->
    Promise.map(objs, (obj) -> obj.fillAssociation(name))
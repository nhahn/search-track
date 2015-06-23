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
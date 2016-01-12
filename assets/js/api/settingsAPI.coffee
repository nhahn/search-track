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
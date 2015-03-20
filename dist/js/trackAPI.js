
/*
 *
 * API used for parsing the information stored in chrome.storage for searches
 *
 */

/*
 * Structure of our storage
 * queries: { 
 *     name: _Name / query term used
 *     date: _last time the query was performed
 *  }
 * tab
 */
var generateUUID;

generateUUID = function() {
  var d, uuid;
  d = (new Date).getTime();
  uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r;
    r = (d + Math.random() * 16) % 16 | 0;
    d = Math.floor(d / 16);
    return (c === 'x' ? r : r & 0x3 | 0x8).toString(16);
  });
  return uuid;
};

window.SearchInfo = (function() {
  var obj, settings, updateFunction, updateID;
  obj = {};
  obj.db = TAFFY();
  updateID = generateUUID();
  updateFunction = null;
  settings = {
    template: {},
    onDBChange: function() {
      return chrome.storage.local.set({
        'queries': {
          db: this,
          updateId: updateID
        }
      });
    }
  };
  chrome.storage.onChanged.addListener(function(changes, areaName) {
    if (changes.queries != null) {
      if (changes.queries.newValue == null) {
        obj.db = TAFFY();
        obj.db.settings(settings);
        if (updateFunction != null) {
          return updateFunction();
        }
      } else if (changes.queries.newValue.updateid !== updateID) {
        obj.db = TAFFY(changes.queries.newValue.db, false);
        obj.db.settings(settings);
        if (updateFunction != null) {
          return updateFunction();
        }
      }
    }
  });
  chrome.storage.local.get('queries', function(retVal) {
    if (retVal.queries != null) {
      obj.db = TAFFY(retVal.queries.db);
    }
    obj.db.settings(settings);
    if (updateFunction != null) {
      return updateFunction();
    }
  });
  obj.clearDB = function() {
    chrome.storage.local.remove('queries');
    return obj.db = TAFFY();
  };
  obj.db.settings(settings);
  obj.updateFunction = function(fn) {
    return updateFunction = fn;
  };
  return obj;
})();

window.PageInfo = (function() {
  var obj, settings, updateFunction, updateID;
  obj = {};
  obj.db = TAFFY();
  updateID = generateUUID();
  updateFunction = null;
  settings = {
    template: {},
    onDBChange: function() {
      return chrome.storage.local.set({
        'pages': {
          db: this,
          updateId: updateID
        }
      });
    }
  };
  chrome.storage.onChanged.addListener(function(changes, areaName) {
    if (changes.pages != null) {
      if (changes.pages.newValue == null) {
        obj.db = TAFFY();
        obj.db.settings(settings);
        if (updateFunction != null) {
          return updateFunction();
        }
      } else if (changes.pages.newValue.updateid !== updateID) {
        obj.db = TAFFY(changes.pages.newValue.db, false);
        obj.db.settings(settings);
        if (updateFunction != null) {
          return updateFunction();
        }
      }
    }
  });
  chrome.storage.local.get('pages', function(retVal) {
    if (retVal.pages != null) {
      obj.db = TAFFY(retVal.pages.db);
    }
    obj.db.settings(settings);
    if (updateFunction != null) {
      return updateFunction();
    }
  });
  obj.clearDB = function() {
    chrome.storage.local.remove('pages');
    return obj.db = TAFFY();
  };
  obj.db.settings(settings);
  obj.updateFunction = function(fn) {
    return updateFunction = fn;
  };
  return obj;
})();

window.PageEvents = (function() {
  var obj, settings, updateFunction, updateID;
  obj = {};
  obj.db = TAFFY();
  updateID = generateUUID();
  updateFunction = null;
  settings = {
    template: {},
    onDBChange: function() {
      return chrome.storage.local.set({
        'page_events': {
          db: this,
          updateId: updateID
        }
      });
    }
  };
  chrome.storage.onChanged.addListener(function(changes, areaName) {
    if (changes.page_events != null) {
      if (changes.page_events.newValue == null) {
        obj.db = TAFFY();
        obj.db.settings(settings);
        if (updateFunction != null) {
          return updateFunction();
        }
      } else if (changes.page_events.newValue.updateid !== updateID) {
        obj.db = TAFFY(changes.page_events.newValue.db, false);
        obj.db.settings(settings);
        if (updateFunction != null) {
          return updateFunction();
        }
      }
    }
  });
  chrome.storage.local.get('page_events', function(retVal) {
    if (retVal.page_events != null) {
      obj.db = TAFFY(retVal.page_events.db);
    }
    obj.db.settings(settings);
    if (updateFunction != null) {
      return updateFunction();
    }
  });
  obj.clearDB = function() {
    chrome.storage.local.remove('page_events');
    return obj.db = TAFFY();
  };
  obj.db.settings(settings);
  obj.updateFunction = function(fn) {
    return updateFunction = fn;
  };
  return obj;
})();

//# sourceMappingURL=trackAPI.js.map

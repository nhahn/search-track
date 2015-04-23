
/*
 *
 * API used for parsing the information stored in chrome.storage for searches
 *
 */

/*
 *
 * Methods used for setting up and managing databases / tables. These should not really
 * be interacted with 
 *
 */
var __hasProp = {}.hasOwnProperty;

window.dbMethods = (function() {
  var errorHandler, obj, objects2csv, persistToFile;
  obj = {};
  obj.generateUUID = function() {
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
  objects2csv = function(objects, attributes) {
    var attribute, csvData, object, row, _i, _j, _len, _len1;
    csvData = new Array();
    csvData.push('"' + attributes.join('","') + '"');
    for (_i = 0, _len = objects.length; _i < _len; _i++) {
      object = objects[_i];
      row = [];
      for (_j = 0, _len1 = attributes.length; _j < _len1; _j++) {
        attribute = attributes[_j];
        row.push(("" + object[attribute]).replace(/\\/g, "\\\\").replace(/"/g, '\\"'));
      }
      csvData.push('"' + row.join('","') + '"');
    }
    return csvData.join('\n') + '\n';
  };
  persistToFile = function(filename, csv) {
    var onInitFs;
    onInitFs = function(fs) {
      return fs.root.getFile(filename, {
        create: true
      }, function(fileEntry) {
        return fileEntry.createWriter(function(writer) {
          var blob;
          blob = new Blob([csv], {
            type: 'text/csv'
          });
          writer.seek(writer.length);
          return writer.write(blob);
        }, errorHandler);
      }, errorHandler);
    };
    return window.webkitRequestFileSystem(window.PERSISTENT, 50 * 1024 * 1024, onInitFs, errorHandler);
  };
  errorHandler = function(e) {
    var msg;
    msg = '';
    switch (e.code) {
      case FileError.QUOTA_EXCEEDED_ERR:
        msg = 'QUOTA_EXCEEDED_ERR';
        break;
      case FileError.NOT_FOUND_ERR:
        msg = 'NOT_FOUND_ERR';
        break;
      case FileError.SECURITY_ERR:
        msg = 'SECURITY_ERR';
        break;
      case FileError.INVALID_MODIFICATION_ERR:
        msg = 'INVALID_MODIFICATION_ERR';
        break;
      case FileError.INVALID_STATE_ERR:
        msg = 'INVALID_STATE_ERR';
        break;
      default:
        msg = 'Unknown Error';
    }
    return console.log('Error: ' + msg);
  };
  obj.createTable = function(name, attributes) {
    var obj_ret, settings, updateFunction, updateID;
    obj_ret = {};
    obj_ret.db = TAFFY();
    updateID = dbMethods.generateUUID();
    updateFunction = null;
    settings = {
      template: {},
      onDBChange: function() {
        var focusCsv, focuses, hsh, old, tabCsv, tabs;
        if (this.length >= 1250) {
          console.log('persisting to file');
          old = obj_ret.db().order('time asec').limit(250).get();
          tabs = _.filter(old, function(e) {
            return e.type === 'tab';
          });
          if (tabs.length > 0) {
            attributes = ['snapshotId', 'windowId', 'id', 'openerTabId', 'index', 'status', 'snapshotAction', 'domain', 'url', 'domainHash', 'urlHash', 'favIconUrl', 'time'];
            tabCsv = objects2csv(tabs, attributes);
            persistToFile('_tabLogs.csv', tabCsv);
          }
          focuses = _.filter(old, function(e) {
            return e.type === 'focus';
          });
          if (focuses.length > 0) {
            attributes = ['action', 'windowId', 'tabId', 'time'];
            focusCsv = objects2csv(focuses, attributes);
            persistToFile('_focusLogs.csv', focusCsv);
          }
          obj_ret.db(old).remove();
        }
        hsh = {};
        hsh[name] = {
          db: this,
          updateId: updateID
        };
        return chrome.storage.local.set(hsh);
      }
    };
    chrome.storage.onChanged.addListener(function(changes, areaName) {
      if (changes[name] != null) {
        if (changes[name].newValue == null) {
          obj_ret.db = TAFFY();
          obj_ret.db.settings(settings);
          if (updateFunction != null) {
            return updateFunction();
          }
        } else if (changes[name].newValue.updateid !== updateID) {
          obj_ret.db = TAFFY(changes[name].newValue.db, false);
          obj_ret.db.settings(settings);
          if (updateFunction != null) {
            return updateFunction();
          }
        }
      }
    });
    chrome.storage.local.get(name, function(retVal) {
      if (retVal[name] != null) {
        obj_ret.db = TAFFY(retVal[name].db);
      }
      obj_ret.db.settings(settings);
      if (updateFunction != null) {
        return updateFunction();
      }
    });
    obj_ret.clearDB = function() {
      chrome.storage.local.remove(name);
      obj_ret.db = TAFFY();
      console.log('deleting spill files');
      return window.webkitRequestFileSystem(window.PERSISTENT, 50 * 1024 * 1024, function(fs) {
        fs.root.getFile('_tabLogs.csv', {
          create: false
        }, function(fileEntry) {
          return fileEntry.remove(function() {
            return console.log('File removed.');
          }, errorHandler);
        }, errorHandler);
        return fs.root.getFile('_focusLogs.csv', {
          create: false
        }, function(fileEntry) {
          return fileEntry.remove(function() {
            return console.log('File removed.');
          }, errorHandler);
        }, errorHandler);
      }, errorHandler);
    };
    obj_ret.db.settings(settings);
    obj_ret.updateFunction = function(fn) {
      return updateFunction = fn;
    };
    return obj_ret;
  };
  return obj;
})();


/*
 *
 * Database that keeps track of the searches we have performed with Google
 *
 *
 */

window.SearchInfo = (function() {
  return dbMethods.createTable('queries', {});
})();


/*
 * Structure of our storage
 * queries: { 
 *     name: _Name / query term used
 *     date: _last time the query was performed
 *  }
 * tab
 */

window.PageInfo = (function() {
  return dbMethods.createTable('pages', {});
})();

window.PageEvents = (function() {
  return dbMethods.createTable('page_events', []);
})();

window.TabInfo = (function() {
  return dbMethods.createTable('page_events', []);
})();

window.SavedInfo = (function() {
  return dbMethods.createTable('tabs', []);
})();

window.TaskInfo = (function() {
  return dbMethods.createTable('tasks', []);
})();

window.AppSettings = (function() {
  var get_val, obj, setting, settings, _fn, _i, _len;
  obj = {};
  settings = ['trackTab', 'trackPage', 'hashTracking'];
  get_val = _.map(settings, function(itm) {
    return 'setting-' + itm;
  });
  chrome.storage.local.get(get_val, function(items) {
    var key, val, _results;
    _results = [];
    for (key in items) {
      if (!__hasProp.call(items, key)) continue;
      val = items[key];
      _results.push(obj[key] = val);
    }
    return _results;
  });
  _fn = function(setting) {
    return Object.defineProperty(obj, setting, {
      set: function(value) {
        var hsh;
        hsh = {};
        hsh['setting-' + setting] = value;
        obj['setting-' + setting] = value;
        return chrome.storage.local.set(hsh, function() {});
      },
      get: function() {
        return obj['setting-' + setting];
      }
    });
  };
  for (_i = 0, _len = settings.length; _i < _len; _i++) {
    setting = settings[_i];
    _fn(setting);
  }
  obj.listSettings = function() {
    return settings;
  };
  chrome.storage.onChanged.addListener(function(changes, areaName) {
    var key, val, _results;
    _results = [];
    for (key in changes) {
      if (!__hasProp.call(changes, key)) continue;
      val = changes[key];
      if (obj.hasOwnProperty(key)) {
        _results.push(obj[key] = val.newValue);
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  });
  return obj;
})();

//# sourceMappingURL=trackAPI.js.map

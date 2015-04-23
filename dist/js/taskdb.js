var taskDB;

taskDB = (function() {
  var datastore, tDB;
  tDB = {};
  datastore = null;

  /**
  	 * Open a connection to the datastore.
   */
  tDB.open = function(callback) {
    var request, version;
    version = 1;
    request = indexedDB.open('tasks', version);
    request.onupgradeneeded = function(e) {
      var db, store;
      db = e.target.result;
      e.target.transaction.onerror = tDB.onerror;
      if (db.objectStoreNames.contains('task')) {
        db.deleteObjectStore('task');
      }
      store = db.createObjectStore('task', {
        keyPath: 'timestamp'
      });
    };
    request.onsuccess = function(e) {
      datastore = e.target.result;
      callback();
    };
    request.onerror = tDB.onerror;
  };

  /**
   * Fetch all of the todo items in the datastore.
   */
  tDB.fetchTasks = function(callback) {
    var cursorRequest, db, keyRange, objStore, tasks, transaction;
    db = datastore;
    transaction = db.transaction(['task'], 'readwrite');
    objStore = transaction.objectStore('task');
    keyRange = IDBKeyRange.lowerBound(0);
    cursorRequest = objStore.openCursor(keyRange);
    tasks = [];
    transaction.oncomplete = function(e) {
      callback(tasks);
    };
    cursorRequest.onsuccess = function(e) {
      var result;
      result = e.target.result;
      if (!!result === false) {
        return;
      }
      tasks.push(result.value);
      result["continue"]();
    };
    cursorRequest.onerror = tDB.onerror;
  };
  tDB.createTask = function(task, callback) {
    var task;
    var db, objStore, request, timestamp, transaction;
    db = datastore;
    transaction = db.transaction(['task'], 'readwrite');
    objStore = transaction.objectStore('task');
    timestamp = (new Date).getTime();
    task = {
      'task': task,
      'count': 1,
      'timestamp': timestamp
    };
    request = objStore.put(task);
    request.onsuccess = function(e) {
      callback(task);
    };
    request.onerror = tDB.onerror;
  };

  /**
   * Delete a task
   */
  tDB.deleteTask = function(id, callback) {
    var db, objStore, request, transaction;
    db = datastore;
    transaction = db.transaction(['task'], 'readwrite');
    objStore = transaction.objectStore('task');
    request = objStore["delete"](id);
    request.onsuccess = function(e) {
      callback();
    };
    request.onerror = function(e) {
      console.log(e);
    };
  };

  /**
   * Increment a task's counter if it's used.
   */
  tDB.incrementCount = function(id, callback) {
    var db, objStore, request, transaction;
    db = datastore;
    transaction = db.transaction(['task'], 'readwrite');
    objStore = transaction.objectStore('task');
    request = objStore.get(id);
    request.onsuccess = function(e) {
      var requestUpdate, task;
      task = request.result;
      task.count += 1;
      requestUpdate = objStore.put(task);
      requestUpdate.onsuccess = function(e) {
        callback();
      };
      requestUpdate.onerror = tDB.onerror;
    };
  };
  return tDB;
})();

//# sourceMappingURL=taskdb.js.map

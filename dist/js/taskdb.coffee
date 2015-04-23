# task database.
taskDB = do ->
  tDB = {}
  datastore = null

  ###*
  	 * Open a connection to the datastore.
  ###

  tDB.open = (callback) ->
    # Database version.
    version = 1
    # Open a connection to the datastore.
    request = indexedDB.open('tasks', version)
    # Handle datastore upgrades.

    request.onupgradeneeded = (e) ->
      db = e.target.result
      e.target.transaction.onerror = tDB.onerror
      # Delete the old datastore.
      if db.objectStoreNames.contains('task')
        db.deleteObjectStore 'task'
      # Create a new datastore.
      store = db.createObjectStore('task', keyPath: 'timestamp')
      return

    # Handle successful datastore access.

    request.onsuccess = (e) ->
      # Get a reference to the DB.
      datastore = e.target.result
      # Execute the callback.
      callback()
      return

    # Handle errors when opening the datastore.
    request.onerror = tDB.onerror
    return

  ###*
  # Fetch all of the todo items in the datastore.
  ###

  tDB.fetchTasks = (callback) ->
    db = datastore
    transaction = db.transaction([ 'task' ], 'readwrite')
    objStore = transaction.objectStore('task')
    keyRange = IDBKeyRange.lowerBound(0)
    cursorRequest = objStore.openCursor(keyRange)
    tasks = []

    transaction.oncomplete = (e) ->
      # Execute the callback function.
      callback tasks
      return

    cursorRequest.onsuccess = (e) ->
      result = e.target.result
      if ! !result == false
        return
      tasks.push result.value
      result.continue()
      return

    cursorRequest.onerror = tDB.onerror
    return

  # Create a new item

  tDB.createTask = (task, callback) ->
    `var task`
    # Get a reference to the db.
    db = datastore
    # Initiate a new transaction.
    transaction = db.transaction([ 'task' ], 'readwrite')
    # Get the datastore.
    objStore = transaction.objectStore('task')
    # Create a timestamp for the task
    timestamp = (new Date).getTime()
    # Create an object for the task
    task = 
      'task': task
      'count': 1
      'timestamp': timestamp
    # Create the datastore request.
    request = objStore.put(task)
    # Handle a successful datastore put.

    request.onsuccess = (e) ->
      # Execute the callback function.
      callback task
      return

    # Handle errors.
    request.onerror = tDB.onerror
    return

  ###*
  # Delete a task
  ###

  tDB.deleteTask = (id, callback) ->
    db = datastore
    transaction = db.transaction([ 'task' ], 'readwrite')
    objStore = transaction.objectStore('task')
    request = objStore.delete(id)

    request.onsuccess = (e) ->
      callback()
      return

    request.onerror = (e) ->
      console.log e
      return

    return

  ###*
  # Increment a task's counter if it's used.
  ###

  tDB.incrementCount = (id, callback) ->
    db = datastore
    transaction = db.transaction([ 'task' ], 'readwrite')
    objStore = transaction.objectStore('task')
    request = objStore.get(id)

    request.onsuccess = (e) ->
      #get the old value we want to update
      task = request.result
      #increment.
      task.count += 1
      #put this updated object back into the DB!
      requestUpdate = objStore.put(task)
      # Handle a successful datastore put.

      requestUpdate.onsuccess = (e) ->
        callback()
        return

      # Handle errors.
      requestUpdate.onerror = tDB.onerror
      return

    return

  # Export the tDB object.
  tDB

# ---
# generated by js2coffee 2.0.3
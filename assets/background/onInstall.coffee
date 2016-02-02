#####
#
# File for methods executed on installation of this extension (or refresh)
# TODO DRY this up some how.... 
#
#####

(() ->
  # Record all of the currently open tabs that we haven't mentioned before.
  chrome.runtime.onInstalled.addListener () ->
    startupCheck()
  chrome.runtime.onStartup.addListener () ->
    console.log('extension started!')
    startupCheck()
  document.addEventListener "DOMContentLoaded", (event) ->
    startupCheck()

  #Method called when either our extension is installed, or reloaded
  startupCheck = () ->
    chrome.tabs.queryAsync({}).then (tabs) ->
      Promise.map tabs, (chromeTab) ->
        newTab = false
        Promise.resolve(Tab.findByTabId(chromeTab.id)).then (tab) ->
          if tab
            return tab
          else
            tab = new Tab({
                tab: chromeTab.id
                windowId: chromeTab.windowId
                position: chromeTab.index
              })
            newTab = true
            return tab.save()
        .then (tab) ->
          Promise.all([tab, Page.findOrCreate(chromeTab.url), if tab.pageVisit then PageVisit.find(tab.pageVisit) else null])
        .spread (tab, page, pageVisit) ->
          if (pageVisit is null or page.id != pageVisit.page)
            Promise.all([
              if newTab then Branch.find(tab.branch) else (new Branch()).save(),
              (new PageVisit({page: page.id, type: "typed"})).save()
            ]).spread (branch, visit) ->
              tab.pageVisit = visit.id
              tab.branch = branch.id
              branch.pageVisits.push(visit.id)
              Promise.all([branch.save(), tab.save()])
          else
            return tab
      .then (tabs) ->
        #Do something with the newly created tabs here
        
  # Get the content (async) of any new pages we added to the DB
  getContentAndTokenize = (tab, page) ->
    Logger.debug "TOK:\n" + page.url
    Promise.all([
      chrome.tabs.getAsync tab.tab
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.document.documentElement.innerHTML'}
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.scrollY'}
      chrome.tabs.executeScriptAsync tab.tab, {code: 'window.innerHeight'}
    ]).spread (chromeTab, results, depth, height) ->
      html = results[0]
      page.favicon = chromeTab.favIconUrl
      page.depth = depth
      page.height = height
      page.title = chromeTab.title
      if tab.task
        db.transaction 'rw', db.Task, () ->
          db.Task.get(tab.task).then (task) ->
            task.nameTempTask(page)
      page.save().then (page) ->
        if html? and html.length > 10
          $.ajax(
            type: 'POST',
            url: 'http://104.131.7.171/lda',
            data: { 'data': JSON.stringify( {'html': html} ) }
          ).success( (results) ->
            Logger.debug 'lda'
            results = JSON.parse results
            vector = results['vector']
            page = _.extend(page,{vector: results['vector'], topics: results['topics'], topic_vector: results['topic_vector'], size: results['size']})
            page.save().catch (err) ->
              console.log(page)
              Logger.error err
          ).fail (a, t, e) ->
            Logger.debug "fail tokenize\n" + t

)()

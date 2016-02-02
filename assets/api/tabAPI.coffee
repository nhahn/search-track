#####
#
# Table for tab-based page tracking. Helps organizing searches and history
#
#####

class Tab extends Base
  constructor: (params) ->
    super {
      tab: undefined
      windowId: -1
      openerTab: -1
      position: 0
      pageVisit: '' #The pageVisit that is currently active
      status: 'active' # This is an enum: ['active', 'stored', 'closed', 'temp']
      branch: '' #The ID of the task this tab is associated with (TODO blank is newTab page i guess??)
      date: Date.now()
    }, params
    # Set an alarm to delete any temp tabs we don't want hanging around
    chrome.alarms.create('deleteTab'+tab, {delayInMinutes: 5}) if (@temp)
      
      
  save: () ->
    if (!@branch)
      branch = new Branch()
      branch.save().then (branch) =>
        @branch = branch.id
        return super()
    else
      super()
      
  #Replace this tab with a new tab (chrome instant blah)
  replace: (replacement) ->
    Branch.find(@branch).then (branch) =>
      prevTab = @tab
      @tab = replacement.tab
      @windowId = replacement.windowId
      @position = replacement.position
      @pageVisit = replacement.pageVisit
      branch.pageVisits.push(@pageVisit)
      console.debug("Replaced tab #{prevTab} with #{@tab}")
      return Dexie.Promise.all([this.save(), branch.save(), replacement.delete()])
    
  #Close this tab
  close: () ->
    if @pageVisit == ''
      return Dexie.Promise.all([this.delete(), db.Branch.delete(@branch)]).then (args) =>
        [tab, branch] = args
        return tab
    else
      @status = 'closed'
      return this.save()
  
  #Make this tab a fork of an existing tab
  forkTab: (existingTab) ->
    Branch.find(@branch).then (branch) =>
      branch.parent = existingTab.branch
      @openerTab = existingTab.id
      console.debug("Forked #{@tab} from #{@openerTab}")
      Dexie.Promise.all([this.save(), branch.save()]).then (args) =>
        [tab, branch] = args
        return tab
  
  #Figure out if we need a new branch / what branch a change in a tab should update
  determineBranch: (details, page) ->
    
    db.transaction 'rw', db.Branch, db.Tab, db.PageVisit, () =>
    #If we did a forward / back transition, find the correct page visit
    if details.transitionQualifiers.indexOf("forward_back") > -1
      return Branch.find(@branch).then (branch) =>
        saveBranch = branch #branch to save the tab on
        branchLocation = branch.pageVisits.indexOf(@pageVisit)
        previous = Dexie.Promise.resolve(null)
        if (branchLocation - 1 >= 0)
          previous = PageVisit.find(branch.pageVisits[branchLocation - 1]) 
        else if branch.parent
          previous = Branch.find(branch.parent).then (previousBranch) ->
            saveBranch = previousBranch #change the branch to the older branch
            return PageVisit.find(_.last(previousBranch.pageVisits))
        
        previous.then (visit) =>
          if (visit and page.id == visit.page) #Ok, we definitely went backwards
            @pageVisit = visit.id
            @branch = saveBranch.id
            visit.date = new Date()
            console.debug("Tab #{@tab} back transition to #{page.url}")
            return Dexie.Promise.all([this.save(), visit.save()])
          else #We went forward
            if (branchLocation + 1 < branch.pageVisits.length) #search the next immediate item in the visits list if available
              return PageVisit.find(branch.pageVisits[branchLocation+1]).then (visit) =>
                if (page.id == visit.page)
                  @pageVisit = visit.id
                  visit.date = new Date()
                  console.debug("Tab #{@tab} forward transition to #{page.url}")
                  return Dexie.Promise.all([this.save(), visit.save()])
            else #otherwise, check all of the other branches that list this current branch as a parent
              return Branch.getChildren().then (branches) =>
                Dexie.Promise.all branches.map (branch) =>
                  return PageVisit.find(branch.pageVisits[0])
                .then (visits) =>
                  visits.forEach (visit, idx) =>
                    if (page.id == visit.page)
                      @branch = branches[idx].id
                      @pageVisit = visit.id
                      visit.date = new Date()
                      console.debug("Tab #{@tab} forward transition to #{page.url}")
                      return Dexie.Promise.all([this.save(), visit.save()])
        #If we get here we couldn't find anything. TODO?
    switch details.transitionType
      when "link" or "form_submit" # If this is a link -- record the reference and keep the same task
        Branch.find(@branch).then (branch) =>
          visit = new PageVisit({page: page.id, type: "link"})
          return Dexie.Promise.all([branch, visit.save()])
        .then (args) =>
          [branch, visit] = args
          #If we are on the last visit of the branch, continue building it out
          if branch.pageVisits.length == 0 or @pageVisit == _.last(branch.pageVisits)
            branch.pageVisits.push(visit.id)
            @pageVisit = visit.id
            console.debug("Tab #{@tab} link transition to #{page.url}")
            return Dexie.Promise.all([this.save(), branch.save()])
          else #We are at some other point in the branch's history. New branch time!
            return branch.split(@pageVisit).then (newBranch) =>
              newBranch.pageVisits.push(visit.id)
              @pageVisit = visit.id
              console.debug("Tab #{@tab} link transition with split to #{page.url}")
              Dexie.Promise.all([newBranch.save(), this.save()])
              
      when "typed" # If this was typed, generate a new base branch
        visit = new PageVisit({page: page.id, type: 'typed'})
        branch = new Branch()
        Dexie.Promise.all([visit.save(), branch.save()]).then (args) =>
          [visit, branch] = args
          @branch = branch.id
          @pageVisit = visit.id
          console.debug("Tab #{@tab} manual typed transition to #{page.url}")
          this.save()
      when "auto_bookmark" 
        visit = new PageVisit({page: page.id, type: 'bookmarked'})
        branch = new Branch()
        Dexie.Promise.all([visit.save(), branch.save()]).then (args) =>
          [visit, branch] = args
          @branch = branch.id
          @pageVisit = visit.id
          console.debug("Tab #{@tab} manual bookmark transition to #{page.url}")
          this.save()
      when "reload" #We really don't want to record this in this instance -- find the last page visit and record it
        throw new Promise.CancellationError('Detected reload page -- ignoring')
        #TODO manage reload here
      when "start_page" #Don't record this.....
        throw new Promise.CancellationError('Detected start page -- ignoring')
      when "generated" # in this case the user is probably typing in what they want? Close to a task
        visit = new PageVisit({page: page.id, type: 'generated'})
        branch = new Branch()
        Dexie.Promise.all([visit.save(), branch.save()]).then (args) =>
          [visit, branch] = args
          @branch = branch.id
          @pageVisit = visit.id
          console.debug("Tab #{@tab} manual generated transition to #{page.url}")
          this.save()
      else
        throw new Promise.CancellationError("Unknown navigation #{details.transitionType}")
      
  @findByTabId: (tabId) ->
    db.Tab.where('tab').equals(tabId).and((val) -> val.status == 'active' or val.status == 'temp').first()

  @createTemp: (details) ->
    console.debug("Generateing temp tab #{details.tabId}")
    (new Tab({tab: details.tabId, windowId: -1, status: 'temp'})).save()
    
  
####
# Remove any still temporary tabs after 5 minutes have passed
####
chrome.alarms.onAlarm.addListener (alarm) ->
  match = alarm.name.match(/deleteTab(\d+)/)
  if (match)
    db.transaction 'rw', db.Tab, () ->
      db.Tab.where('tab').equals(match[1]).and((val) -> val.status is 'temp').first().then (tab) ->
        tab.delete() if tab
    
#TODO probably want an onidle background process that monitors for
#temp tabs still around?
    

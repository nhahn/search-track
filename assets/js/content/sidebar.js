/*
TODO: operations on buckets: name each, merge, save somewhere else, hide - use context menus!
TODO: better annotations - display on tab instead of hover
TODO: auto-size buckets - "groups"
TODO: add search, base off of AngularUI - search multiple pages!!
TODO: task database! a better way to manage tasks. sidebar is like WM for one task
TODO: minimize manipulation!
TODO: how does the Great Suspender work? it changes tab color!
BUG: throttling occasionally messes with db saving. Not everything seems to be on the same page. 
Figure out best throttle interval.
BUG: Uncaught TypeError: Cannot read property 'clientWidth' of null
BUG: doesn't work on first injection after extension loads, for many different errors (maybe due to race conditions)
*/

var listApp = angular.module('listApp', ['ngDraggable', 'ngDexieBind'], function($compileProvider) {
/* content security to display favicons, is this needed?
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(http?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(http?|ftp|mailto|file|chrome-extension):/);
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|chrome-extension):/);
*/
});

listApp.controller('RootCtrl', function ($scope, $dexieBind) {
  $scope.minimized = true;
  $scope.bottom = true;

  $scope.minimize = function () {
    if ($scope.minimized) {
      chrome.runtime.sendMessage({maximize: true})
      $('body').css('background-color', 'rgb(221,219,221)');
    } else {
      chrome.runtime.sendMessage({minimize: true})
      $('body').css('background-color', 'rgba(0,0,0,0)');
    }
    $scope.minimized = !$scope.minimized;
    $scope.$apply();
  };

  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    if (request.changeSize) 
      $scope.minimize();
    else if (request.bottom)
      $scope.bottom = true;
    else if (request.tOp)
      $scope.bottom = false;
  });

  $scope.blacklist = function() {
    chrome.runtime.sendMessage({blacklist:true}); 
    chrome.runtime.sendMessage({removeSidebar:true});  
  }
  
  $scope.remove = function() {
    chrome.runtime.sendMessage({removeSidebar:true}); 
  }

  $scope.changeLocation = function() {
    chrome.runtime.sendMessage({changeLocation: true});
    $scope.bottom = !$scope.bottom;
  }

  $dexieBind.bind(db, db.Task.filter(function(val){ return !val.hidden }), $scope).then(function(data) {
    $scope.tasks = data;
    $scope.$broadcast('tasksloaded');
  });


  // For the border
  $scope.onBorderDropComplete = function(index, obj, evt){
    var otherObj = $scope.tasks[index];
    var otherIndex = $scope.tasks.indexOf(obj);
    $scope.tasks[index] = obj;
    $scope.tasks[otherIndex] = otherObj;
  }

  $scope.remove = function() {
    console.log("Deleted " + this.task.name);
    // dexieBind doesn't delete it automatically?
    db.Task.where('name').equals(this.task.name).toArray(function(a) {
      console.log(a[0]);
      a[0].delete();
    });
    var index = $scope.tasks.indexOf(this.task);
    $scope.tasks.splice(index,1);
  }

  $scope.changeName = function() {
    var newName = this.task.name;
    // use dexieBind?
    db.Task.where('dateCreated').equals(this.task.dateCreated).toArray(function(a) {
      db.Task.update(a[0].id, {name: newName}).then(function (updated) {
        console.log (a[0].name + " renamed to " + newName);
      });
    });
  }

  // For Col1
  $scope.onGridDropComplete = function(index, obj, evt){
    var otherObj = $scope.pages[index];
    var otherIndex = $scope.pages.indexOf(obj);
    $scope.pages[index] = obj;
    $scope.pages[otherIndex] = otherObj;
  }
});

listApp.directive('myInput', ['$timeout', function ($timeout) {
  return {
    link: function (scope, element, attrs) {
      $timeout(function () { // be sure it's run after DOM render.
        element.click(function() {
          this.focus(); // only focuses, but not on correct place.
        });

        element.keypress(function(e) {
          if (e.which == 13) {
            $(this).submit();
            return false;
          } else if (e.which == 27) {
            this.editing = !this.editing;
          }
        });
      }, 0, false);
    }
  };
}]);

listApp.controller('MinimizedCtrl', function ($scope, $dexieBind) {

  chrome.runtime.sendMessage({getCurrentTab: true}, function(msg) {
    return $dexieBind.bind(db, db.Tab.where('tab').equals(msg[0].id).and(function(val) {
      return val.status === 'active';
    }), $scope).then(function(tab) {
      var watch;
      $scope.tab = tab;
      return $scope.tab.$join(db.Task, 'task', 'id');
    }).then(function(tasks) {
      $scope.curTask = tasks;
    });
  });
  
  $scope.changeTask = function () {
    chrome.runtime.sendMessage({toggleTasks:true});  
  }
});

listApp.controller('AnnotationCtrl', function ($scope, $dexieBind) {
  // TODO use dexieBind
  chrome.runtime.sendMessage({getCurrentTab: true}, function(msg) {
    Tab.findByTabId(msg[0].id).then(function (tab) {
      $scope.tab = tab;
      return Task.find(tab.task);
    }).then(function(task) {
      $scope.$apply(function() {
        $scope.task = task;
      });
    });
  });
});


listApp.controller('ColCtrl2', function ($scope) {
  $scope.pages = [
    {name: 'one'},
    {name: 'two'},
    {name: 'three'},
    {name: 'four'},
    {name: 'five'},
    {name: 'six'},
  ],
 
  $scope.onDropComplete = function(index, obj, evt){
    var otherObj = $scope.pages[index];
    var otherIndex = $scope.pages.indexOf(obj);
    $scope.pages[index] = obj;
    $scope.pages[otherIndex] = otherObj;
  }
});



/* OLD STUFF, may need later */
/*
		if (request.currentDb) { // Updates visual for the first time (fails if you call SavedDB directly sometimes)
      TABID = request.tabId;
      console.log(TABID);
      var db = request.currentDb;
      // var len = Math.min(8,tabs.length); // cap at 8 items
      for (var i = 1; i < db.tabs.length; i++) { // db.tabs[0] is the annotation
        var tab = db.tabs[i];
        newTab(tab);
      }
      $('#esoterictextbox').val(db.annotation);
    } else if (request.updated) { // database was updated - make relevant changes
      var db1 = request.updated[0];
      var db2 = request.updated[1];
      var annotation = request.updated[2];
			update(db1,1,annotation);
			update(db2,2,annotation);
		} else if (request.newLoc) { // user dragged a tab to a new location - update here
      console.log(request.newLoc);
      var info = document.getElementById(request.newLoc[0]);
      // Set offsets for display using the tab's index (tab.loc)
      var parentWidth = document.getElementById('esotericcolumn1').clientWidth;
      var parentHeight = 240;
      var x_buff = parentWidth*(.25/6);
      var x_offset = x_buff*2 + .25*parentWidth;
      var y_buff = parentHeight*(.25/6);
      var y_offset = y_buff*2 + .25*parentHeight;
      info.style.transform = 'translate(' + (x_buff + x_offset*((request.newLoc[1])%3)) + 'px, ' 
        + (y_buff + y_offset*(Math.floor((request.newLoc[1])/3))) + 'px)';
      info.style.webkitTransform = 'translate(' + (x_buff + x_offset*((request.newLoc[1])%3)) + 'px, ' 
        + (y_buff + y_offset*(Math.floor((request.newLoc[1])/3))) + 'px)';
      info.setAttribute('data-x',x_buff + x_offset*((request.newLoc[1])%3)); 
      info.setAttribute('data-y',y_buff + y_offset*(Math.floor((request.newLoc[1])/3)));
    } else if (request.delTab) { // user deleted a tab on some page - update here
      if (request.delTab.tabId == TABID) 
        $('.esotericbordername').css('background','rgba(222,219,221,.85)');
      $('#' + request.delTab.id).remove();
    } if (request.newNote) { // user updated a tab's note on some page - update here
      $('#' + request.newNote[0]).title = request.newNote[1];
    } else if (request.newColor) { // user updated a tab's color on some page - update here
      console.log(request.newColor);
      $('#' + request.newColor[0]).css('backgroundColor',request.newColor[1]);
    } else if (request.newTab) { // new tab was inserted to db
      newTab(request.newTab);
    } else if (request.newAnnotation) { // user updated the annotation box - update here
      $('#esoterictextbox').val(request.newAnnotation);
    }
});
*/

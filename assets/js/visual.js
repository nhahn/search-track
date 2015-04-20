/*
  For new tab page (visual.html)
*/

'use strict';

console.log("opened a new new tab page");

var listApp = angular.module('listApp', ['ui.tree'], function($compileProvider) {
    // content security for favicons
    $compileProvider.imgSrcSanitizationWhitelist(/^\s*(http?|ftp|file|chrome-extension):|data:image\//);
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(http?|ftp|mailto|file|chrome-extension):/);
    $compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|chrome-extension):|data:image\//);
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|chrome-extension):/);
}); 

var task = "default";
var nothing1 = [{title:"Nothing here yet.",importance:1,items:[]}];
var nothing2 = [{title:"Nothing here yet.",importance:2,items:[]}];
var nothing3 = [{title:"Nothing here yet.",importance:3,items:[]}];
var tabs = [];

listApp.controller('MainCtrl', ['$scope', 'listApp', function ($scope, listApp, $filter) {
  $scope.editing = false;
  // listApp.refreshTaskVisual();

  shortcut.add("Right", function() {
    window.open("/html/visual2.html","_self");   
  });

  chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
      if (request.task) {  
        task = request.task;
        console.log('got task ' + "\"" + task + "\" from background page"); 

        $scope.tree1 = nothing1;
        $scope.tree2 = nothing2;
        $scope.tree3 = nothing3;
        $scope.$digest();
        
        // this doesn't really make sense, but I can't think of another way to prevent
        // it from displaying before tabs is bound.
        SavedInfo.db().order("position").callback(function() {
          tabs = SavedInfo.db().filter({importance:1}).order("position").get();
          console.log(tabs); // ANNOYING bug: timeElapsed field randomly doesn't show up here.....

          // Bug: /very/ slow because of the callbacks...
          
          // Display tabs 
          for(var i = 0; i < tabs.length; i++) {
            // Read the tab items backwards (most recent first).
            var tab = tabs[tabs.length - i - 1];

            // if (tab.task == task) {
              var title = tab.title;
              if (title == undefined || title.length == 0) title = "Untitled";
              else if (title.length > 65) title = title.substring(0,64) + "... ";
              var obj = {};
              obj.title = title;
              obj.task = tab.task;
              obj.time = tab.time;
              obj.items = [];
              obj.ref = tab.ref;
              obj.depth = tab.depth;
              obj.height = tab.height;
              obj.url = tab.url;
              obj.timeElapsed = tab.timeElapsed;

              var getLocation = function(href) {
                  var l = document.createElement("a");
                  l.href = href;
                  return l;
              };
              var l = getLocation(tab.url);
              obj.favicon = 'http://' + l.hostname + '/favicon.ico';

              if (tab.importance == 1) {
                if ($scope.tree1 === nothing1) $scope.tree1 = [];
                obj.importance = 1;
                $scope.tree1.push(obj);
              } else if (tab.importance == 2) {
                if ($scope.tree2 === nothing2) $scope.tree2 = [];
                obj.importance = 2;
                $scope.tree2.push(obj);
              } else {
                if ($scope.tree3 === nothing3) $scope.tree3 = [];
                obj.importance = 3;
                $scope.tree3.push(obj);  
              } 
              $scope.$digest();
            }
            updateExport();
        });
      } else if (request.newTask) {   //from popup.js
        task = request.task;
        newView();
        // listApp.refreshTaskVisual();
      } else if (request.currentTask) { //newVisual from me

      }
    });

  $scope.emptyPlaceholderEnabled = (angular.isUndefined($scope.emptyPlaceholderEnabled)) 
    ? true : $scope.emptyPlaceholderEnabled;
    
  $scope.selectedItem = {};

  $scope.options = {
    dropped: function(event) {
      var start = event.source.index;
      var end = event.dest.index;
      var dest = event.dest.nodesScope.$modelValue;
      var sourceList = event.source.nodesScope.$modelValue;
      if (dest.length != sourceList.length && (dest[start] != sourceList[start])) {
          console.log(dest[end].title);
          console.log(event.source.nodeScope.$modelValue.title);
          if (event.dest.index == 0) importance = dest[1].importance;
          else importance = dest[0].importance;
          pageDB.changeImportance(event.source.nodeScope.$modelValue.id, importance, 
            function() {});
      }     
      // Update pageDB order
      if (Math.abs(start-end) == 1) {
        pageDB.swapId(dest[end].id,dest[start].id, function() {});
      } else if (start < end) {
        for (var i = end; i > start; i--) {
            pageDB.swapId(dest[i].id,dest[start].id, function() {});
        }
      } else {
        for (var i = end; i < start; i++) {
            pageDB.swapId(dest[i].id,dest[end].id, function() {});
        }
      }
    }
  };

  // Bug: seems to be removing everything except one
  $scope.rm = function(scope) {
    var nodeData = scope.$modelValue;
    var time = scope.$modelValue.time;
    SavedInfo.db().filter({'time':time}).remove();  // using callback is undefined
    if (nodeData.title != "Nothing here yet.") {
      scope.remove();
      console.log('deleted ' + nodeData.title + ' (' + time + ')');
      newView();
    }
  };

  $scope.save = function(scope) {
    pageDB.changeTitle(scope.$modelValue.id, scope.$modelValue.name, 
      function() {});
    scope.editing = false;
    scope.$modelValue.title = scope.$modelValue.name;
  };

  $scope.cancelEditing = function(scope) {
    scope.editing = false;
  }

  $scope.edit = function(scope) {
    scope.editing = true;
  };

  $scope.toggle = function(scope) {
    scope.toggle();
  };

  $scope.open = function(scope) {
    console.log(scope.$modelValue.depth);
    // trying to get it to scroll to where you last were, but csp prohibits this.
    chrome.tabs.query({'currentWindow': true, 'active': true}, 
      function(tabs) {
        activeId = tabs[0].id;
        chrome.runtime.sendMessage({"scrollDown": scope.$modelValue.depth, "id": activeId},
          function(response) {
          });
      }); 
    window.open(scope.$modelValue.url, "_self"); 
  };

  $scope.visible = function(item, scope) {
    if ($scope.query && $scope.query.length > 0
      && (item.title.toUpperCase()).indexOf($scope.query.toUpperCase()) == -1) {
      return false;
    }
    return true;
  };

  $scope.findNodes = function(){
  };

}]);


listApp.factory('listApp', function() {
  var _list = [];

  return {

  // refreshTaskVisual: function refreshTaskVisual() {
  //   taskDB.fetchTasks(function(tasks) {

  //     var taskList = document.getElementById('tasklist');
  //     taskList.innerHTML = '';

  //     // Sort tasks by counts (max to min) using an anonymous function!
  //     tasks.sort(function(a,b) {
  //       return b.count-a.count;
  //     });

  //     var firstTask = ""; var secondTask = ""; var thirdTask = "";
  //     var fourthTask = ""; var fifthTask = ""; var sixthTask = "";
  //     var seventhTask = ""; var eighthTask = ""; var ninthTask = "";

  //     if (tasks.length >= 1) firstTask = tasks[0].task;
  //     if (tasks.length >= 2) secondTask = tasks[1].task;
  //     if (tasks.length >= 3) thirdTask = tasks[2].task;
  //     if (tasks.length >= 4) fourthTask = tasks[3].task;
  //     if (tasks.length >= 5) fifthTask = tasks[4].task;
  //     if (tasks.length >= 6) sixthTask = tasks[5].task;
  //     if (tasks.length >= 7) seventhTask = tasks[6].task;
  //     if (tasks.length >= 8) eighthTask = tasks[7].task;
  //     if (tasks.length >= 9) ninthTask = tasks[8].task;

  //     for(var i = 0; i < tasks.length; i++) {
  //       var tsk = tasks[i];

  //       var a = document.createElement('a');
  //       a.className = "list-group-item";

  //       var info = document.createElement('a');
  //       var title = tsk.task;
  //       info.id = title; //should be unique.
  //       if(title.length > 15) {
  //           title = title.substring(0,14) + "... ";
  //       }
  //       info.innerHTML = (i+1).toString() + ". " + title;
  //       info.setAttribute('data-id',tsk.timestamp)
  //       info.target = "_blank";
        
  //       //add onclick to change current task to the clicked task
  //       info.addEventListener('click', function(e) {
  //         var id = parseInt(e.target.getAttribute('data-id'));

  //         //increment counter for this task
  //         taskDB.incrementCount(id, function() {
  //           chrome.runtime.sendMessage(
  //             {newTask: true, task: e.target.getAttribute('id')},
  //             function() {});
  //           chrome.runtime.sendMessage({newVisual: true}, function(response) {
  //             console.log(response.farewell);
  //           });
  //         });
  //       });

  //       a.appendChild(info);

  //       var space = document.createElement('span')
  //       space.innerHTML = '&nbsp;&nbsp;'

  //       a.appendChild(space);

  //       var x = document.createElement('button');
  //       x.setAttribute("class", 'close');
  //       x.innerHTML = 'x';
  //       x.setAttribute("data-id", tsk.timestamp);

  //       a.appendChild(x);

  //       taskList.appendChild(a);

  //       x.addEventListener('click', function(e) {
  //         var id = parseInt(e.target.getAttribute('data-id'));
  //         taskDB.deleteTask(id, refreshTaskVisual);
  //       });
  //     }
  //   });
  // },

  linkList: function(list) {_list = list; }

  }
});


function updateExport() {
  // Add option to save the database
  var allTabs = SavedInfo.db().stringify();
  // taken from 
  // http://stackoverflow.com/questions/20104552/javascript-export-
  // in-json-and-download-it-as-text-file-by-clicking-a-button
  var save = document.getElementById("export");
  save.download = "JSONexport.txt";
  save.href = "data:text/plain;base64," + btoa(unescape(encodeURIComponent(allTabs)));
  save.innerHTML = "Export your data here.";
} 

function newView() {
  chrome.runtime.sendMessage({newVisual: true}, function(response) {
    console.log('new view');
    console.log(response.farewell);
  });

  document.getElementById('currentTask').innerHTML = "My current task: " + task;
}
newView();
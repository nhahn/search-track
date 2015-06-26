// TODO: reload button
// TODO: change button colors on hover
// TODO: operations on buckets: name each, merge, save somewhere else, hide - use context menus! 
// TODO: better annotations - display on tab instead of hover
// TODO: can do stuff with only checked tabs
// TODO: auto-size buckets - "groups"
// TODO: add search, base off of AngularUI - search multiple pages!!
// TODO: task database! a better way to manage tasks. sidebar is like WM for one task
// TODO: minimize manipulation!
// TODO: perhaps use an iframe instead? look at vimium bar. or could even use devtools panel!
// TODO: use keyword extraction service, mechanism to extract /meaning/
// TODO: mouse over to see whole title
// TODO: can do things with dragging with shift key!
// TODO: add options page
// TODO: topsites?
// TODO: how does the Great Suspender work? it changes tab color!
// TODO: make it useable, speed up. I disabled the time elapsed function since it seems to be the laggiest
// It gets exponentially slower because of chrome.storage!!
// BUG: throttling occasionally messes with db saving. Not everything seems to be on the same page. 
// Figure out best throttle interval.
// BUG: Uncaught TypeError: Cannot read property 'clientWidth' of null
// BUG: doesn't work on first injection after extension loads, for many different errors (maybe due to race conditions)
// CWO: integrate wtih search-track. inject sidebar when you open a link in a new tab (not an update)


var listApp = angular.module('listApp', ['ui.tree'], function($compileProvider) {
// content security to display favicons
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(http?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(http?|ftp|mailto|file|chrome-extension):/);
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|chrome-extension):/);
});

console.log($('#column1'));
console.log(document.getElementById('column1'));



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

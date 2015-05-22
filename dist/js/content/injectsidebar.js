/*
 * This script is injected into every page the user opens. It injects the sidebar that users can
 * interact with.
 */

// Note: I'd rather use db.settings and onUpdate/onRemove instead of message passing to make it more synchronized, but
// doesn't work.
// TODO: task database! a better way to manage tasks
// TODO: reload button? button to switch view
// TODO: be able to add the other tabs in the window, not just the one you're currently on - shortcuts
// TODO: make it useable, speed up. I disabled the time elapsed function since it seems to be the laggiest
// TODO: perhaps use an iframe instead? look at vimium bar
// TODO: name each bucket
// TODO: delete bucket
// TODO: only allow one item per small box
// TODO: minimize manipulation!
// TODO: can do things with dragging with shift key!
// TODO: enable search-track, integrate with it
// TODO: mouse over to see whole title
// TODO: find first open spot to place tab
// TODO: add a link while opening in new tab
// BUG: throttling occasionally messes with db saving. Not everything seems to be on the same page.
/* "chrome.storage is not a big truck. It's a series of tubes. And if you don't understand,
 * those tubes can be filled, and if they are filled when you put your message in, it gets in line, 
 * and it's going to be delayed by anyone that puts into that tube enormous amounts of material."
 */
// BUG: doesn't work if tab was closed in different window
// BUG: Uncaught TypeError: Cannot read property 'clientWidth' of null
// BUG: doesn't work on first injection after extension loads, for many different errors (probably due to race conditions)
// CWO: bug testing. actually use it, then push first stable build

var listApp = angular.module('listApp', ['ui.tree'], function($compileProvider) {
// content security to display favicons
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(http?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(http?|ftp|mailto|file|chrome-extension):/);
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|chrome-extension):/);
});

chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {
		if (request.currentDb) { // Updates visual for the first time (fails from SavedDB sometimes)
      var db = request.currentDb;
      update(db[0],1,db[2]);
      update(db[1],2,db[2]);
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
      $('#' + request.delTab).remove();
    } else if (request.newNote) { // user updated a tab's note on some page - update here
      $('#' + request.newNote[0]).title = request.newNote[1];
    } else if (request.newColor) { // user updated a tab's color on some page - update here
      console.log(request.newColor);
      $('#' + request.newColor[0]).css('backgroundColor',request.newColor[1]);
    }

});

// Inject HTML for sidebar if it hasn't been injected already
if (typeof injected === 'undefined') {
$.get(chrome.extension.getURL('/html/sidebar.html'), function(data) {
	injected = true;
  var $app = $($.parseHTML(data)).appendTo('body');

	$app.ready(function(){
    var parentWidth = document.getElementById('esotericcolumn1').clientWidth;
    var parentHeight = 240;

    interact('.draggable')
    .draggable({
      snap: {
        targets: [
          interact.createSnapGrid({
            x: parentWidth/3,
            y: parentHeight/3,
            onEnd: true
          })
        ]
      },
      inertia: false,
      restrict: {
        restriction: "parent"
      },

      // call this function on every dragmove event
      onmove: dragMoveListener,	
      // call this function on every dragend event
      onend: function (event) {}	
    })
    .on('tap', function (event) {
      var id = parseInt(event.currentTarget.id);
      var obj = SavedInfo.db().filter({'time':id});
      if (obj.get()[0].color == 'rgba(219,217,219,1)') {
        event.currentTarget.style.backgroundColor = 'red';
            console.log('changed 1');
        obj.update({'color':'red'});
        chrome.runtime.sendMessage({changedColor:[id,'red']});
      } else {
        event.currentTarget.style.backgroundColor = 'rgba(219,217,219,1)';
            console.log('changed 1');
        obj.update({'color':'rgba(219,217,219,1)'});
        chrome.runtime.sendMessage({changedColor:[id,'rgba(219,217,219,1)']});
      }
      event.preventDefault();
    })
    .on('doubletap', function (event) {
      // TODO: do this without alert, support flow
      var id = event.currentTarget.id;
      var obj = SavedInfo.db().filter({'time':parseInt(id)});
      var old_note = obj.get()[0].note;
      var new_note = prompt("Annotate this tab",old_note);
      if (new_note != null) obj.update({'note':new_note});
      event.currentTarget.title = new_note;
      chrome.runtime.sendMessage({changedNote:[id,new_note]}, function(response) {
        console.log(response.farewell)
      });
      event.preventDefault();
    });

    interact('.esotericinnercol').dropzone({
      // only accept elements matching this CSS selector
      accept: '.draggable',
      // Require a 75% element overlap for a drop to be possible
      overlap: 1,

      ondropactivate: function (event) {
        // add active dropzone feedback
        event.target.classList.add('drop-active');
      },
      /* BUG: one behind the drag, due to snapping
      ondragenter: function (event) {
        var draggableElement = event.relatedTarget,
        dropzoneElement = event.target;
      
        // feedback the possibility of a drop
        dropzoneElement.classList.add('drop-target');
        draggableElement.classList.add('can-drop');
      }, 
      ondragleave: function (event) {
        //remove the drop feedback style
        event.target.classList.remove('drop-target');
        event.relatedTarget.classList.remove('can-drop');
      },
      */
      ondrop: function (event) {
        // Save current location to the database
        var id = parseInt(event.relatedTarget.attributes.id.value);
        var loc = parseInt(event.target.attributes.colid.value);
        SavedInfo.db().filter({time:id}).update({loc:loc}).callback(function() {
          // Force db to update by updating something else after
          var text = $('#esoterictextbox').val();
          SavedInfo.db().update({'annotation': text});

          // db doesn't update fast enough, so tell all content scripts directly
          chrome.runtime.sendMessage({changedLoc: [id,loc]}, function() {
            console.log(response.farewell + ' ' + id + ' to ' + loc);
          });
        });
      },
      ondropdeactivate: function (event) {
        // remove active dropzone feedback
        event.target.classList.remove('drop-active');
        event.target.classList.remove('drop-target');
      }
    });
    
    // "Remove" button 
    $(".esotericbordername a").click(function() {
      $(".esotericsidebarname").remove()
    });

    // Click to open sidebar
		$(".esotericbordername").click(function(){
			if ($('.esotericsidebarname').css('bottom') <= '-260px') {
		 		$(".esotericsidebarname").animate({"bottom": "+=275px"});
		 	} else {
		 		$(".esotericsidebarname").animate({"bottom": "-=275px"});
		 	}
		});

    // Update database after user finishes typing
    var typingTimer;                
    var doneTypingInterval = 500; 
    // on keyup, start the countdown
    $('#esoterictextbox').keyup(function(){
      clearTimeout(typingTimer);
      typingTimer = setTimeout(doneTyping, doneTypingInterval);
    });
    // on keydown, clear the countdown 
    $('#esoterictextbox').keydown(function(){
      clearTimeout(typingTimer);
    });

    function doneTyping () {
      var text = $('#esoterictextbox').val();
      SavedInfo.db().update({'annotation': text}).callback(function() {
        // Force db to update by doing it twice
        SavedInfo.db().update({'annotation': text})
        console.log(SavedInfo.db().get()[0]);
        chrome.runtime.sendMessage({changed: text}, function(response) {
          console.log(response.farewell + ' annotation');
        });
      });
    }

	});
});
}

function dragMoveListener (event) {
	var target = event.target,
	  // keep the dragged position in the data-x/data-y attributes
	  x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx,
  	y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;

	// translate the element
	target.style.webkitTransform =
  target.style.transform =
    'translate(' + x + 'px, ' + y + 'px)';

	// update the posiion attributes
	target.setAttribute('data-x', x);
	target.setAttribute('data-y', y);
}

function update(tabs,imp,annotation) {
  // var len = Math.min(8,tabs.length); // cap at 8 items
  for (var i = 0; i < tabs.length; i++) {
    var tab = tabs[i];
    if (document.getElementById(tab.time) == null) {
      var box = document.getElementById('esotericcolumn' + imp.toString());
      var info = document.createElement('div');
      info.setAttribute('class','draggable');
      info.setAttribute('title',tab.note);
      info.setAttribute('id',tab.time);
      if (tab.color == "red") info.style.backgroundColor = 'red';

      var favicon = document.createElement('img');
      favicon.setAttribute('src',tab.favicon);
      favicon.setAttribute('id','esotericfavicon');
      info.appendChild(favicon);

      var title = tab.title;
      if (title == undefined || title.length == 0) title = "Untitled";
      else if (title.length > 25) title = ' ' + title.substring(0,24) + "... ";
      var ttl = document.createElement('a');
      ttl.innerHTML = title;
      ttl.setAttribute('id','ttl_' + tab.time);
      ttl.tabId = tab.tabId;
      ttl.url = tab.url;
      info.appendChild(ttl);

      var del = document.createElement('a');
      del.setAttribute('class','pull-right btn btn-danger btn-xs esotericdelete');
      del.setAttribute('id','del_' + tab.time); 
      info.appendChild(del);

      // Set offsets for display using the tab's index (tab.loc)
      var parentWidth = document.getElementById('esotericcolumn1').clientWidth;
      var parentHeight = 240;
      var x_buff = parentWidth*(.25/6);
      var x_offset = x_buff*2 + .25*parentWidth;
      var y_buff = parentHeight*(.25/6);
      var y_offset = y_buff*2 + .25*parentHeight;
      info.style.transform = 'translate(' + (x_buff + x_offset*(tab.loc%3)) + 'px, ' + (y_buff + y_offset*(Math.floor(tab.loc/3))) + 'px)';
      info.style.webkitTransform = 'translate(' + (x_buff + x_offset*(tab.loc%3)) + 'px, ' + (y_buff + y_offset*(Math.floor(tab.loc/3))) + 'px)';
      info.setAttribute('data-x',x_buff + x_offset*(tab.loc%3)); 
      info.setAttribute('data-y',y_buff + y_offset*(Math.floor(tab.loc/3)));

      box.appendChild(info);

      $(document).ready(function() {
        // Could just use id from above, given that these listeners are only for this tab
        // $(".draggable").hoverIntent(function() {alert(this)});

        $('#del_' + tab.time).click(function() {
          var time = parseInt($(this)[0].parentElement.id);
          // var title = $(this).context.parentElement.innerText;
          SavedInfo.db().filter({'time':time}).remove(); // may take some time...
          // Force db to update by updating something else after?
          var text = $('#esoterictextbox').val();
          SavedInfo.db().update({'annotation': text});
          $(this)[0].parentElement.remove();
          
          chrome.runtime.sendMessage({deleted: time}, function() {
            console.log(response.farewell + ' ' + time);
          });
        });

        $('#ttl_' + tab.time).click(function() {
          var id = parseInt($(this)[0].parentElement.id);
          // undo color change from the tap
          if ($(this)[0].parentElement.style.backgroundColor == 'red') {
            var obj = SavedInfo.db().filter({'time':id});
            obj.update({'color':'rgba(219,217,219,1)'});
            chrome.runtime.sendMessage({changedColor:[id,'rgba(219,217,219,1)']});
            console.log('changed 2');
          } else {
            var obj = SavedInfo.db().filter({'time':id});
            obj.update({'color':'red'});
            chrome.runtime.sendMessage({changedColor:[id,'red']});
            console.log('changed 2');
          }

          chrome.runtime.sendMessage({'changeUrl':[$(this)[0].tabId,$(this)[0].url]}, function() {
            console.log('opened');
          }); 
        });
      });

    }
  }
  
  // Update annotation box
  $('#esoterictextbox').val(annotation);
}

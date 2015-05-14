// Bug: first load, obj is null
// TODO: switch to the tab on click - save tabid somewhere? and scroll down correctly!
// TODO: reload button?
// TODO: be able to add the other tabs in the window, not just the one you're currently on - shortcuts
// TODO: save current x and y transforms, etc
// TODO: minimize manipulation! snap instead of drag, increase flow (between sandboxes)
// TODO: make it useable, speed up
// TODO: insert sidebar faster into windows
// TODO: could merge content scripts (1-3) with this, use message passing
// TODO: perhaps use an iframe instead? look at vimium bar
// TODO: less calls to update - should be more discerning
// Currently working on: notepad in third bucket

var listApp = angular.module('listApp', ['ui.tree'], function($compileProvider) {
// content security to display favicons
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(http?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(http?|ftp|mailto|file|chrome-extension):/);
$compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|chrome-extension):|data:image\//);
$compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|chrome-extension):/);
});

chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {
		if (request.updated) {
			update();
		}
	});

// Inject HTML for sidebar if it hasn't been injected already
if (typeof injected === 'undefined') {
$.get(chrome.extension.getURL('/html/sidebar.html'), function(data) {
	injected = true;
  var $app = $($.parseHTML(data)).appendTo('body');

	interact('.draggable')
	.draggable({
		restrict: {
			restriction: "parent",
			endOnly: true,
			elementRect: { top: 0, left: 0, bottom: 1, right: 1 }
		},

	  // call this function on every dragmove event
		onmove: dragMoveListener,	
		// call this function on every dragend event
		onend: function (event) {
 	   var textEl = event.target.querySelector('p');

	    textEl && (textEl.textContent =
 	      'moved a distance of '
      	+ (Math.sqrt(event.dx * event.dx +
	 					         event.dy * event.dy)|0) + 'px');
		}	
	})
	.on('tap', function (event) {
		var id = event.currentTarget.id;
		var obj = SavedInfo.db().filter({'time':parseInt(id)});
		if (obj.get()[0].color == 'rgba(219,217,219,1)') {
    	event.currentTarget.style.backgroundColor = 'red';
			obj.update({'color':'red'});
		} else {
		  event.currentTarget.style.backgroundColor = 'rgba(219,217,219,1)';
			obj.update({'color':'rgba(219,217,219,1)'});
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
		event.preventDefault();
	});
	
	$app.ready(function(){
		$(".esotericbordername").click(function(){
			if ($('.esotericsidebarname').css('bottom') == '-260px') {
		 		$(".esotericsidebarname").animate({"bottom": "+=275px"});
		 	} else {
		 		$(".esotericsidebarname").animate({"bottom": "-=275px"});
		 	}
		});
   
    var annotation = SavedInfo.db().get()[0].annotation;
    $('#esoterictextbox').val(annotation);

    var notepad = document.getElementById('esoterictextbox');
    notepad.addEventListener('input', function() {
      var text = $('#esoterictextbox').val();
      SavedInfo.db().update({'annotation': text});
    });
		update();
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

function update() {
	// Display all saved tabs in the correct box. Not sure what the callback is for exactly.
	SavedInfo.db().callback(function() {
 		tabs = SavedInfo.db().get();
		for (var i = 1; i < tabs.length; i++) {
			var tab = tabs[i];
			if (document.getElementById(tab.time) == null) {
				var box = document.getElementById('esotericcolumn1');
				if (tab.importance == 2) box = document.getElementById('esotericcolumn2');
				else if (tab.importance == 3) box = document.getElementById('esotericcolumn3');
				var info = document.createElement('div');
				info.setAttribute('class','draggable');
        // If you change the note, it won't update
				info.setAttribute('title',tab.note);
				info.setAttribute('id',tab.time);
				if (tab.color == "red") info.style.backgroundColor = 'red';

	  		/* chrome.tabs does this better, but I'm using a content script to
	       * get this info.
				 */
	     	var getLocation = function(href) {
	        var l = document.createElement("a");
	        l.href = href;
	        return l;
	      }; 
				var l = getLocation(tab.url);
				var favLink = 'http://' + l.hostname + '/favicon.ico';
				var favicon = document.createElement('img');
				favicon.setAttribute('src',favLink);
				favicon.setAttribute('id','esotericfavicon');
	      info.appendChild(favicon);

				var title = tab.title;
	      if (title == undefined || title.length == 0) title = "Untitled";
	      else if (title.length > 25) title = ' ' + title.substring(0,24) + "... ";
				var ttl = document.createElement('a');
				ttl.innerHTML = title;
				ttl.setAttribute('href',tab.url);
				info.appendChild(ttl);

				var del = document.createElement('a');
				del.setAttribute('class','pull-right btn btn-danger btn-xs esotericdelete');
				info.appendChild(del);
			
				box.appendChild(info);
			}
		}
	
    // Adds a lot of the same listeners to each element, but I'm doing this so every new element
    // can be deleted  
    $(document).ready(function() {
      // $(".draggable").hoverIntent(function() {alert(this)});
  
      $('.esotericdelete').each(function() {
        $(this).click(function() {
    	    var time = parseInt($(this)[0].parentElement.id);
          // var title = $(this).context.parentElement.innerText;
          SavedInfo.db().filter({'time':time}).remove();
          $(this)[0].parentElement.remove();
        });
      });
    });
	});
}


// TODO: task database! a better way to manage tasks
// TODO: reload button?
// TODO: be able to add the other tabs in the window, not just the one you're currently on - shortcuts
// TODO: make it useable, speed up. I disabled the time elapsed function since it seems to be the laggiest
// TODO: insert sidebar faster into windows
// TODO: perhaps use an iframe instead? look at vimium bar
// TODO: name each bucket
// TODO: save current x and y transforms, etc
// TODO: only allow one item per small column
// TODO: option to hide sidebar
// TODO: need a better place to put annotation in db
// BUG: throttling messes with db saving.
// CWO: minimize manipulation! snap instead of drag, increase flow (between sandboxes)

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
			update(request.updated);
		}
});

// Inject HTML for sidebar if it hasn't been injected already
if (typeof injected === 'undefined') {
$.get(chrome.extension.getURL('/html/sidebar.html'), function(data) {
	injected = true;
  var $app = $($.parseHTML(data)).appendTo('body');

	interact('.draggable')
	.draggable({
    inertia: false,
		restrict: {
			restriction: "#ontop",
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
  /*
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
  */
  .on('doubletap', function (event) {
		// TODO: do this without alert, support flow
		var id = event.currentTarget.id;
		var obj = SavedInfo.db().filter({'time':parseInt(id)});
		var old_note = obj.get()[0].note;
 	  var new_note = prompt("Annotate this tab",old_note);
 	  if (new_note != null) obj.update({'note':new_note});
		event.preventDefault();
	});

  interact('.esotericinnercol').dropzone({
    // only accept elements matching this CSS selector
    accept: '.draggable',
    // Require a 55% element overlap for a drop to be possible
    overlap: 0.55,

    ondropactivate: function (event) {
      // add active dropzone feedback
      event.target.classList.add('drop-active');
    },
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
    ondrop: function (event) {},
    ondropdeactivate: function (event) {
      // remove active dropzone feedback
      event.target.classList.remove('drop-active');
      event.target.classList.remove('drop-target');
    }
  });
	
	$app.ready(function(){
		$(".esotericbordername").click(function(){
			if ($('.esotericsidebarname').css('bottom') <= '-260px') {
		 		$(".esotericsidebarname").animate({"bottom": "+=275px"});
		 	} else {
		 		$(".esotericsidebarname").animate({"bottom": "-=275px"});
		 	}
		});

    var notepad = document.getElementById('esoterictextbox');
    notepad.addEventListener('input', function() {
      var text = $('#esoterictextbox').val();
      SavedInfo.db().update({'annotation': text});
      var db = SavedInfo.db().get();
		  update(db);
    });

    var db = SavedInfo.db().get();
    update(db);
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

function update(tabs) {
  for (var i = 1; i < tabs.length; i++) { // limit to 9 for now?
    var tab = tabs[i];
    console.log(tab.title);
    console.log(i);
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

      /* old way of getting favicon url 
      var getLocation = function(href) {
        var l = document.createElement("a");
        l.href = href;
        return l;
      }; 
      var l = getLocation(tab.url);
      var favLink = 'http://' + l.hostname + '/favicon.ico';
      */
      var favicon = document.createElement('img');
      favicon.setAttribute('src',tab.favicon);
      favicon.setAttribute('id','esotericfavicon');
      info.appendChild(favicon);

      var title = tab.title;
      if (title == undefined || title.length == 0) title = "Untitled";
      else if (title.length > 25) title = ' ' + title.substring(0,24) + "... ";
      var ttl = document.createElement('a');
      ttl.innerHTML = title;
      ttl.setAttribute('class','esoterictitlehref');
      ttl.tabId = tab.tabId;
      ttl.id = tab.time;
      info.appendChild(ttl);

      var del = document.createElement('a');
      del.setAttribute('class','pull-right btn btn-danger btn-xs esotericdelete');
      info.appendChild(del);

      // Set offsets for display
      var parentWidth = document.getElementById('esotericcolumn1').clientWidth;
      var parentHeight = document.getElementById('esotericcolumn1').clientHeight;
      // Using percentages:
      /* info.style.transform = 'translate(' + (16.6666667 + 133.333333*(i%3)) + '%, ' + (16.6666667 + 133.333333*(Math.floor((i-1)/3))) + '%)';
      info.style.webkitTransform = 'translate(' + (16.6666667 + 133.333333*(i%3)) + '%, ' + (16.6666667 + 133.333333*(Math.floor((i-1)/3))) + '%)'; */
      var x_buff = parentWidth*(.25/6);
      var x_offset = x_buff*2 + .25*parentWidth;
      var y_buff = parentHeight*(.25/6);
      var y_offset = y_buff*2 + .25*parentHeight;
      info.style.transform = 'translate(' + (x_buff + x_offset*((i-1)%3)) + 'px, ' + (y_buff + y_offset*(Math.floor((i-1)/3))) + 'px)';
      info.style.webkitTransform = 'translate(' + (x_buff + x_offset*((i-1)%3)) + 'px, ' + (y_buff + y_offset*(Math.floor((i-1)/3))) + 'px)';
      info.setAttribute('data-x',x_buff + x_offset*(i%3)); 
      info.setAttribute('data-y',y_buff + y_offset*(Math.floor((i-1)/3)));

      box.appendChild(info);
    }
  }
  
  // Update annotation box 
  var annotation = tabs[0].annotation;
  $('#esoterictextbox').val(annotation);

  // Adds a lot of the same listeners to each element, but I'm doing this so every new element
  // can be deleted  
  $(document).ready(function() {
    // $(".draggable").hoverIntent(function() {alert(this)});

    $('.esotericdelete').each(function() {
      $(this).click(function() {
        var time = parseInt($(this)[0].parentElement.id);
        // var title = $(this).context.parentElement.innerText;
        SavedInfo.db().filter({'time':time}).remove(); // may take some time..
        $(this)[0].parentElement.remove(); 
      });
    });

    $('.esoterictitlehref').each(function() {
      $(this).click(function() {
        chrome.runtime.onMessage.addListener(
          function(request, sender, sendResponse) {
            if (request.notOpened) chrome.tabs.create({'url':$(this)[0].url});
        });

       chrome.runtime.sendMessage({'changeId':$(this)[0].tabId});
        
        // undo color change
        /*
        var id = $(this)[0].id;
        var obj = SavedInfo.db().filter({'time':parseInt(id)});
        if (obj.get()[0].color == 'rgba(219,217,219,1)') {
          obj.update({'color':'red'});
        } else {
          obj.update({'color':'rgba(219,217,219,1)'});
        }
        */
      });
    });
  });
}

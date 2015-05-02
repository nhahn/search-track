
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
    event.currentTarget.classList.toggle('switch-bg');
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

		// Display all saved tabs
		SavedInfo.db().order("position").callback(function() {
    	tabs = SavedInfo.db().order("position").get();
			for (var i = 0; i < tabs.length; i++) {
				var tab = tabs[i];
				console.log(tab);
				var box = document.getElementById('esotericcolumn1');
				if (tab.importance == 2) box = document.getElementById('esotericcolumn2');
				else if (tab.importance == 3) box = document.getElementById('esotericcolumn3');
				var info = document.createElement('div');
				info.setAttribute('class','draggable');
				var title = tab.title;
        if (title == undefined || title.length == 0) title = "Untitled";
        else if (title.length > 30) title = title.substring(0,29) + "... ";
				info.innerHTML = title;
				box.appendChild(info);
			}
		});

	});

});
}

 // $("div.container").hoverIntent(config);

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



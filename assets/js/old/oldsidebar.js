/* Some old sidebar code that may be useful later on - uses interact.js */

$app.ready(function(){
    console.log(parent);
    if (parent === top) {
      console.log(document);
      console.log($('#injectedsidebar'));
      console.log($('#injectedsidebar').contents().find('.massdelete'));

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
          event.currentTarget.style.backgroundColor = '#FF7878';
              console.log('changed 1 - red');
          obj.update({'color':'#FF7878'});
          chrome.runtime.sendMessage({changedColor:[id,'#FF7878']});
        } else {
          event.currentTarget.style.backgroundColor = 'rgba(219,217,219,1)';
              console.log('changed 1 - gray');
          obj.update({'color':'rgba(219,217,219,1)'});
          chrome.runtime.sendMessage({changedColor:[id,'rgba(219,217,219,1)']});
        }
        event.preventDefault();
      })
      .on('doubletap', function (event) {
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

      // Click to open sidebar
      $(".esotericbordername").click(function(){
        if ($('.esotericsidebarname').css('bottom') <= '-260px') {
          $(".esotericsidebarname").animate({"bottom": "+=275px"});
        } else {
          $(".esotericsidebarname").animate({"bottom": "-=275px"});
        }
      });

      /* 
      // "Reload" button
      $(".esotericreload").click(function() {
        console.log('afa');
      });
      */

      // "Remove" button 
      $(".esotericremove").click(function() {
        $(this).removeEventListener("click");
        $(".esotericsidebarname").remove()
      });

      // Mass delete a bucket
      $(".esotericmassdelete").click(function() {
        $(this).parent().children(".draggable").each(function() {
          var time = parseInt($(this)[0].id);
          var tabId = SavedInfo.db().filter({'time':time}).get()[0].tabId;
          SavedInfo.db().filter({'time':time}).remove(); // may take some time...
          // Force db to update by updating something else first?
          var text = $('#esoterictextbox').val();
          SavedInfo.db().update({'annotation': text});
          $(this)[0].remove();
          
          chrome.runtime.sendMessage({deleted: {'id':time,'tabId':tabId}}, function() {
            console.log(response.farewell + ' ' + time);
          });
        });
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
          chrome.runtime.sendMessage({changedAnnotation: text}, function(response) {
            console.log(response.farewell + ' annotation');
          });
        });
      }
    }
  });

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

function newTab(tab) {
  if (document.getElementById(tab.time) == null) {
    console.log(tab.url);
    console.log(window.location.href);
    if (tab.url == window.location.href || tab.tabId == TABID) // use tab.url.match and regex
      $('.esotericbordername').css('background','rgba(248,193,47,.85)');

    imp = tab.importance;
    var box = document.getElementById('esotericcolumn' + imp.toString());
    var info = document.createElement('div');
    info.setAttribute('class','draggable');
    info.setAttribute('title',tab.note);
    info.setAttribute('id',tab.time);
    if (tab.color == "#FF7878") info.style.backgroundColor = '#FF7878';

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
        var tabId = SavedInfo.db().filter({'time':time}).get()[0].tabId;
        SavedInfo.db().filter({'time':time}).remove(); // may take some time...
        // Force db to update by updating something else first?
        var text = $('#esoterictextbox').val();
        SavedInfo.db().update({'annotation': text});
        $(this)[0].parentElement.remove();
        
        chrome.runtime.sendMessage({deleted: {'id':time,'tabId':tabId}}, function() {
          console.log(response.farewell + ' ' + time);
        });
      });

      $('#ttl_' + tab.time).click(function() {
        var id = parseInt($(this)[0].parentElement.id);

        // undo color change from the tap
        console.log($(this)[0].parentElement.style.backgroundColor); 
        if ($(this)[0].parentElement.style.backgroundColor == 'rgba(219,217,219,1)') {
          var obj = SavedInfo.db().filter({'time':id});
          obj.update({'color':'#FF7878'});
          chrome.runtime.sendMessage({changedColor:[id,'#FF7878']});
          console.log('changed 2 - red');
        } else {
          var obj = SavedInfo.db().filter({'time':id});
          obj.update({'color':'rgba(219,217,219,1)'});
          chrome.runtime.sendMessage({changedColor:[id,'rgba(219,217,219,1)']});
          console.log('changed 2 - gray');
        }

        chrome.runtime.sendMessage({'changeUrl':[$(this)[0].tabId,$(this)[0].url]}, function() {
          console.log('opened');
        }); 
      });
    });

  }
}


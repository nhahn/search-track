function getInfo() {
  var tab = {};
  tab.time = Date.now();
  tab.timeElapsed = 0;

  var ttl = document.title;
  if (ttl.length == 0) ttl = prompt("Please name this page","Untitled");
  tab.title = ttl;

  tab.url = document.URL;
  var highlighted = "";
  if (window.getSelection().toString().replace(/ /g,'') != '')
  		var highlighted = window.getSelection().toString();
  tab.selected = highlighted;
  	
  tab.importance = 1;

  tab.depth = window.scrollY;
  tab.height = window.innerHeight;
  console.log("My Depth: " + tab.depth);
  console.log("Total Depth: " + document.body.clientHeight);

  // for the drag-and-drop list (could be adapted for 2D manipulation)
  tab.position = SavedInfo.db().count();

  // will be able to "favorite" tabs
  tab.favorite = false;

  // is it a reference tab?
  tab.ref = false;

  //TODO: TASK DB, then get the right task. Where do I record the current task? I'll have to send a message?
  tab.task = "";

	// add to DB.
	SavedInfo.db.insert(tab);

  // inform visual that there's a new tab that's been added
	chrome.runtime.sendMessage({newTab: true}, function(response) {
	  console.log(response.farewell);
	});
}

getInfo();
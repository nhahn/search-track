/*
	Background page for the Forager part of the extension 
*/

// TODO: why is angular loading twice?
// TODO: task db!

task = "default";
console.log(task);

var currentTab;
var lastTab;

chrome.storage.local.clear();
chrome.storage.sync.clear();

// Message passing from content scripts and new tab page
chrome.runtime.onMessage.addListener(
   function(request, sender, sendResponse) {
    console.log(sender.tab ?
                "from a content script:" + sender.tab.url :
                "from the extension");
		if (request.newTask) {
			task = request.task;
		} else if (request.newVisual) {
			chrome.runtime.sendMessage({task: task}, function(response) {
				console.log('sent current task'); // doesn't work
        		console.log(response.farewell);
     		});
		} else if (request.newTab) { // from content.js, to visual.js
			// for some reason, have to route through the background page.
			chrome.runtime.sendMessage({task: task}, function(response) {
				console.log('sent current task');
        		console.log(response.farewell);
     		});
		} else if (request.updated) {
			chrome.tabs.query({active: true, currentWindow: true}, function(tabs){
	   	  chrome.tabs.sendMessage(tabs[0].id, {updated: true}, function(response) {});  
			});
		}	
	/*	
		else if (request.scrollDown != 0) {
			setTimeout(function() {
				chrome.tabs.executeScript(
					null, {file: '/js/scroll.js', runAt: "document_start"}, function() {});
				chrome.runtime.sendMessage({down: request.scrollDown}, function() {});
			  }, 5000);
		}
		*/
   });

chrome.commands.onCommand.addListener(function(command) {
  // Call 'update' with an empty properties object to get access to the current
  // tab (given to us in the callback function).
  chrome.tabs.update({}, function(tab) {
   if (command == 'add-importance-1') add1();
   else if (command == 'add-importance-2') add2();
   else if (command == 'add-importance-3') add3();
	 else if (command == 'open') open();
  });
});

// user marks tab as "for later"
function add1() {
	// could use tabs.query instead, but doesn't provide info about position.
	// you would get a better faviconUrl though...
	chrome.tabs.executeScript(
		null, {file: '/vendor/taffydb/taffy-min.js', runAt: "document_start"}, function() {
		chrome.tabs.executeScript(
			null, {file: '/vendor/underscore/underscore-min.js', runAt: "document_start"}, function() {
			chrome.tabs.executeScript(
				null, {file: '/js/trackAPI.js', runAt: "document_start"}, function() {
				chrome.tabs.executeScript(
					null, {file: '/js/content/content.js', runAt: "document_start"}, function() {
					chrome.tabs.query({'currentWindow': true, 'active': true}, function(tabs) {
						activeId = tabs[0].id;
						// chrome.tabs.remove(activeId);
					});
				});
			}); 
		}); 
	}); 
}
function add2() {
	// could use tabs.query instead, but doesn't provide info about position.
	// you would get a better faviconUrl though...
	chrome.tabs.executeScript(
		null, {file: '/vendor/taffydb/taffy-min.js', runAt: "document_start"}, function() {
		chrome.tabs.executeScript(
			null, {file: '/vendor/underscore/underscore-min.js', runAt: "document_start"}, function() {
			chrome.tabs.executeScript(
				null, {file: '/js/trackAPI.js', runAt: "document_start"}, function() {
				chrome.tabs.executeScript(
					null, {file: '/js/content/content2.js', runAt: "document_start"}, function() {
					chrome.tabs.query({'currentWindow': true, 'active': true}, function(tabs) {
						activeId = tabs[0].id;
						// chrome.tabs.remove(activeId);
					});
				});
			}); 
		}); 
	}); 
}
function add3() {
	// could use tabs.query instead, but doesn't provide info about position.
	// you would get a better faviconUrl though...
	chrome.tabs.executeScript(
		null, {file: '/vendor/taffydb/taffy-min.js', runAt: "document_start"}, function() {
		chrome.tabs.executeScript(
			null, {file: '/vendor/underscore/underscore-min.js', runAt: "document_start"}, function() {
			chrome.tabs.executeScript(
				null, {file: '/js/trackAPI.js', runAt: "document_start"}, function() {
				chrome.tabs.executeScript(
					null, {file: '/js/content/content3.js', runAt: "document_start"}, function() {
					chrome.tabs.query({'currentWindow': true, 'active': true}, function(tabs) {
						activeId = tabs[0].id;
						// chrome.tabs.remove(activeId);
					});
				});
			}); 
		}); 
	}); 
}
function open() {
	console.log('triggered');
	// Opens or closes the sidebar in the current page.
	chrome.tabs.executeScript(null, {file: '/js/content/openclose.js', runAt: "document_start"});
}

// Max at 9 tabs
chrome.tabs.onCreated.addListener(function(tab) {
	chrome.tabs.query({currentWindow: true}, function(tabs) {
		if (tabs.length > 9) {
			alert("Too many tabs!");
			chrome.tabs.remove(tab.id, function() {});
		}
	});
});

// Inject sidebar to every updated page
chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
	var tab = tabs[0];
	chrome.tabs.insertCSS(null, {file: "/css/sidebar.css", runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/vendor/taffydb/taffy-min.js', runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/vendor/underscore/underscore-min.js', runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/js/trackAPI.js', runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/vendor/jquery/dist/jquery.min.js', runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/vendor/angular/angular.js', runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/js/content/hoverintent.js', runAt: "document_start"}, function() {
  chrome.tabs.executeScript(
	null, {file: '/js/angular-ui-tree-master/dist/angular-ui-tree.min.js', runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/vendor/bootstrap/dist/js/bootstrap.min.js', runAt: "document_start"}, function() {
	chrome.tabs.executeScript(
	null, {file: '/js/interact.min.js', runAt: "document_start"}, function() { 	// For some reason, won't work in vendor 
	chrome.tabs.executeScript(
	null, {file: '/js/content/injectsidebar.js', runAt: "document_start"});	
	});});});});});});});});});});
});

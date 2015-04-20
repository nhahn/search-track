/*
	Manages the Forager part of the extension (background page)
*/

task = "default";
console.log(task);

var currentTab;
var lastTab;

// SavedInfo.db().remove();

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
		} else if (request.scrollDown != 0) {
			setTimeout(function() {
				chrome.tabs.executeScript(
					null, {file: '/js/scroll.js', runAt: "document_start"}, function() {});
				chrome.runtime.sendMessage({down: request.scrollDown}, function() {});
			  }, 5000);
		}
   });


chrome.commands.onCommand.addListener(function(command) {
  // Call 'update' with an empty properties object to get access to the current
  // tab (given to us in the callback function).
  chrome.tabs.update({}, function(tab) {
   if (command == 'add-importance-1') add1();
   else if (command == 'add-importance-2') add2();
   else if (command == 'add-importance-3') add3();
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
						chrome.tabs.remove(activeId);
					});
				});
			}); 
		}); 
	}); 
}

function add2() {
	// chrome.tabs.query({'currentWindow': true, 'active': true}, 
	// 	function(tabs) {
	// 		activeId = tabs[0].id;
	// 		chrome.tabs.executeScript(
	// 			activeId, {file: '/js/background/trackAPI.js', runAt: "document_start"}, function() {
	// 				chrome.tabs.executeScript(
	// 					activeId, {file: '/js/content2.js', runAt: "document_start"}, function() {
	// 						chrome.tabs.remove(activeId);
	// 			});
	// 	}); 
}

function add3() {
	// chrome.tabs.query({'currentWindow': true, 'active': true}, 
	// 	function(tabs) {
	// 		activeId = tabs[0].id;
	// 		chrome.tabs.executeScript(
	// 			activeId, {file: '/js/content3.js', runAt: "document_start"}, function() {
	// 				chrome.tabs.remove(activeId);
	// 			});
	// 	}); 
}

// max at 9 tabs
chrome.tabs.onCreated.addListener(function(tab) {
	chrome.tabs.query({currentWindow: true}, function(tabs) {
		if (tabs.length > 9) {
			alert("Too many tabs!");
			chrome.tabs.remove(tab.id, function() {});
		}
	});
});

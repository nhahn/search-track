chrome.runtime.onMessage.addListener(
   function scroll(request, sender, sendResponse) {
   	alert(console.log(request.down));
		if (request.down) {	
   	chrome.runtime.onMessage.removeListener(scroll);
			window.scroll(0,request.down);
		}
   });

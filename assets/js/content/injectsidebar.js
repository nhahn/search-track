/*
 * This script is injected into every page the user opens. It injects an iframe (sidebar.html) that users can interact with.
 */

if (typeof injected === 'undefined') {
  // Inject HTML for sidebar if it hasn't been injected already
  var $app = $('<!-- INJECTED SIDEBAR --> <iframe id="injectedsidebar" style="position:fixed;z-index:2147483645;height:190px;bottom:0;width:100%;font-family:arial;padding:0;background-color:rgba(221,219,221,0.9);border:none;border-top:1px solid rgb(103,103,103);" sandbox="allow-same-origin allow-scripts allow-popups" src="' + chrome.extension.getURL('/html/sidebar.html') + '"></iframe> <!-- END SIDEBAR-->').appendTo('html');
	injected = true;

  // Listeners from forager.js
  chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
      if (request.open) {
        if ($('#injectedsidebar').css('bottom') == '0px') {
          $('#injectedsidebar').animate({"bottom": "-=170px"});
        } else {
          $('#injectedsidebar').animate({"bottom": "+=170px"}); 
        }
      }
  });
}


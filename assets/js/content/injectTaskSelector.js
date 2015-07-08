/*
 * This script is injected into every page the user opens. It injects an iframe (sidebar.html) that users can interact with.
 */

if (typeof injectedTaskSelector === 'undefined') {
  // Inject HTML for sidebar if it hasn't been injected already
  var $app = $('<!-- INJECTED SELECTOR --> <iframe id="injectedTaskSelector" sandbox="allow-same-origin allow-scripts allow-popups" src="' + chrome.extension.getURL('/html/taskSelector.html') + '"></iframe> <!-- END SELECTOR-->').appendTo('html');
	injectedTaskSelector = true;
  
  $('#injectedTaskSelector').toggleClass('slideTasksFrameUp');
} else {
  $('#injectedTaskSelector').toggleClass('slideTasksFrameUp');
}
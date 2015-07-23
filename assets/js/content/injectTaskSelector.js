/*
 * This script is injected into every page the user opens. It injects an iframe (sidebar.html) that users can interact with.
 */

if (typeof injectedTaskSelector === 'undefined') {
  injectedTaskSelector = {};
  chrome.runtime.onMessage.addListener(function(message, sender, sendResponse) {
      // Handle message.
      // In this example, message === 'whatever value; String, object, whatever'
    if message.openForLevel
      if !injectedTaskSelector[message.openForLevel] {
        var $app = $('<!-- INJECTED SELECTOR --> <iframe id="injectedTaskSelector'+message.openForLevel+'" sandbox="allow-same-origin allow-scripts allow-popups" src="' + chrome.extension.getURL('/html/taskSelector.html')+"?level=" + message.openForLevel + '"></iframe> <!-- END SELECTOR-->').appendTo('html');
        injectedTaskSelector[message.openForLevel] = true;
        $('#injectedTaskSelector'+message.openForLevel).toggleClass('slideTasksFrameUp');
      } else {
        $('#injectedTaskSelector'+message.openForLevel).toggleClass('slideTasksFrameUp');
      }
  });
}

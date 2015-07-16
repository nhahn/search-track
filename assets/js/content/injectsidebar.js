/*
 * This script is injected into every page the user opens. It injects an iframe (sidebar.html) that users can interact with.
 */

if (typeof injected === 'undefined' && window.menubar.visible && window.toolbar.visible) {
  // Inject HTML for sidebar if it hasn't been injected already
  var $app = $('<!-- INJECTED SIDEBAR --> <iframe id="injectedsidebar" style="position:fixed;z-index:2147483645;height:28px;bottom:0;width:100%;font-family:arial;padding:0;background-color:rgb(228,226,228);border:none;border-top:1px solid rgb(153,151,154)" sandbox="allow-same-origin allow-scripts allow-popups" src="' + chrome.extension.getURL('/html/sidebar.html') + '"></iframe> <!-- END SIDEBAR -->').appendTo('html');
  $('body').css('padding-bottom', 28);
	injected = true;
}

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.tOp) {
    $('#injectedsidebar').css('top',0);
    $('#injectedsidebar').css('border-top','none');
    $('body').css('margin-top', 28);

    // Fix Google page issues that result from pushing content down. TODO if google.com
    $('#searchform').css('position', 'inherit');
    $('a:contains(Screen reader users, click here to turn off Google Instant.)').css('position', 'inherit');
    $('#cnt').css('padding-top', '0');
    $('#sform').css('height', '0');
    // $('.jhp>#gb').css('top','-267px');
    $('#viewport').css('top','28px');

  } else if (request.bottom) {
    $('#injectedsidebar').css('top','inherit');
    $('#injectedsidebar').css('bottom',0);
    $('#injectedsidebar').css('border-top','1px solid rgb(153,151,154)');
    $('body').css('padding-bottom', 28);
    $('body').css('margin-top', 0);
    $('#viewport').css('top','0');
  }
});


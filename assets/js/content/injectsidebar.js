/*
 * This script is injected into every page the user opens. It injects an iframe (sidebar.html) that users can interact with.
 */

if (typeof injected === 'undefined') {
  $(document).ready(function() {
    $('body').css('margin-top', "28px");

    // Fix Google page issues that result from pushing content down. TODO if google
    $('#searchform').css('position', 'inherit');
    console.log($('a:contains(Screen reader users, click here to turn off Google Instant.)'));
    $('a:contains(Screen reader users, click here to turn off Google Instant.)').css('position', 'inherit');
    $('#cnt').css('padding-top', '0');
    $('#sform').css('height', '0');
    // $('.jhp>#gb').css('top','-267px');
    $('#viewport').css('top','28px');
  });

  // Inject HTML for sidebar if it hasn't been injected already
  var $app = $('<!-- INJECTED SIDEBAR --> <iframe id="injectedsidebar" style="position:fixed;z-index:2147483645;height:28px;top:0;width:100%;font-family:arial;padding:0;background-color:rgba(221,219,221,0.85);border:none;" sandbox="allow-same-origin allow-scripts allow-popups" src="' + chrome.extension.getURL('/html/sidebar.html') + '"></iframe> <!-- END SIDEBAR -->').appendTo('html');
  // $('body').css('padding-bottom', 28px);
	injected = true;
}


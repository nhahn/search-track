
chrome.browserAction.onClicked.addListener (callback) ->
  chrome.tabs.create {'url': chrome.extension.getURL('/graph-app/main.html')}, (tab) ->
    # Tab opened.

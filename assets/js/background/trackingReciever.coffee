chrome.runtime.onStartup.addListener () ->
  behavior = chrome.runtime.connect

#Track which tabs are active at a given moment
chrome.tabs.onActivated.addListener () ->
  
  

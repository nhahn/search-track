var takeSnapshot, trackFocus, trackReplace;

takeSnapshot = function(action) {
  return chrome.tabs.query({
    windowType: 'normal'
  }, function(tabs) {
    return chrome.windows.getCurrent(null, function(window) {
      var saveTabs, snapshotId, tab, time, _i, _len;
      saveTabs = [];
      snapshotId = dbMethods.generateUUID();
      time = Date.now();
      for (_i = 0, _len = tabs.length; _i < _len; _i++) {
        tab = tabs[_i];
        tab.type = 'tab';
        tab.snapshotAction = action;
        tab.domain = URI(tab.url).domain();
        tab.urlHash = CryptoJS.MD5(tab.url).toString(CryptoJS.enc.Base64);
        tab.domainHash = CryptoJS.MD5(tab.domain).toString(CryptoJS.enc.Base64);
        tab.snapshotId = snapshotId;
        tab.time = time;
        delete tab.width;
        delete tab.height;
        delete tab.selected;
        delete tab.highlighted;
        delete tab.incognito;
        delete tab.title;
        saveTabs.push(tab);
      }
      TabInfo.db.insert(saveTabs);
      return console.log('========== END   SNAPSHOT ==========');
    });
  });
};

trackFocus = function(action, windowId, tabId) {
  var data;
  console.log('activated - ' + windowId + ':' + tabId);
  data = {
    type: 'focus',
    windowId: windowId,
    tabId: tabId,
    action: action,
    time: Date.now()
  };
  return TabInfo.db.insert(data);
};

trackReplace = function(removedTabId, addedTabId) {
  return console.log('replaced - ' + addedTabId + ':' + removedTabId);
};

var current_title = "";
// chrome.tabs.query({'currentWindow': true, 'active': true}, function(tabs) {
//   console.log(tabs);
//   // current_title = tabs[0].title;
// });
var init_time = Date.now();

/* records time spent on each tab in SavedInfo
 * issue: this will be very skewed towards the tabs that are open when you switch out of Chrome. I'm
 * also basing SavedInfo on tab titles, which can be variable
 */
function recordElapsedTime(oldTabTitle, newTabId) {
  var t = SavedInfo.db().filter({'title':oldTabTitle}).get();
  console.log("Last tab: " + oldTabTitle);

  // Bug: t.timeElapsed is NaN.
  console.log(t);
  var oldTime = t.timeElapsed;

  if (t.length != 0) {
    SavedInfo.db().filter({'title':oldTabTitle}).update(
    {'timeElapsed': (oldTime+Date.now()-init_time)}).callback(function() {
      console.log('Updated time for \"' + oldTabTitle + '\", spent ' + (Date.now()-init_time)/1000 + ' s');
      console.log('Total time: ' + t.timeElapsed + ' ms');  
    });
  }

  chrome.tabs.get(newTabId, function(tab) {
    current_title = tab.title;
    init_time = Date.now();
  });
}
  
chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  if (changeInfo.status == null) {
    console.log(changeInfo);
    return;
  }
  recordElapsedTime(current_title, tabId);
  return takeSnapshot('updated:' + changeInfo.status);
});

chrome.tabs.onAttached.addListener(function(tabId, attachInfo) {
  return takeSnapshot('attached:' + attachInfo.newWindowId + ':' + attachInfo.newPosition);
});

chrome.tabs.onMoved.addListener(function(tabId, moveInfo) {
  return takeSnapshot('moved:' + moveInfo.windowId + ':' + moveInfo.fromIndex + ':' + moveInfo.toIndex);
});

chrome.tabs.onRemoved.addListener(function(tabId, removeInfo) {
  return takeSnapshot('removed:' + removeInfo.windowId + ':' + removeInfo.isWindowClosing);
});

chrome.tabs.onActivated.addListener(function(activeInfo) {
  recordElapsedTime(current_title, activeInfo.tabId);
  return trackFocus('tabChange', activeInfo.windowId, activeInfo.tabId);
});

chrome.windows.onFocusChanged.addListener(function(windowId) {
  return chrome.tabs.query({
    active: true,
    windowId: windowId,
    currentWindow: true
  }, function(tabs) {
    var tab;
    if (tabs.length > 0) {
      tab = tabs[0];
      return trackFocus('windowChange', windowId, tab.id);
    }
  });
});

chrome.tabs.onReplaced.addListener(function(addedTabId, removedTabId) {
  return trackReplace(removedTabId, addedTabId);
});

// ---
// generated by coffee-script 1.9.0
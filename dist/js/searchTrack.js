
/*
 * This file keeps track of the Google searches a person performs in the background. It saves them
 * in the local storage in the "queries" variable
 */
var searchTrack;

searchTrack = {};

searchTrack.addPageRelation = function(url, query, tabId) {};

searchTrack.removeTab = function(searches, tabId) {
  var idx, tabs;
  tabs = searches.first().tabs;
  idx = tabs.indexOf(tabId);
  if (idx > -1) {
    tabs.splice(idx, 1);
  }
  return searches.update({
    tabs: tabs
  });
};

searchTrack.addTab = function(searches, tabId) {
  var tabs;
  tabs = searches.first().tabs;
  if (tabs.indexOf(tabId) < 0) {
    tabs.push(tabId);
  }
  return searches.update({
    tabs: tabs,
    date: Date.now()
  });
};

chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  var matches, query, searchInfo;
  if (changeInfo.url != null) {
    console.log('onUpdate: ' + changeInfo.url);
    matches = changeInfo.url.match(/www\.google\.com\/.*q=(.*?)($|&)/);
    if (matches !== null) {
      query = decodeURIComponent(matches[1].replace(/\+/g, ' '));
      console.log('onUpdate query: ' + query);
      if (query === "") {
        return;
      }
      searchInfo = SearchInfo.db({
        tabs: {
          has: tabId
        }
      });
      if (searchInfo.first()) {
        searchTrack.removeTab(searchInfo, tabId);
      }
      searchInfo = SearchInfo.db([
        {
          name: query
        }
      ]);
      console.log('onUpdate query is: ' + query);
      if (!searchInfo.first()) {
        console.log('creating for: ' + changeInfo.url);
        SearchInfo.db.insert({
          tabs: [tabId],
          date: Date.now(),
          name: query
        });
        return PageInfo.db.insert({
          url: changeInfo.url,
          query: query,
          tab: tabId,
          date: Date.now(),
          referrer: null,
          visits: 1,
          title: tab.title
        });
      } else {
        console.log('add tab for: ' + changeInfo.url);
        return searchTrack.addTab(searchInfo, tabId);
      }
    }
  }
});

chrome.webNavigation.onDOMContentLoaded.addListener(function(details) {
  var searchInfo;
  console.log('onLoaded: ' + details);
  searchInfo = SearchInfo.db({
    tabs: {
      has: details.tabId
    }
  });
  if (searchInfo.first()) {
    return chrome.tabs.get(details.tabId, function(tab) {
      var pages;
      pages = PageInfo.db({
        tab: details.tabId
      }).order("date desc");
      if (pages.first()) {
        return chrome.tabs.executeScript(details.tabId, {
          code: 'window.document.documentElement.innerHTML'
        }, function(results) {
          var html;
          html = results[0];
          if ((html != null) && html.length > 10) {
            return $.ajax({
              type: 'POST',
              url: 'http://127.0.0.1:5000/tokenize',
              data: {
                'data': JSON.stringify({
                  'html': html
                })
              }
            }).success(function(results) {
              var insert_obj, vector;
              results = JSON.parse(results);
              vector = results['vector'];
              insert_obj = {
                vector: vector,
                title: tab.title
              };
              return pages.update(insert_obj, true);
            });
          }
        });
      }
    });
  }
});

chrome.webNavigation.onCommitted.addListener(function(details) {
  var pages, search, searchInfo;
  console.log('onCommitted: ' + details.tabId + ": " + details.transitionType + ", " + details.transitionQualifiers);
  searchInfo = SearchInfo.db({
    tabs: {
      has: details.tabId
    }
  });
  if (details.transitionQualifiers.indexOf("from_address_bar") > -1) {
    if (searchInfo.first()) {
      return searchTrack.removeTab(searchInfo, details.tabId);
    }
  } else if (details.transitionType === "link" || details.transitionType === "form_submit") {
    if (details.transitionQualifiers.indexOf("forward_back") > -1) {
      if (searchInfo.first()) {
        pages = PageInfo.db({
          tab: details.tabId
        }, {
          query: searchInfo.first().name
        }, {
          url: details.url
        });
        if (pages.first()) {
          return pages.update({
            visits: pages.first().visits + 1,
            date: Date.now()
          }, false);
        }
      }
    } else {
      if (searchInfo.first()) {
        if (details.transitionQualifiers.indexOf("client_redirect") > -1) {
          return chrome.tabs.get(details.tabId, function(tab) {
            var insert_obj;
            pages = PageInfo.db({
              tab: details.tabId
            }).order("date desc");
            if (pages.first()) {
              insert_obj = {
                url: details.url,
                title: tab.title
              };
              pages.update(insert_obj, false);
              return console.log('UPDATE');
            }
          });
        }
      }
    }
  } else if (details.transitionType === "auto_bookmark" || details.transitionType === "typed" || details.transitionType === "keyword") {
    pages = PageInfo.db({
      tab: details.tabId
    }, {
      url: details.url
    });
    if (pages.first()) {
      search = SearchInfo.db({
        name: pages.first().query
      });
      return searchTrack.addTab(search, details.tabId);
    } else if (searchInfo.first()) {
      return searchTrack.removeTab(searchInfo, details.tabId);
    }
  }
});

chrome.webNavigation.onCreatedNavigationTarget.addListener(function(details) {
  var searchInfo;
  console.log('onNav: ' + details.sourceTabId + ' -> ' + details.tabId);
  searchInfo = SearchInfo.db({
    tabs: {
      has: details.sourceTabId
    }
  });
  if (searchInfo.first()) {
    return chrome.tabs.get(details.tabId, function(tab) {
      var insert_obj, pages;
      insert_obj = {
        url: details.url,
        query: searchInfo.first().name,
        tab: details.tabId,
        date: Date.now(),
        referrer: null,
        visits: 1,
        title: tab.title
      };
      pages = PageInfo.db({
        tab: details.sourceTabId
      }).order("date desc");
      if (pages.first()) {
        insert_obj.referrer = pages.first().___id;
      }
      PageInfo.db.insert(insert_obj);
      return searchTrack.addTab(searchInfo, details.tabId);
    });
  }
});

//# sourceMappingURL=searchTrack.js.map

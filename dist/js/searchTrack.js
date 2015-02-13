
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
    matches = changeInfo.url.match(/www\.google\.com\/.*q=(.*?)($|&)/);
    if (matches !== null) {
      query = decodeURIComponent(matches[1].replace(/\+/g, ' '));
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
      if (!searchInfo.first()) {
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
        return searchTrack.addTab(searchInfo, tabId);
      }
    }
  }
});

chrome.webNavigation.onDOMContentLoaded.addListener(function(details) {
  var searchInfo;
  console.log('_a');
  searchInfo = SearchInfo.db({
    tabs: {
      has: details.tabId
    }
  });
  console.log(details);
  if (searchInfo.first()) {
    console.log('_b');
    return chrome.tabs.get(details.tabId, function(tab) {
      var pages;
      pages = PageInfo.db({
        tab: details.tabId
      }).order("date desc");
      if (pages.first()) {
        console.log('_c');
        return chrome.tabs.executeScript(details.tabId, {
          code: 'window.document.documentElement.innerHTML'
        }, function(results) {
          var insert_obj;
          console.log('_d');
          console.log(results);
          insert_obj = {
            html: results[0],
            title: tab.title
          };
          pages.update(insert_obj);
          return console.log(PageInfo.db());
        });
      }
    });
  }
});

chrome.webNavigation.onCommitted.addListener(function(details) {
  var pages, search, searchInfo;
  searchInfo = SearchInfo.db({
    tabs: {
      has: details.tabId
    }
  });
  console.log(details);
  if (details.transitionQualifiers.indexOf("from_address_bar") > -1) {
    if (searchInfo.first()) {
      searchTrack.removeTab(searchInfo, details.tabId);
      return console.log('a');
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
        console.log('b');
        if (pages.first()) {
          pages.update({
            visits: pages.first().visits + 1,
            date: Date.now()
          });
          return console.log('c');
        }
      }
    } else {
      console.log('d');
      if (searchInfo.first()) {
        console.log('e');
        if (details.transitionQualifiers.indexOf("client_redirect") > -1) {
          console.log('e1');
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
              return pages.update(insert_obj);
            }
          });
        } else {
          console.log('e2');
          return chrome.tabs.get(details.tabId, function(tab) {
            var insert_obj;
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
              tab: details.tabId
            }).order("date desc");
            if (pages.first()) {
              insert_obj.referrer = pages.first().___id;
            }
            return PageInfo.db.insert(insert_obj);
          });
        }
      }
    }
  } else if (details.transitionType === "auto_bookmark" || details.transitionType === "typed" || details.transitionType === "keyword") {
    console.log('f');
    pages = PageInfo.db({
      tab: details.tabId
    }, {
      url: details.url
    });
    if (pages.first()) {
      console.log('g');
      search = SearchInfo.db({
        name: pages.first().query
      });
      return searchTrack.addTab(search, details.tabId);
    } else if (searchInfo.first()) {
      console.log('h');
      return searchTrack.removeTab(searchInfo, details.tabId);
    }
  }
});

chrome.webNavigation.onCreatedNavigationTarget.addListener(function(details) {
  var searchInfo;
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
      return PageInfo.db.insert(insert_obj);
    });
  }
});

//# sourceMappingURL=searchTrack.js.map

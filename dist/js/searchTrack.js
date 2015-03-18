
/*
 * This file keeps track of the Google searches a person performs in the background. It saves them
 * in the local storage in the "queries" variable
 */
var createOrUpdateSearchInfo, extractGoogleRedirectURL, getContentAndTokenize, searchTrack;

searchTrack = {};

searchTrack.addPageRelation = function(url, query, tabId) {};

searchTrack.removeTab = function(searchInfo, ___id) {
  var idx, tabs;
  tabs = searchInfo.tabs;
  idx = tabs.indexOf(___id);
  if (idx > -1) {
    tabs.splice(idx, 1);
  }
  return SearchInfo.db(searchInfo).update({
    tabs: tabs
  });
};

searchTrack.addTab = function(searchInfo, ___id) {
  var tabs;
  tabs = searchInfo.tabs;
  if (tabs.indexOf(___id) < 0) {
    tabs.push(___id);
  }
  return SearchInfo.db(searchInfo).update({
    tabs: tabs,
    date: Date.now()
  });
};

extractGoogleRedirectURL = function(url) {
  var matches;
  matches = url.match(/www\.google\.com\/.*url=(.*?)($|&)/);
  if (matches === null) {
    return url;
  }
  url = decodeURIComponent(matches[1].replace(/\+/g, ' '));
  return url;
};

createOrUpdateSearchInfo = function(tabId, tab, query) {
  var data, pageInfo, searchInfo;
  searchInfo = SearchInfo.db([
    {
      name: query
    }
  ]).order("date desc").first();
  if (!searchInfo) {
    console.log('creating for: ' + tab.url);
    data = {
      isSERP: true,
      url: tab.url,
      query: query,
      tab: tabId,
      date: Date.now(),
      referrer: null,
      visits: 1,
      title: tab.title
    };
    PageInfo.db.insert(data);
    pageInfo = PageInfo.db(data).order("date desc").first();
    return SearchInfo.db.insert({
      tabs: [pageInfo.___id],
      date: Date.now(),
      name: query
    });
  } else {
    pageInfo = PageInfo.db({
      url: tab.url,
      query: query
    }).order("date desc").first();
    if (!pageInfo) {
      data = {
        isSERP: true,
        url: tab.url,
        query: query,
        tab: tabId,
        date: Date.now(),
        referrer: null,
        visits: 1,
        title: tab.title
      };
      PageInfo.db.insert(data);
      pageInfo = PageInfo.db(data).order("date desc").first();
      console.log('add tab for: ');
      console.log(pageInfo);
      console.log('to: ');
      console.log(searchInfo);
      searchTrack.addTab(searchInfo, pageInfo.___id);
      console.log('result: ');
      return console.log(searchInfo);
    }
  }
};

getContentAndTokenize = function(tabId, tab, pageInfo) {
  console.log("TOK:");
  console.log(tab.url);
  return chrome.tabs.executeScript(tabId, {
    code: 'window.document.documentElement.innerHTML'
  }, function(results) {
    var html;
    html = results[0];
    if ((html != null) && html.length > 10) {
      return $.ajax({
        type: 'POST',
        url: 'http://104.131.7.171/lda',
        data: {
          'data': JSON.stringify({
            'html': html
          })
        }
      }).success(function(results) {
        var update_obj, vector;
        console.log('lda');
        results = JSON.parse(results);
        vector = results['vector'];
        update_obj = {
          title: tab.title,
          url: tab.url,
          vector: results['vector'],
          topics: results['topics'],
          topic_vector: results['topic_vector'],
          size: results['size']
        };
        return PageInfo.db(pageInfo).update(update_obj, true);
      }).fail(function(a, t, e) {
        console.log('fail tokenize');
        return console.log(t);
      });
    }
  });
};

chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  var dup_pageInfo, matches, pageInfo, query, searchInfo;
  if (changeInfo.status !== 'complete') {
    return;
  }
  console.log('onUpdated ' + tabId);
  console.log(changeInfo);
  matches = tab.url.match(/www\.google\.com\/.*q=(.*?)($|&)/);
  if (matches !== null) {
    query = decodeURIComponent(matches[1].replace(/\+/g, ' '));
    if (query !== "") {
      return createOrUpdateSearchInfo(tabId, tab, query);
    }
  } else {
    pageInfo = PageInfo.db({
      tab: tabId
    }).order("date desc").first();
    if (pageInfo) {
      searchInfo = SearchInfo.db({
        tabs: {
          has: pageInfo.___id
        }
      }).order("date desc").first();
      dup_pageInfo = PageInfo.db({
        title: tab.title,
        url: tab.url,
        query: searchInfo.name
      }).first();
      if (dup_pageInfo) {
        return PageInfo.db(pageInfo).remove();
      } else {
        return getContentAndTokenize(tabId, tab, pageInfo);
      }
    }
  }
});

chrome.webNavigation.onCompleted.addListener(function(details) {
  if (details.frameId !== 0) {
    return;
  }
  console.log('onCompleted:');
  console.log(details);
  return console.log(details.url);
});

chrome.webNavigation.onCreatedNavigationTarget.addListener(function(details) {
  console.log('onNav: ' + details.sourceTabId + ' -> ' + details.tabId);
  details.url = extractGoogleRedirectURL(details.url);
  return chrome.tabs.get(details.sourceTabId, function(sourceTab) {
    var pageInfo, searchInfo;
    pageInfo = PageInfo.db({
      url: sourceTab.url
    }).order("date desc").first();
    searchInfo = SearchInfo.db({
      tabs: {
        has: pageInfo.___id
      }
    }).order("date desc").first();
    if (searchInfo) {
      PageInfo.db.insert({
        isSERP: false,
        tab: details.tabId,
        query: searchInfo.name,
        referrer: pageInfo.___id
      });
      pageInfo = PageInfo.db({
        tab: details.tabId,
        query: searchInfo.name
      }).order("date desc").first();
      return searchTrack.addTab(searchInfo, pageInfo.___id);
    }
  });
});

//# sourceMappingURL=searchTrack.js.map

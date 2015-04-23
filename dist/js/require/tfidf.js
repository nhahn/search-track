var TfIdf, natural;

natural = require('natural');

TfIdf = natural.TfIdf;

self.addEventListener('runTFIDF', function(e) {
  var tfidf;
  tfidf = new TfIdf();
  e.data.forEach(function(doc) {
    return tfidf.addDocument(doc);
  });
  return self.postMessage('complete', tfidf);
});

//# sourceMappingURL=tfidf.js.map

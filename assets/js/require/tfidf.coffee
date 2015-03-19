natural = require('natural')
TfIdf = natural.TfIdf

self.addEventListener 'runTFIDF', (e) ->
  tfidf = new TfIdf()
  e.data.forEach (doc) ->
    tfidf.addDocument(doc)
  self.postMessage 'complete', tfidf

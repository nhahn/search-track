# Search Track
Helps you track, manage, and learn from your web searches

Dependencies
------------

This project uses [Node.js](http://node.js) and [Grunt](http://gruntjs.com) for dependency compilation. These will need to be installed on your machine to compile and install the extension. Node.js can be installed using the various package installers on their website, and the Grunt command line can be installed using `npm`. 

```bash
npm install -g grunt
npm install -g grunt-cli
```

Additionally, install the various Grunt compilers used in the project
```bash
npm install
```

[Bower](http://bower.io) is used for external javascript asset management. You will need to install bower, and then download the javascript dependencies.
```bash
npm install -g bower
bower install
```

Lastly (and this is the only command you really need to run while developing) you just need to run Grunt
```bash
grunt
```
This will copy, compile, etc. everything, and watch for any changes in the `assets` folder. To stop it from watching, just hit `CTRL+C`.

Running
---------

To run the extension, you will need to complete the above steps in order to properly compile the extension. Once complete, add it to chrome using the 'Load unpacked extension...' button. Load the `dist` directory in the Git repository, as this has all of the compiled file in it. 

Development
-------------

All external packages are downloaded and placed in the `vendor` directory using bower. Any assets in the `assets` directory are compiled (if they are less/sass/coffee script) and synced to the dist directory along with the vendor files using Grunt. Please only develop this extension using the files in the `assets` directory rather than the `dist` directory. If you need to add an external javascript file / module, please find the appropriate package in Bower. 

### Style

The application features, and heavily uses, Promies per the [Bluebird](https://github.com/petkaantonov/bluebird) library. This means that most functions built out in this application return a promise for their operations, rather than featuring a callback. Additionally, many of the Chrome APIs have been wrapper, and feature promisified versions (specifically, [tabs](https://developer.chrome.com/extensions/tabs), [sessions](https://developer.chrome.com/extensions/sessions), [history](https://developer.chrome.com/extensions/history), and [windows](https://developer.chrome.com/extensions/windows)). For more information on how to use promises, please see the [Bluebird API documentation](https://github.com/petkaantonov/bluebird/blob/master/API.md). 

### Pieces
The application is divided into two working parts. A background service that manages the searches, and a front-end companion that provides some real-time information from the service. 

#### DB APIs
 In order to manage the large amount of information this application records, we use a flavor of [IndexDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API) called Dexie.js. All of the files associated with the db api can be found in the `assets/js/api` folder. The various tables and keys are setup in `dbApi.coffee` file. Additionally, for each table, there is a Javascript class defined, with various instance and class methods. These are:
 * Task (`taskAPI.coffee`) - The task organizational unit for various tabs and pages
 * Tab (`tabAPI.coffee`) - A stored representation of the [Chrome Tab object](https://developer.chrome.com/extensions/tabs#type-Tab)
 * Page (`pageAPI.coffee`) - Represents a web page visisted as part of a task / search.
 * Search (`searchAPI.coffee`) - A Google search used as an anchor point for various tasks.
 * TabEvent (`tabEventAPI.coffee`) - Associated with a Tab object, created when a tab is moved, focused, etc.
 * PageEvent (`pageEventAPI.coffee`) - Records information about interactions with a Page object.
 
All of these files are concatenated and compiled into `/js/trackAPI.js`. This is the **only file** that needs to be included in order to take advantage of this API. In addition to the classes mentioned above, there is also the general global `db` object that will become available. This can be used to query the above mentioned tables/objects using the Dexie.js API. For example:
 ```coffeescript
 #Logs the tab, whose id is 'abc-123'
 db.Tab.where('tabId').equals('abc-123').first().then (tab) ->
   console.log(tab)
 ```

#### Background Services
 First, running in the background, are the tracker services. These track the tabs, searches performed, and any page events of important pages. These can be found in the `assets/js/background` folder. These are finally all included in the `assets/html/background.jade` page and will run in the extension background.
 
#### Front-End Companion
  The front end provides some simple interaction with the information in the back-end. Its written in angular and linked to the back-end service with an angular module (created by me!) called [DexieBind](https://github.com/nhahn/angular-dexie-bind). This binds a particular Dexie.js query to an angular variable, so it can react in real time to updates to the database. The angular application, currently, has three views
  - a simple list that correlates web pages to the related searches
  - a tree view that allows you to view the web page path for a search.
  - and a settings page that allows you to clear the service's information

Dependencies
---------------

This application relies on a couple of dependencies. The core functionality depends on [Dexie.js](http://www.dexie.org) as an IndexDB wrapper and
[Bluebird](https://github.com/petkaantonov/bluebird) for Promises. 

The front-end application uses [AngularJS](https://angularjs.org) to create a real-time application and 
[Underscore.js](http://underscorejs.org/) to perform some data processing on the results returned from the back-end service.
There are some additional dependencies that provide the tree graphic ([D3](http://d3js.org)), integration with Twitter Bootstrap ([Angular-Bootstrap](http://angular-ui.github.io/bootstrap/)),
URI processing ([URI.js](http://medialize.github.io/URI.js/)) and, of course, [jQuery](http://jquery.com). 

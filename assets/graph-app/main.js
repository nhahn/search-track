import React from 'react';
import { Router, Route, Link} from 'react-router';
import { render } from 'react-dom';
import history from './history';
import alt from './alt'; 
import App from './components/App';

alt.bootstrap(JSON.stringify({
}));

render((
  <Router history={history}>
    <Route path="/" component={App}>
  
    </Route>
  </Router>
), document.body)


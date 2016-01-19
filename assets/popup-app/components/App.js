import React from 'react';
import {assign} from 'underscore';
import HomeActions from '../actions/HomeActions';

class App extends React.Component {

  constructor(props) {
    super(props);
    this.onChange = this.onChange.bind(this);
  }
 
  componentDidMount() {

  }
  
  componentWillUnmount() {
  }

  onChange(state) {
    this.setState(state);
  }
 
  render() {
    return (
      <div>
        { this.props.children }
      </div>
   );
  }
}

export default App;

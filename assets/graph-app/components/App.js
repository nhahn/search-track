import React from 'react';
import {assign} from 'underscore';
import HomeActions from '../actions/HomeActions';

class App extends React.Component {

  constructor(props) {
    super(props);
    this.onChange = this.onChange.bind(this);
    this.links = [];
    this.nodes = [];
  }
 
  componentDidMount() {
    Branch.getTopLevelBranches().then((branches) => {
      //We have the top level branches from react
      branches.map((branch) => {
        this.nodes.push(branch);
        let src = this.nodes.length - 1;
        return recursiveBuild(branch, src);
      })  
    });
  }
  
  recursiveBuild(branch, src) {
    branch.getChildren().then((children) => {
      return children.map((child) => {
        this.nodes.push(child);
        let target = this.nodes.length - 1;
        this.links.push({source: src, target: target});
        return this.recursiveBuild(child, target);
      })
    })
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
        <div>
          {this.nodes}
        </div>
      </div>
   );
  }
}

export default App;

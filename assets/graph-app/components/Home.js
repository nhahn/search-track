import React from 'react';
import {Link} from 'react-router';
import HomeStore from '../stores/HomeStore'
import HomeActions from '../actions/HomeActions';

class Home extends React.Component {

  constructor(props) {
    super(props);
    this.state = HomeStore.getState();
    this.onChange = this.onChange.bind(this);
  }

  componentDidMount() {
    HomeStore.listen(this.onChange);
  }

  componentWillUnmount() {
    HomeStore.unlisten(this.onChange);
  }

  onChange(state) {
    this.setState(state);
  }

  render() {
    return (
      <div className='container'>
        <div className='row' style={{textAlign: 'center', paddingTop: 30}}>
          <div className='col-sm-3 vcenter'>
            <img className="" src="/img/plant2.svg" style={{width: "100%", minWidth: 200}}/>
          </div>
          <div className='col-sm-3 vcenter'>
            <img className="heartbeat" src="/img/heart.svg" style={{width: "50%"}}/>
            <h2>Listen to your Plants Heartbeat</h2>
          </div>
          <div className='col-sm-6 vcenter'>
            <div className="row">
              <div className='col-sm-6 vcenter'>
                <div className='row'>
                  <div className='col-sm-5 vcenter'>
                    <img className="" src="/img/watering_can.svg" style={{minWidth: 100}}/>
                  </div>
                  <div className='col-sm-7 vcenter'>
                    <h4>Soil Moisture</h4>
                  </div>
                </div>
                <div className='row'>
                  <div className='col-sm-5 vcenter'>
                    <img className="" src="/img/sun.svg" style={{minWidth: 100}}/>
                  </div>
                  <div className='col-sm-7 vcenter'>
                    <h4>Sunlight (Lux)</h4>
                  </div>
                </div>
              </div>
              <div className='col-sm-6 vcenter'>
                <div className='row'>
                  <div className='col-sm-5 vcenter'>
                    <img className="" src="/img/humidity.svg" style={{minWidth: 100}}/>
                  </div>
                  <div className='col-sm-7 vcenter'>
                    <h4>Humidity</h4>
                  </div>
                </div>
                <div className='row'>
                  <div className='col-sm-5 vcenter'>
                    <img className="" src="/img/thermometer.svg" style={{minWidth: 100}}/>
                  </div>
                  <div className='col-sm-7 vcenter'>
                    <h4>Temperature</h4>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="jumbotron" style={{marginTop: 20}}>
          <h3>PlantMinder is a WiFi connected device that you place in your plants. It monitors your plants, and keeps you informed about their health and their enviornment</h3>
        </div>
        <div className='row' style={{marginTop: 20}}>
          <div className='col-sm-3 col-sm-offset-1'>
            <h3 style={{marginTop: 0}}>Peace of Mind</h3>
          </div>
          <div className='col-sm-6'>
            <p>Plant Minder helps you take care of and monitor your indoor plants. Your can install the application on your iPhone or Android advice to recieve alerts about care information. </p>
          </div>
        </div>
        <div className='row' style={{paddingTop: 20}}>
          <div className='col-sm-3 col-sm-offset-1'>
            <h3 style={{marginTop: 0}}>Optimal Care</h3>
          </div>
          <div className='col-sm-6'>
            <p>Plant Minder provides you history about sunlight, humidity, temperature, and soil moisture</p>
          </div>
        </div>
        <div className='row' style={{paddingTop: 20}}>
          <div className='col-sm-3 col-sm-offset-1'>
            <h3 style={{marginTop: 0}}>Set it and Forget It</h3>
          </div>
          <div className='col-sm-6'>
            <p>Plant Minder is powered by two AA batteries, can last for months!</p>
          </div>
        </div>
      </div> 
    )
  }
}

export default Home;

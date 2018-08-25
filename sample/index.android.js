/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  Button
} from 'react-native';
import MParticle from './index.js'
// import MParticle from 'react-native-mparticle'

export default class MParticleSample extends Component {
  constructor(props) {
    super(props);
    this.state = {isShowingText: true,
                  optedOut: true,
                  attributionResults: "{value: no attributionResults}",
                  isKitActive: true};

    this._toggleOptOut = this._toggleOptOut.bind(this)
    this._getAttributionResults = this._getAttributionResults.bind(this)
    this._isKitActive = this._isKitActive.bind(this)
    this.render = this.render.bind(this)

    // Example Login
    var request = new MParticle.IdentityRequest();
    request.email = 'testing1@gmail.com';
    request.onUserAlias = (previousUser, newUser) => {
      console.debug(previousUser.userID);
      console.debug(newUser.userID);
    };

    MParticle.Identity.login(request, (error, user) => {
      if (error) {
        console.debug(error);
      } else {
        console.debug(user.userAttributes);
      }
    });

    // Toggle the state every few seconds
    setInterval(() => {
        MParticle.logEvent('Test event', MParticle.EventType.Other, { 'Test key': 'Test value' })
        this.setState((previousState) => {
          return {isShowingText: !previousState.isShowingText}
        })
        MParticle.Identity.getCurrentUser((currentUser) => {
          currentUser.setUserTag('regular');
        });
        var request = new MParticle.IdentityRequest();
        request.email = 'testing1@gmail.com';
        request.customerId = "vlknasdlknv"
        request.setUserIdentity('12345', MParticle.UserIdentityType.Alias);

        MParticle.Identity.login(request, (error, userID) => {
          if (error) {
            console.debug(error);
          } else {
            console.debug(userID);
          }
        });

        const product = new MParticle.Product('Test product for cart', '1234', 19.99)
        const transactionAttributes = new MParticle.TransactionAttributes('Test transaction id')
        const event = MParticle.CommerceEvent.createProductActionEvent(MParticle.ProductActionType.AddToCart, [product], transactionAttributes)

        MParticle.logCommerceEvent(event)
        MParticle.logPushRegistration("afslibvnoewtibnsgb", "vdasvadsdsav");
        console.debug("interval")
    }, 5000);
  }

  _toggleOptOut() {
    MParticle.getOptOut((optedOut) => {
          MParticle.setOptOut(!optedOut)
          console.debug("setOptout" + optedOut)
          this.setState((previousState) => {
            console.debug("returning state")
            return { optedOut: !optedOut };
          })
        })
  }

  _getAttributionResults() {
    MParticle.getAttributions((_attributionResults) => {
      this.setState((previousState) => {
        return {attributionResults: _attributionResults}
      })
    })
  }

  _isKitActive() {
    MParticle.isKitActive(80, (active) => {
      this.setState((previousState) => {
        return {isKitActive: active}
      })
    })
  }

  render() {
    let display = this.state.isShowingText ? 'Sending Event' : ' '
    let optedOut = this.state.optedOut ? 'true' : 'false'
    let optAction = this.state.optedOut ? 'In' : 'Out'
    let kitActive = this.state.isKitActive ? 'true' : 'false'
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native! {display}
          </Text>
        <Text style={styles.welcome}>
        Opted Out = {optedOut}
        </Text>
        <Button 
          onPress={() => {this._toggleOptOut()}}
          title={'Opt ' + optAction}/>
        <Text>
          Attributes = {JSON.stringify(this.state.attributionResults)}
          </Text>
        <Button
          onPress={() => {this._getAttributionResults()}}
          title="Get Attribution Results"/>
        <Text>
          KitActive = {kitActive} (should switch to false)
          </Text>
          <Button
            onPress={() => {this._isKitActive()}}
            title="Check Kit Active"/>
        <Text style={styles.instructions}>
          To get started, edit index.ios.js
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Cmd+D or shake for dev menu
        </Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('MParticleSample', () => MParticleSample);
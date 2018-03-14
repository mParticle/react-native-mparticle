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
  View
} from 'react-native';
import MParticle from 'react-native-mparticle';

export default class MParticleSample extends Component {
  constructor(props) {
    super(props);
    this.state = {isShowingText: true};

    // Example Login
    // var request = new MParticle.IdentityRequest();
    // request.email = 'testing1@gmail.com';
    // request.onUserAlias = (previousUser, newUser) => {
    //   console.debug(previousUser.userID);
    //   console.debug(newUser.userID);
    // };

    // MParticle.Identity.login(request, (error, user) => {
    //   if (error) {
    //     console.debug(error);
    //   } else {
    //     console.debug(user.userAttributes);
    //   }
    // });

    // Toggle the state every few seconds
    setInterval(() => {
      this.setState(previousState => {
        //MParticle.logEvent('Test event', MParticle.EventType.Other, { 'Test key': 'Test value' })
        MParticle.Identity.getCurrentUser((currentUser) => {
          currentUser.setUserTag('regular');
        });
        var request = new MParticle.IdentityRequest();
        request.email = 'testing2@gmail.com';

        MParticle.Identity.modify(request, (error, userID) => {
          console.error(error);
          if (error) {
            console.debug('Error:');
            console.error(error);
          } else {
            console.debug('Modify Result:');
            console.debug(userID);
          }
        });

        const product = new MParticle.Product('Test product for cart', '1234', 19.99)
        const transactionAttributes = new MParticle.TransactionAttributes('Test transaction id')
        const event = MParticle.CommerceEvent.createProductActionEvent(MParticle.ProductActionType.AddToCart, [product], transactionAttributes)

        MParticle.logCommerceEvent(event)

        return { isShowingText: !previousState.isShowingText };
      });
    }, 5000);
  }

  render() {
    let display = this.state.isShowingText ? 'Sending Event' : ' ';
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native!
        </Text>
        <Text style={styles.welcome}>
          {display}
        </Text>
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

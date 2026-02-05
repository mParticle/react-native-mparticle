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
  Button,
  Platform,
  findNodeHandle,
  ScrollView,
  NativeEventEmitter,
  SafeAreaView,
  TextInput,
  View,
  TouchableOpacity,
  KeyboardAvoidingView,
} from 'react-native';
import MParticle from 'react-native-mparticle';

const { RoktLayoutView } = MParticle;

const eventManagerEmitter = new NativeEventEmitter(MParticle.RoktEventManager);

export default class MParticleSample extends Component {
    constructor(props) {
        super(props);
        this.placeholder1 = React.createRef();
        this.state = {
            isShowingText: true,
            optedOut: true,
            attributionResults: "{value: no attributionResults}",
            session: '',
            isKitActive: true,
            customIdentifier: 'MSDKBottomSheetLayout',
        };

        this._toggleOptOut = this._toggleOptOut.bind(this)
        this._getAttributionResults = this._getAttributionResults.bind(this)
        this._isKitActive = this._isKitActive.bind(this)
        this.render = this.render.bind(this)

        // Example Login
        var request = new MParticle.IdentityRequest();
        request.email = 'testing1@gmail.com';
        request.customerId = "123"
        MParticle.Identity.login(request, (error, userId, previousUserId) => {
            if (error) {
                console.debug(error);
            }

            // Only create alias request if there's a previous user
            if (previousUserId) {
                var previousUser = new MParticle.User(previousUserId);
                previousUser.getFirstSeen((firstSeen) => {
                    previousUser.getLastSeen((lastSeen) => {
                        var aliasRequest = new MParticle.AliasRequest()
                            .sourceMpid(previousUser.getMpid())
                            .destinationMpid(userId)
                            .startTime(firstSeen - 1000)
                            .endTime(lastSeen - 1000)
                        console.log("AliasRequest = " + JSON.stringify(aliasRequest));
                        MParticle.Identity.aliasUsers(aliasRequest, (success, error) => {
                            if (error) {
                                console.log("Alias error = " + error);
                            }
                            console.log("Alias result: " + success);
                        });

                        var aliasRequest2 = new MParticle.AliasRequest()
                            .sourceMpid(previousUser.getMpid())
                            .destinationMpid(userId)
                        console.log("AliasRequest2 = " + JSON.stringify(aliasRequest2));
                        MParticle.Identity.aliasUsers(aliasRequest2, (success, error) => {
                            if (error) {
                                console.log("Alias 2 error = " + error);
                            }
                            console.log("Alias 2 result: " + success);
                        });
                    })
                })
            } else {
                console.log("No previous user found, skipping alias request");
            }

            var user = new MParticle.User(userId);
            console.debug("User Attributes = " + user.userAttributes);
            MParticle.Identity.logout({}, (error, userId) => {
                if (error) {
                    console.debug("Logout error" + error);
                }
                var request = new MParticle.IdentityRequest();
                request.email = 'testing2@gmail.com';
                request.customerId = '456'
                MParticle.Identity.modify(request, (error) => {
                    if (error) {
                        console.debug("Modify error = " + error)
                    }
                });
            });
        });

        var i = 0;
        // Toggle the state every few seconds, 10 times
        var intervalId = setInterval(() => {
            MParticle.logEvent('Test event', MParticle.EventType.Other, { 'Test key': 'Test value', 'Test Boolean': true, 'Test Int': 1235, 'Test Double': 123.123 })
            this.setState((previousState) => {
                return {isShowingText: !previousState.isShowingText}
            })
            MParticle.Identity.getCurrentUser((currentUser) => {
                //currentUser.setUserTag('regular');
            });
            var request = new MParticle.IdentityRequest();
            request.email = 'testing1@gmail.com';
            request.customerId = "vlknasdlknv"
            request.setUserIdentity('12345', MParticle.UserIdentityType.Alias);

            const product = new MParticle.Product('Test product for cart', '1234', 19.99)
            const transactionAttributes = new MParticle.TransactionAttributes('Test transaction id')
            const event = MParticle.CommerceEvent.createProductActionEvent(MParticle.ProductActionType.AddToCart, [product], transactionAttributes)

            MParticle.logCommerceEvent(event)
            MParticle.logPushRegistration("afslibvnoewtibnsgb", "vdasvadsdsav");
            console.debug("interval")
            i++;
            if (i >= 10) {
                clearInterval(intervalId);
            }
        }, 5000);
    }

    componentDidMount() {
        MParticle.getSession(session => this.setState({ session }))
        if (eventManagerEmitter) {
            // Save subscriptions so we can remove them later
            this.roktCallbackListener = eventManagerEmitter.addListener(
                'RoktCallback',
                data => {
                    console.log('roktCallback received: ' + data.callbackValue);
                },
            );

            this.roktEventsListener = eventManagerEmitter.addListener('RoktEvents', data => {
                console.log(`*** ROKT EVENT *** ${JSON.stringify(data)}`);
            });
        } else {
            console.warn('RoktEventManager not available, skipping event listeners');
        }
    }

    componentWillUnmount() {
        // Remove event listeners to avoid duplicate subscriptions
        if (this.roktCallbackListener) {
            this.roktCallbackListener.remove();
        }
        if (this.roktEventsListener) {
            this.roktEventsListener.remove();
        }
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

    _incrementAttribute() {
        MParticle.Identity.getCurrentUser((currentUser) => {
            currentUser.incrementUserAttribute("incrementedAttribute", 1)
        })
    }

    _roktSelectOverlayPlacements() {
      this._roktSelectPlacements('MSDKOverlayLayout')
    }

    _roktSelectBottomSheetPlacements() {
      this._roktSelectPlacements('MSDKBottomSheetLayout')
    }

    _roktSelectEmbeddedPlacements() {
      this._roktSelectPlacements('MSDKEmbeddedLayout')
    }

    _roktSelectPlacements(identifier) {
      // Platform-specific attributes
      const iosAttributes = {
        "email": "ios-user@example.com",
        "platform": "ios",
        "userId": "ios-54321",
        "deviceType": "mobile",
      };

      const androidAttributes = {
        "email": "android-user@example.com",
        "platform": "android",
        "userId": "android-67890",
        "deviceType": "mobile",
      };

      // Select attributes based on platform
      const attributes = Platform.OS === 'ios' ? iosAttributes : androidAttributes;
      console.log(`Platform detected: ${Platform.OS}, using ${Platform.OS === 'ios' ? 'iOS' : 'Android'} attributes:`, attributes);
      const cacheConfig = MParticle.Rokt.createCacheConfig(30, attributes);
      const config = MParticle.Rokt.createRoktConfig('system', cacheConfig);
      const placeholderMap = {
        'Location1': findNodeHandle(this.placeholder1.current),
      }
      MParticle.Rokt.selectPlacements(identifier, attributes, placeholderMap, config, null).then((result) => {
        console.debug("Rokt selectPlacements result: " + JSON.stringify(result))
      }).catch((error) => {
        console.debug("Rokt selectPlacements error: " + JSON.stringify(error))
      })
    }
    render() {
        let display = this.state.isShowingText ? 'Sending Event' : ' '
        let optedOut = this.state.optedOut ? 'true' : 'false'
        let optAction = this.state.optedOut ? 'In' : 'Out'
        let kitActive = this.state.isKitActive ? 'true' : 'false'
        return (
            <SafeAreaView style={styles.safeArea}>
                <KeyboardAvoidingView
                    style={styles.keyboardAvoid}
                    behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
                >
                <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
                    <View style={styles.header}>
                        <Text style={styles.logo}>mParticle</Text>
                        <Text style={styles.subtitle}>React Native SDK Sample</Text>
                    </View>
                    <Text style={styles.statusText}>
                        {display}
                    </Text>
                    <Text style={styles.infoText}>
                        Opted Out = {optedOut}
                    </Text>
                    <Button
                        onPress={() => {this._toggleOptOut()}}
                        title={'Opt ' + optAction}/>
                    <Text style={styles.infoText}>
                        Session = {JSON.stringify(this.state.session)}
                    </Text>
                    <Text style={styles.infoText}>
                        Attributes = {JSON.stringify(this.state.attributionResults)}
                    </Text>
                    <Button
                        onPress={() => {this._getAttributionResults()}}
                        title="Get Attribution Results"/>
                    <Text style={styles.infoText}>
                        KitActive = {kitActive} (should switch to false)
                    </Text>
                    <Button
                        onPress={() => {this._isKitActive()}}
                        title="Check Kit Active"/>
                    <Text style={styles.instructions}>
                        To get started, edit index.js
                    </Text>
                    <Text style={styles.instructions}>
                        Press Cmd+R to reload,{'\n'}
                        Cmd+D or shake for dev menu
                    </Text>

                    <Button
                        onPress={() => {this._incrementAttribute()}}
                        title="Increment Attribute"/>
                    <Text style={styles.sectionTitle}>ROKT</Text>
                    <Button title="ROKT Embedded" onPress={() => {this._roktSelectEmbeddedPlacements()}}/>
                    <Button title="ROKT Overlay" onPress={() => {this._roktSelectOverlayPlacements()}}/>
                    <Button title="ROKT BottomSheet" onPress={() => {this._roktSelectBottomSheetPlacements()}}/>

                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>Custom Placement</Text>
                        <TextInput
                            style={styles.textInput}
                            value={this.state.customIdentifier}
                            onChangeText={(text) => this.setState({ customIdentifier: text })}
                            placeholder="Enter placement identifier"
                            placeholderTextColor="#999"
                        />
                        <TouchableOpacity
                            style={styles.primaryButton}
                            onPress={() => this._roktSelectPlacements(this.state.customIdentifier)}
                        >
                            <Text style={styles.primaryButtonText}>Run Custom Placement</Text>
                        </TouchableOpacity>
                    </View>

                    <RoktLayoutView
                        ref={this.placeholder1}
                        placeholderName="Location1" />
                </ScrollView>
                </KeyboardAvoidingView>
            </SafeAreaView>
        );
    }
}

const styles = StyleSheet.create({
    safeArea: {
        flex: 1,
        backgroundColor: '#FFFFFF',
    },
    keyboardAvoid: {
        flex: 1,
    },
    container: {
        flexGrow: 1,
        padding: 20,
        backgroundColor: '#FFFFFF',
    },
    header: {
        alignItems: 'center',
        marginBottom: 20,
        paddingVertical: 15,
        borderBottomWidth: 1,
        borderBottomColor: '#E0E0E0',
    },
    logo: {
        fontSize: 32,
        fontWeight: 'bold',
        color: '#C20075',  // Beetroot
    },
    subtitle: {
        fontSize: 16,
        color: '#666666',
        marginTop: 4,
    },
    statusText: {
        textAlign: 'center',
        fontSize: 14,
        color: '#000000',
        marginBottom: 20,
    },
    section: {
        marginVertical: 15,
        padding: 15,
        backgroundColor: '#F8F8F8',
        borderRadius: 10,
    },
    sectionTitle: {
        fontSize: 16,
        fontWeight: '600',
        color: '#000000',
        marginBottom: 10,
        textAlign: 'center',
    },
    textInput: {
        borderWidth: 1,
        borderColor: '#E0E0E0',
        borderRadius: 8,
        padding: 12,
        fontSize: 14,
        backgroundColor: '#FFFFFF',
        marginBottom: 10,
        color: '#000000',
    },
    primaryButton: {
        backgroundColor: '#C20075',  // Beetroot
        paddingVertical: 12,
        paddingHorizontal: 20,
        borderRadius: 8,
        alignItems: 'center',
    },
    primaryButtonText: {
        color: '#FFFFFF',
        fontSize: 16,
        fontWeight: '600',
    },
    infoText: {
        fontSize: 14,
        color: '#666666',
        marginVertical: 5,
    },
    instructions: {
        textAlign: 'center',
        color: '#666666',
        marginBottom: 5,
    },
});

AppRegistry.registerComponent('MParticleSample', () => MParticleSample);

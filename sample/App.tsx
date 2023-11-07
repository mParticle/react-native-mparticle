import React, {useCallback, useEffect, useState} from 'react';
import type {PropsWithChildren} from 'react';
import {
  Button,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';
import MParticle from 'react-native-mparticle';

import {Colors, Header} from 'react-native/Libraries/NewAppScreen';

type SectionProps = PropsWithChildren<{
  title: string;
}>;

function Section({children, title}: SectionProps): JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';
  return (
    <View style={styles.sectionContainer}>
      <Text
        style={[
          styles.sectionTitle,
          {
            color: isDarkMode ? Colors.white : Colors.black,
          },
        ]}>
        {title}
      </Text>
      <View style={styles.sectionChildrenWrapper}>{children}</View>
    </View>
  );
}

function App(): JSX.Element {
  const [optedOut, setOptedOut] = useState(true);
  const [session, setSession] = useState<any>({});
  const [sendingEvent, setSendingEvent] = useState<boolean>(true);
  const [attributes, setAttributes] = useState<any>({
    value: 'no attributionResults',
  });
  const [isKitActive, setKitActiveState] = useState<boolean>(true);
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  const textStyle = [
    styles.sectionDescription,
    {
      color: isDarkMode ? Colors.light : Colors.dark,
    },
  ];

  const onPressOptOutToggle = useCallback(() => {
    MParticle.getOptOut(optedOut => {
      MParticle.setOptOut(!optedOut);
      setOptedOut(!optedOut);
    });
  }, []);

  const onPressGetAttributes = useCallback(() => {
    MParticle.getAttributions(attr => {
      setAttributes(attr);
    });
  }, []);

  const onPressGetKitActiveState = useCallback(() => {
    MParticle.isKitActive(80, res => {
      setKitActiveState(res);
    });
  }, []);

  const onPressIncrementAttribute = useCallback(() => {
    MParticle.Identity.getCurrentUser((currentUser: any) => {
      currentUser.incrementUserAttribute('incrementedAttribute', 1);
    });
  }, []);

  useEffect(() => {
    MParticle.getSession(sessionId => {
      setSession(sessionId);
    });
    onPressGetAttributes();
    onPressGetKitActiveState();
  }, []);

  useEffect(() => {
    const request = new MParticle.IdentityRequest();
    request.setEmail('testing1@gmail.com');
    request.setCustomerID('123');
    MParticle.Identity.login(
      request,
      (error: any, userId: any, previousUserId: any) => {
        if (error) {
          console.error(error);
          return;
        }
        var previousUser = new MParticle.User(previousUserId);
        previousUser.getFirstSeen((firstSeen: number) => {
          previousUser.getLastSeen((lastSeen: number) => {
            const aliasRequest = new MParticle.AliasRequest()
              .sourceMpid(previousUser.getMpid())
              .destinationMpid(userId)
              .startTime(firstSeen - 1000)
              .endTime(lastSeen - 1000);
            console.log(
              'AliasRequest: ' + JSON.stringify(aliasRequest, null, 2),
            );
            MParticle.Identity.aliasUsers(
              aliasRequest,
              (success: any, error: any) => {
                if (error) {
                  console.log('Alias error: ' + error);
                }
                console.log('Alias result: ' + success);
              },
            );

            const aliasRequest2 = new MParticle.AliasRequest()
              .sourceMpid(previousUser.getMpid())
              .destinationMpid(userId);
            console.log(
              'AliasRequest2 = ' + JSON.stringify(aliasRequest2, null, 2),
            );
            MParticle.Identity.aliasUsers(
              aliasRequest2,
              (success: any, error: any) => {
                if (error) {
                  console.log('Alias 2 error: ' + error);
                }
                console.log('Alias 2 result: ' + success);
              },
            );
          });
        });

        const user = new MParticle.User(userId);
        user.getUserAttributes((attrs: any) =>
          console.debug('User Attributes:', attrs),
        );
        MParticle.Identity.logout({}, (error: any, userId: any) => {
          if (error) {
            console.debug('Logout error: ' + error);
            return;
          }
          var request = new MParticle.IdentityRequest();
          request.setEmail('testing2@gmail.com');
          request.setCustomerID('456');
          MParticle.Identity.modify(request, (error: any) => {
            if (error) {
              console.debug('Modify error: ' + error);
            }
          });
        });
      },
    );
  }, []);

  useEffect(() => {
    var i = 0;
    // Toggle the state every few seconds, 10 times
    var intervalId = setInterval(() => {
      MParticle.logEvent('Test event', MParticle.EventType.Other, {
        'Test key': 'Test value',
      });
      setSendingEvent(!sendingEvent);
      MParticle.Identity.getCurrentUser((currentUser: any) => {
        currentUser.setUserTag('regular');
      });
      var request = new MParticle.IdentityRequest();
      request.setEmail('testing1@gmail.com');
      request.setCustomerID('vlknasdlknv');
      request.setUserIdentity('12345', MParticle.UserIdentityType.Alias);

      const product = new MParticle.Product(
        'Test product for cart',
        '1234',
        19.99,
      );
      const transactionAttributes = new MParticle.TransactionAttributes(
        'Test transaction id',
      );
      const event = MParticle.CommerceEvent.createProductActionEvent(
        MParticle.ProductActionType.AddToCart,
        [product],
        transactionAttributes,
      );

      MParticle.logCommerceEvent(event);
      MParticle.logPushRegistration('afslibvnoewtibnsgb', 'vdasvadsdsav');
      console.debug('interval');
      i++;
      if (i >= 10) {
        clearInterval(intervalId);
      }
    }, 5000);
  }, []);

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={backgroundStyle.backgroundColor}
      />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}>
        <Header />
        <View
          style={{
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
          }}>
          {sendingEvent && (
            <Text style={[textStyle, {backgroundColor: '#598afe'}]}>
              Sending event...
            </Text>
          )}
          <Section title="Opted Out?">
            <Text style={textStyle}>{optedOut ? 'Yes' : 'No'}</Text>
            <Button
              onPress={onPressOptOutToggle}
              title={`Opt ${optedOut ? 'In' : 'Out'}`}
            />
          </Section>
          <Section title="Session">
            <Text style={textStyle}>{JSON.stringify(session, null, 2)}</Text>
          </Section>
          <Section title="Attributes">
            <Text style={textStyle}>{JSON.stringify(attributes, null, 2)}</Text>
            <Button onPress={onPressGetAttributes} title="Refresh" />
          </Section>
          <Section title="Kit Active">
            <Text style={textStyle}>{isKitActive ? 'Active' : 'Inactive'}</Text>
            <Button onPress={onPressGetKitActiveState} title="Refresh" />
          </Section>
          <Section title="Increment Attribute">
            <Button
              onPress={onPressIncrementAttribute}
              title="Increment Attribute by 1"
            />
          </Section>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    display: 'flex',
    flex: 1,
  },
  sectionChildrenWrapper: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
});

export default App;

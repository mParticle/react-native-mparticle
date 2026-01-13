/**
 * Expo Test App for mParticle React Native SDK
 *
 * This app tests the Expo config plugin integration for the mParticle SDK.
 * It demonstrates SDK initialization, event logging, and Rokt placements.
 */

import React, { useState, useRef, useEffect } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  Platform,
  findNodeHandle,
  NativeEventEmitter,
} from 'react-native';
import MParticle from 'react-native-mparticle';

const { RoktLayoutView, RoktEventManager } = MParticle;

// Create event emitter for Rokt events
const eventManagerEmitter = new NativeEventEmitter(RoktEventManager);

export default function App() {
  const [eventName, setEventName] = useState('Test Event');
  const [status, setStatus] = useState('SDK initialized via native code');
  const [logs, setLogs] = useState<string[]>([]);

  // Ref for Rokt embedded placeholder
  const roktPlaceholderRef = useRef<any>(null);

  const addLog = (message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs(prev => [`[${timestamp}] ${message}`, ...prev].slice(0, 20));
  };

  // Set up Rokt event listeners
  useEffect(() => {
    if (!eventManagerEmitter) {
      console.warn('RoktEventManager not available, skipping event listeners');
      return;
    }

    const roktCallbackListener = eventManagerEmitter.addListener(
      'RoktCallback',
      (data: any) => {
        console.log('roktCallback received:', data.callbackValue);
        addLog(`Rokt callback: ${data.callbackValue}`);
      }
    );

    const roktEventsListener = eventManagerEmitter.addListener(
      'RoktEvents',
      (data: any) => {
        console.log('Rokt event:', JSON.stringify(data));
        addLog(`Rokt event: ${data.event || JSON.stringify(data)}`);
      }
    );

    return () => {
      roktCallbackListener.remove();
      roktEventsListener.remove();
    };
  }, []);

  const handleLogEvent = () => {
    if (!eventName.trim()) {
      setStatus('Error: Event name is required');
      return;
    }

    MParticle.logEvent(eventName, MParticle.EventType.Other, {
      source: 'ExpoTestApp',
      timestamp: new Date().toISOString(),
    });
    addLog(`Logged event: ${eventName}`);
    setStatus(`Event logged: ${eventName}`);
  };

  const handleLogScreenEvent = () => {
    MParticle.logScreenEvent('Expo Test Screen', {
      screen_name: 'Main',
      source: 'ExpoTestApp',
    });
    addLog('Logged screen event: Expo Test Screen');
    setStatus('Screen event logged');
  };

  const handleLogCommerceEvent = () => {
    const product = new MParticle.Product('Test Product', 'SKU-12345', 29.99);
    const transactionAttributes = new MParticle.TransactionAttributes(
      'TRANS-001'
    );
    const event = MParticle.CommerceEvent.createProductActionEvent(
      MParticle.ProductActionType.AddToCart,
      [product],
      transactionAttributes
    );

    MParticle.logCommerceEvent(event);
    addLog('Logged commerce event: AddToCart');
    setStatus('Commerce event logged');
  };

  const handleSetUserAttribute = () => {
    MParticle.Identity.getCurrentUser((currentUser: any) => {
      if (currentUser) {
        currentUser.setUserAttribute('test_attribute', 'expo_test_value');
        addLog('Set user attribute: test_attribute = expo_test_value');
        setStatus('User attribute set');
      } else {
        addLog('Error: No current user found');
        setStatus('Error: No current user');
      }
    });
  };

  const handleIdentify = () => {
    const request = new MParticle.IdentityRequest();
    request.email = 'expo-test@example.com';
    request.customerId = 'expo-test-123';

    MParticle.Identity.identify(
      request,
      (error: any, userId: string | null) => {
        if (error) {
          addLog(`Identify error: ${JSON.stringify(error)}`);
          setStatus('Identify failed');
        } else {
          addLog(`Identify success: userId = ${userId}`);
          setStatus(`Identified: ${userId}`);
        }
      }
    );
  };

  const handleGetCurrentUser = () => {
    MParticle.Identity.getCurrentUser((currentUser: any) => {
      if (currentUser) {
        addLog(
          `Current user ID: ${currentUser.userID || currentUser.getMpid?.()}`
        );
        setStatus(`Current user retrieved`);
      } else {
        addLog('No current user found');
        setStatus('No current user');
      }
    });
  };

  const handleCheckOptOut = () => {
    MParticle.getOptOut((optedOut: boolean) => {
      addLog(`Opt-out status: ${optedOut ? 'Opted out' : 'Opted in'}`);
      setStatus(`Opt-out: ${optedOut}`);
    });
  };

  // Rokt placement functions
  const handleRoktSelectPlacements = (identifier: string) => {
    // Platform-specific attributes
    const iosAttributes = {
      email: 'ios-expo-user@example.com',
      platform: 'ios',
      userId: 'ios-expo-54321',
      deviceType: 'mobile',
    };

    const androidAttributes = {
      email: 'android-expo-user@example.com',
      platform: 'android',
      userId: 'android-expo-67890',
      deviceType: 'mobile',
    };

    // Select attributes based on platform
    const attributes =
      Platform.OS === 'ios' ? iosAttributes : androidAttributes;

    addLog(`Rokt: Using ${Platform.OS} attributes for ${identifier}`);

    // Create Rokt config
    const cacheConfig = MParticle.Rokt.createCacheConfig(30, attributes);
    const config = MParticle.Rokt.createRoktConfig('system', cacheConfig);

    // Build placeholder map for embedded placements
    const placeholderMap: { [key: string]: number | null } = {};
    const nodeHandle = findNodeHandle(roktPlaceholderRef.current);
    if (nodeHandle !== null) {
      placeholderMap['Location1'] = nodeHandle;
    }

    // Call selectPlacements
    MParticle.Rokt.selectPlacements(
      identifier,
      attributes,
      placeholderMap,
      config,
      undefined
    )
      .then((result: any) => {
        addLog(`Rokt selectPlacements success: ${JSON.stringify(result)}`);
        setStatus(`Rokt: ${identifier} loaded`);
      })
      .catch((error: any) => {
        addLog(`Rokt selectPlacements error: ${JSON.stringify(error)}`);
        setStatus(`Rokt error: ${error.message || 'Unknown error'}`);
      });
  };

  const handleRoktEmbedded = () =>
    handleRoktSelectPlacements('MSDKEmbeddedLayout');
  const handleRoktOverlay = () =>
    handleRoktSelectPlacements('MSDKOverlayLayout');
  const handleRoktBottomSheet = () =>
    handleRoktSelectPlacements('MSDKBottomSheetLayout');

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" />
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={styles.title}>mParticle Expo Test</Text>
        <Text style={styles.subtitle}>
          Testing Expo Config Plugin Integration
        </Text>

        <View style={styles.statusContainer}>
          <Text style={styles.statusLabel}>Status:</Text>
          <Text style={styles.statusText}>{status}</Text>
        </View>

        <View style={styles.inputContainer}>
          <Text style={styles.label}>Event Name:</Text>
          <TextInput
            style={styles.input}
            value={eventName}
            onChangeText={setEventName}
            placeholder="Enter event name"
            autoCapitalize="none"
          />
        </View>

        <View style={styles.buttonGrid}>
          <TouchableOpacity
            style={[styles.button, styles.primaryButton]}
            onPress={handleLogEvent}
          >
            <Text style={styles.buttonText}>Log Event</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.secondaryButton]}
            onPress={handleLogScreenEvent}
          >
            <Text style={styles.buttonText}>Log Screen</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.secondaryButton]}
            onPress={handleLogCommerceEvent}
          >
            <Text style={styles.buttonText}>Log Commerce</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.tertiaryButton]}
            onPress={handleIdentify}
          >
            <Text style={styles.buttonText}>Identify</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.tertiaryButton]}
            onPress={handleGetCurrentUser}
          >
            <Text style={styles.buttonText}>Get User</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.tertiaryButton]}
            onPress={handleSetUserAttribute}
          >
            <Text style={styles.buttonText}>Set Attribute</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.infoButton]}
            onPress={handleCheckOptOut}
          >
            <Text style={styles.buttonText}>Check Opt-Out</Text>
          </TouchableOpacity>
        </View>

        {/* Rokt Section */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle}>Rokt Placements</Text>
          <Text style={styles.sectionSubtitle}>
            Test Rokt SDK integration via mParticle kit
          </Text>

          <View style={styles.buttonGrid}>
            <TouchableOpacity
              style={[styles.button, styles.roktButton]}
              onPress={handleRoktEmbedded}
            >
              <Text style={styles.buttonText}>Embedded</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.button, styles.roktButton]}
              onPress={handleRoktOverlay}
            >
              <Text style={styles.buttonText}>Overlay</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.button, styles.roktButtonAlt]}
              onPress={handleRoktBottomSheet}
            >
              <Text style={styles.buttonText}>Bottom Sheet</Text>
            </TouchableOpacity>
          </View>

          {/* Rokt Embedded Placeholder */}
          <View style={styles.roktPlaceholderContainer}>
            <Text style={styles.placeholderLabel}>
              Embedded Placement Area:
            </Text>
            <RoktLayoutView
              ref={roktPlaceholderRef}
              placeholderName="Location1"
            />
          </View>
        </View>

        <View style={styles.logsContainer}>
          <Text style={styles.logsTitle}>Activity Log:</Text>
          {logs.length === 0 ? (
            <Text style={styles.logEmpty}>No activity yet</Text>
          ) : (
            logs.map((log, index) => (
              <Text key={index} style={styles.logEntry}>
                {log}
              </Text>
            ))
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  scrollContent: {
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#04a0c1',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
    marginBottom: 24,
    textAlign: 'center',
  },
  statusContainer: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 20,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusLabel: {
    fontWeight: 'bold',
    marginRight: 8,
    color: '#333',
  },
  statusText: {
    flex: 1,
    color: '#04a0c1',
  },
  inputContainer: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 6,
  },
  input: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
  },
  buttonGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 24,
  },
  button: {
    width: '48%',
    padding: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 10,
  },
  primaryButton: {
    backgroundColor: '#04a0c1',
  },
  secondaryButton: {
    backgroundColor: '#28a745',
  },
  tertiaryButton: {
    backgroundColor: '#6f42c1',
  },
  infoButton: {
    backgroundColor: '#17a2b8',
    width: '100%',
  },
  buttonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
  },
  logsContainer: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  logsTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  logEmpty: {
    color: '#999',
    fontStyle: 'italic',
  },
  logEntry: {
    fontSize: 12,
    color: '#555',
    paddingVertical: 4,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  sectionContainer: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#e63946',
    marginBottom: 4,
  },
  sectionSubtitle: {
    fontSize: 12,
    color: '#666',
    marginBottom: 16,
  },
  roktButton: {
    backgroundColor: '#e63946',
  },
  roktButtonAlt: {
    backgroundColor: '#d62839',
    width: '100%',
  },
  roktPlaceholderContainer: {
    marginTop: 16,
    padding: 12,
    backgroundColor: '#f8f9fa',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#dee2e6',
    borderStyle: 'dashed',
    minHeight: 100,
  },
  placeholderLabel: {
    fontSize: 12,
    color: '#6c757d',
    marginBottom: 8,
  },
});

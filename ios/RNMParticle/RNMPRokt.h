#import <Foundation/Foundation.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <RNMParticle/RNMParticle.h>
#import <React/RCTBridge.h>

@interface RNMPRokt : NSObject<NativeMPRoktSpec>
@property (nonatomic, weak, nullable) RCTBridge *bridge;
#else

#import <React/RCTBridgeModule.h>
@interface RNMPRokt : NSObject <RCTBridgeModule>
#endif

@end

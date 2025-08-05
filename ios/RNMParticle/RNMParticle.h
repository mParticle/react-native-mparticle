#import <Foundation/Foundation.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <RNMParticle/RNMParticle.h>
@interface RNMParticle : NSObject <NativeMParticleSpec>
#else
#import <React/RCTBridgeModule.h>
@interface RNMParticle : NSObject <RCTBridgeModule>
#endif

@end

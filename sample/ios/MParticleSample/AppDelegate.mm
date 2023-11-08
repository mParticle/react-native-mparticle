#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
@import mParticle_Apple_SDK;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"MParticleSample";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};
  
  // Initialize mParticle
  // see: https://docs.mparticle.com/developers/sdk/ios/initialization/#initialize-the-sdk
  NSString *mParticleApiKey = @"YOUR-WORKSPACE-KEY-HERE";
  NSString *mParticleApiSecret = @"YOUR-WORKSPACE-SECRET-HERE";
  MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:mParticleApiKey secret:mParticleApiSecret];
  // Create Identity
  // see: https://docs.mparticle.com/developers/sdk/ios/idsync/#creating-an-idsync-request
  MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
  request.email = @"email@example.com";
  mParticleOptions.identifyRequest = request;
  mParticleOptions.onIdentifyComplete = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
    NSLog(@"Identify complete. userId = %@ error = %@", apiResult.user.userId, error);
  };
  
  [[MParticle sharedInstance] startWithOptions:mParticleOptions];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end

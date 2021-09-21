#import "AppDelegate.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import "mParticle.h"
#import "RNMParticle.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef FB_SONARKIT_ENABLED
  InitializeFlipper(application);
#endif

  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                   moduleName:@"MParticleSample"
                                            initialProperties:nil];

  MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"REPLACE ME"
                                                                 secret:@"REPLACE ME"];
  //Please see the Identity page for more information on building this object
  MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
  request.email = @"email@example.com";
  mParticleOptions.identifyRequest = request;
  mParticleOptions.onIdentifyComplete = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
    NSLog(@"Identify complete. userId = %@ error = %@", apiResult.user.userId, error);
  };
  
  [[MParticle sharedInstance] startWithOptions:mParticleOptions];

  if (@available(iOS 13.0, *)) {
      rootView.backgroundColor = [UIColor systemBackgroundColor];
  } else {
      rootView.backgroundColor = [UIColor whiteColor];
  }

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end

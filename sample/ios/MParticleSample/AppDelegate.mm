/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import "mParticle.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"MParticleSample";
  self.initialProps = @{};
  
  MPNetworkOptions *networkOptions = [[MPNetworkOptions alloc] init];
  networkOptions.pinningDisabled = true;
 
  MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"REPLACE_ME"
                                                                 secret:@"REPLACE_ME"];
  mParticleOptions.logLevel = MPILogLevelDebug;
  mParticleOptions.environment = MPEnvironmentProduction;
  
  //Please see the Identity page for more information on building this object
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
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end

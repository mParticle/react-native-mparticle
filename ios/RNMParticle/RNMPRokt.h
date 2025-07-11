#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>

@interface RNMPRokt : NSObject <RCTBridgeModule>

@property (nonatomic, weak, nullable) RCTBridge *bridge;

@end

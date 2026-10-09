// Private: the mParticle and RoktContracts headers, for every way an app can supply the SDKs.
//  - CocoaPods (static library or framework):  <mParticle_Apple_SDK_ObjC/...>, <RoktContracts/RoktContracts-Swift.h>
//  - a manually embedded xcframework:           <mParticle_Apple_SDK/...>, <RoktContracts/RoktContracts.h>
//  - flat public headers on the search path, as in a Swift Package Manager build: "mParticle.h"
//  - last resort, module import: works in .m files only, because this pod builds .mm files
//    without -fcxx-modules.
#if __has_include(<mParticle_Apple_SDK_ObjC/mParticle.h>)
    #import <mParticle_Apple_SDK_ObjC/mParticle.h>
    #import <mParticle_Apple_SDK_ObjC/MPRokt.h>
#elif __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
    #import <mParticle_Apple_SDK/MPRokt.h>
#elif __has_include("mParticle.h")
    #import "mParticle.h"
    #import "MPRokt.h"
#else
    @import mParticle_Apple_SDK_ObjC;
#endif

// RoktContracts for Objective-C (.m) files only. Objective-C++ files use its types through the
// Swift layer (RNMPRoktSwift.h), because a Swift Package Manager Objective-C++ target cannot
// import them; the SDK headers above only forward-declare RoktEmbeddedView, RoktConfig and RoktEvent.
#ifndef __cplusplus
#if __has_include(<RoktContracts/RoktContracts-Swift.h>)
    #import <RoktContracts/RoktContracts-Swift.h>
#elif __has_include(<RoktContracts/RoktContracts.h>)
    #import <RoktContracts/RoktContracts.h>
#elif __has_include("RoktContracts-Swift.h")
    #import "RoktContracts-Swift.h"
#else
    @import RoktContracts;
#endif
#endif // __cplusplus

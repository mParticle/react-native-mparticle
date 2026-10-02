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

#if __has_include(<RoktContracts/RoktContracts-Swift.h>)
    #import <RoktContracts/RoktContracts-Swift.h>
#elif __has_include(<RoktContracts/RoktContracts.h>)
    #import <RoktContracts/RoktContracts.h>
#elif __has_include("RoktContracts-Swift.h")
    #import "RoktContracts-Swift.h"
#else
    @import RoktContracts;
#endif

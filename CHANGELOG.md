# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add SPM hybrid bridge for mParticle-Apple-SDK iOS dependency (#283)
- Add Expo config plugin for mParticle integration (#270)

### Fixed

- Fix React Native Codegen issue with version 0.84 (#284)
- Prevent app crash in Release builds on iOS (#286)
- Log nil bridge before addUIBlock in New Architecture (#287)

## [2.8.1] - 2025-09-04

### Fixed

- Remove userIdentities key expectation in native iOS logic (#255)
- Use eventName in logEvent for Android (#254)

## [2.8.0] - 2025-08-07

### Changed

- Updated GitHub workflows for SDK release

## [2.7.13] - 2024-11-08

### Fixed

- Fix Swift File Support (#211)

## [2.7.12] - 2024-06-11

### Fixed

- Fix setVariant on Product (#207)

## [2.7.11] - 2024-04-03

### Fixed

- Add Static Library Install Steps (#204)

## [2.7.10] - 2024-03-12

### Added

- Add setLocation function (#196)

## [2.7.9] - 2023-12-07

### Added

- Add Media Event Type (#176)

## [2.7.8] - 2023-01-10

### Added

- Allow uploadInterval to be set manually (#95)
- Add Manual Upload (#86)

## [2.7.7] - 2022-10-19

### Fixed

- Correct quantity value conversion (#82)

## [2.7.6] - 2022-08-31

### Fixed

- Parse string values for transaction attributes to numbers (#81)

## [2.7.5] - 2022-07-28

### Fixed

- Update Android impression/promotion handling (#76)

## [2.7.4] - 2022-07-21

### Fixed

- Update podspec for tvOS support

## [2.7.3] - 2022-07-19

### Fixed

- Update podspec

## [2.7.2] - 2022-07-14

### Fixed

- Support tvOS implementation (#73)

## [2.7.1] - 2022-05-18

### Fixed

- Fix Android info() usages

## [2.7.0] - 2022-05-18

### Fixed

- Serialize Android getUserAttributes results to WritableMap

## [2.6.2] - 2022-03-31

### Added

- Add Android mapping for Commerce Events (currency, checkoutStep, checkoutOptions) (#63)
- Add upload bypass option for logScreen (#57)

## [2.6.1] - 2022-01-10

### Fixed

- Remove extra ProductActionType check (#59)
- Add custom attributes for ecommerce events (#58)

## [2.6.0] - 2021-09-22

### Fixed

- Remove deprecated jcenter references

## [2.5.0] - 2021-09-15

### Fixed

- Fix conditional around shouldUploadEvent (#51)
- Fix Boolean map customAttribute values crash on Android (#49)

## [2.4.13] - 2021-09-07

### Added

- Add shouldUploadEvent option for Android and iOS

## [2.4.12] - 2021-03-24

### Fixed

- Fix nullability issue for ATT timestamp

## [2.4.11] - 2021-03-23

### Changed

- Update UserIdentity enum

## [2.4.10] - 2021-03-17

### Added

- Add GetUserAttributes

## [2.4.9] - 2021-02-25

### Added

- Add ATT constants

## [2.4.8] - 2021-02-25

### Added

- ATT (App Tracking Transparency) support

## [2.4.7] - 2020-12-01

### Added

- Add error for invalid identities used in an identity request

## [2.4.6] - 2020-11-02

### Fixed

- Fix identity casting issue

## [2.4.5] - 2020-10-14

### Fixed

- Fix merge issue around getUserIdentities

## [2.4.4] - 2020-09-25

### Changed

- Update for iOS 14

## [2.4.3] - 2020-08-13

### Added

- Add CCPA support

## [2.4.2] - 2019-12-09

### Fixed

- Implement null check for session on iOS

## [2.4.1] - 2019-11-06

### Fixed

- Fix Android UserIdentities serialization

## [2.4.0] - 2019-10-21

### Added

- Add Consent State support for Android

## [2.3.3] - 2019-10-09

### Fixed

- Add null-check for Session object on Android

## [2.3.2] - 2019-09-26

### Fixed

- Add @ReactMethod decorator to getSession method

## [2.3.1] - 2019-08-27

### Added

- Implement getSession method

## [2.3.0] - 2019-07-09

### Added

- Implement Alias functionality

## [2.2.3] - 2019-06-18

### Fixed

- Use setUserAttributeList to set array values for iOS

## [2.2.2] - 2019-06-13

### Fixed

- Fix user identity conversion

## [2.2.1] - 2019-05-28

### Fixed

- Fix null User crash

## [2.2.0] - 2019-04-25

### Added

- Add Consent State support for iOS

## [2.1.3] - 2019-02-06

### Added

- Expose MParticleUser.incrementUserAttribute

## [2.1.2] - 2018-10-18

### Added

- Add react-native-mparticle.podspec

## [2.1.1] - 2018-08-25

### Fixed

- Fix IdentityType transformations

## [2.1.0] - 2018-07-27

### Added

- Add additional APIs for Attribution

### Fixed

- Fix Identity error cases

## [2.0.0] - 2018-03-19

Initial rewrite as a React Native module.

## [1.0.7] - 2018-02-27

### Changed

- Minor updates

## [1.0.6] - 2018-02-21

### Changed

- Minor updates

## [1.0.4] - 2017-11-28

### Changed

- Minor updates

## [1.0.3] - 2017-08-17

### Changed

- Initial release with core mParticle SDK integration

[Unreleased]: https://github.com/mParticle/react-native-mparticle/compare/2.8.1...HEAD
[2.8.1]: https://github.com/mParticle/react-native-mparticle/compare/2.8.0...2.8.1
[2.8.0]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.13...2.8.0
[2.7.13]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.12...v2.7.13
[2.7.12]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.11...v2.7.12
[2.7.11]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.10...v2.7.11
[2.7.10]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.9...v2.7.10
[2.7.9]: https://github.com/mParticle/react-native-mparticle/compare/2.7.8...v2.7.9
[2.7.8]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.7...2.7.8
[2.7.7]: https://github.com/mParticle/react-native-mparticle/compare/2.7.6...v2.7.7
[2.7.6]: https://github.com/mParticle/react-native-mparticle/compare/2.7.5...2.7.6
[2.7.5]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.4...2.7.5
[2.7.4]: https://github.com/mParticle/react-native-mparticle/compare/2.7.3...v2.7.4
[2.7.3]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.2...2.7.3
[2.7.2]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.1...v2.7.2
[2.7.1]: https://github.com/mParticle/react-native-mparticle/compare/v2.7.0...v2.7.1
[2.7.0]: https://github.com/mParticle/react-native-mparticle/compare/v2.6.2...v2.7.0
[2.6.2]: https://github.com/mParticle/react-native-mparticle/compare/v2.6.1...v2.6.2
[2.6.1]: https://github.com/mParticle/react-native-mparticle/compare/v2.6.0...v2.6.1
[2.6.0]: https://github.com/mParticle/react-native-mparticle/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.13...v2.5.0
[2.4.13]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.12...v2.4.13
[2.4.12]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.11...v2.4.12
[2.4.11]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.10...v2.4.11
[2.4.10]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.9...v2.4.10
[2.4.9]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.8...v2.4.9
[2.4.8]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.7...v2.4.8
[2.4.7]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.5...v2.4.7
[2.4.6]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.5...v2.4.7
[2.4.5]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.3...v2.4.5
[2.4.4]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.3...v2.4.5
[2.4.3]: https://github.com/mParticle/react-native-mparticle/compare/2.4.2...v2.4.3
[2.4.2]: https://github.com/mParticle/react-native-mparticle/compare/2.4.1...2.4.2
[2.4.1]: https://github.com/mParticle/react-native-mparticle/compare/v2.4.0...2.4.1
[2.4.0]: https://github.com/mParticle/react-native-mparticle/compare/v2.3.3...v2.4.0
[2.3.3]: https://github.com/mParticle/react-native-mparticle/compare/v2.3.2...v2.3.3
[2.3.2]: https://github.com/mParticle/react-native-mparticle/compare/2.3.1...v2.3.2
[2.3.1]: https://github.com/mParticle/react-native-mparticle/compare/2.3.0...2.3.1
[2.3.0]: https://github.com/mParticle/react-native-mparticle/compare/2.2.3...2.3.0
[2.2.3]: https://github.com/mParticle/react-native-mparticle/compare/2.2.2...2.2.3
[2.2.2]: https://github.com/mParticle/react-native-mparticle/compare/2.2.1...2.2.2
[2.2.1]: https://github.com/mParticle/react-native-mparticle/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/mParticle/react-native-mparticle/compare/2.1.3...2.2.0
[2.1.3]: https://github.com/mParticle/react-native-mparticle/compare/2.1.2...2.1.3
[2.1.2]: https://github.com/mParticle/react-native-mparticle/compare/2.1.1...2.1.2
[2.1.1]: https://github.com/mParticle/react-native-mparticle/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/mParticle/react-native-mparticle/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/mParticle/react-native-mparticle/compare/1.0.7...2.0.0
[1.0.7]: https://github.com/mParticle/react-native-mparticle/compare/1.0.6...1.0.7
[1.0.6]: https://github.com/mParticle/react-native-mparticle/compare/1.0.4...1.0.6
[1.0.4]: https://github.com/mParticle/react-native-mparticle/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/mParticle/react-native-mparticle/releases/tag/1.0.3

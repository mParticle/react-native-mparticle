import { applyMParticlePodfileMods } from '../../plugin/src/withMParticleIOS';
import type { MParticlePluginProps } from '../../plugin/src/withMParticle';

/**
 * The Expo config plugin's Podfile changes. `iosDependencyManager: 'cocoapods'` (the default)
 * must keep producing exactly what earlier releases produced; `'spm'` turns on the pod's Swift
 * Package Manager mode and calls ios/mparticle_spm.rb instead of adding pods.
 */

// The part of the Expo prebuild template the plugin touches.
const EXPO_PODFILE = `require File.join(File.dirname(\`node --print "require.resolve('expo/package.json')"\`), "scripts/autolinking")
platform :ios, podfile_properties['ios.deploymentTarget'] || '15.1'

prepare_react_native_project!

target 'MyApp' do
  use_expo_modules!
  config = use_native_modules!(config_command)

  use_react_native!(
    :path => config[:reactNativePath],
    :app_path => "#{Pod::Config.instance.installation_root}/..",
  )

  post_install do |installer|
    react_native_post_install(
      installer,
      config[:reactNativePath],
    )
  end
end
`;

const baseProps: MParticlePluginProps = {
  iosApiKey: 'key',
  iosApiSecret: 'secret',
  androidApiKey: 'key',
  androidApiSecret: 'secret',
  iosKits: ['mParticle-Rokt'],
};

const spmProps: MParticlePluginProps = {
  ...baseProps,
  iosDependencyManager: 'spm',
};

const ROKT_CALL =
  "    mparticle_spm_post_install(installer, kits: [{ url: 'https://github.com/mparticle-integrations/mp-apple-integration-rokt', product: 'mParticle-Rokt' }])";

describe('applyMParticlePodfileMods', () => {
  it('keeps the CocoaPods output unchanged', () => {
    expect(applyMParticlePodfileMods(EXPO_PODFILE, baseProps)).toBe(
      EXPO_PODFILE.replace(
        "'15.1'\n",
        `'15.1'

# mParticle dynamic framework linking (added by react-native-mparticle expo plugin)
pre_install do |installer|
  installer.pod_targets.each do |pod|
    if pod.name == 'mParticle-Apple-SDK' || pod.name == 'mParticle-Apple-SDK-ObjC' || pod.name == 'mParticle-Apple-SDK-Swift' || pod.name == 'mParticle-Rokt' || pod.name == 'Rokt-Widget' || pod.name == 'RoktContracts' || pod.name == 'RoktUXHelper' || pod.name == 'DcuiSchema'
      def pod.build_type;
        Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
      end
    end
  end
end
`
      ).replace(
        '  )\n\n  post_install',
        `  )

  # mParticle kits (added by react-native-mparticle expo plugin)
  pod 'mParticle-Rokt', '>= 9.3.1', '< 10.0'

  post_install`
      )
    );
  });

  it('sets the flag before the target, requires the helper and calls it in post_install', () => {
    const podfile = applyMParticlePodfileMods(EXPO_PODFILE, spmProps);

    expect(podfile).toBe(
      EXPO_PODFILE.replace(
        "target 'MyApp' do",
        `# mParticle Swift Package Manager mode (added by react-native-mparticle expo plugin)
$RNMParticleUseSPM = true
require File.join(File.dirname(\`node --print "require.resolve('react-native-mparticle/package.json')"\`.strip), 'ios', 'mparticle_spm')

target 'MyApp' do`
      ).replace(
        'post_install do |installer|\n',
        `post_install do |installer|\n${ROKT_CALL}\n`
      )
    );
    expect(podfile).not.toContain('pre_install');
    expect(podfile).not.toContain("pod 'mParticle-Rokt'");
  });

  it('passes the core version and extra kits through', () => {
    const podfile = applyMParticlePodfileMods(EXPO_PODFILE, {
      ...spmProps,
      iosSdkVersion: '9.6.1',
      iosSpmKits: [
        {
          url: 'https://github.com/example/kit',
          product: 'Example-Kit',
          version: '1.2.3',
        },
      ],
    });

    expect(podfile).toContain(
      "mparticle_spm_post_install(installer, core_version: '9.6.1', kits: [{ url: 'https://github.com/mparticle-integrations/mp-apple-integration-rokt', product: 'mParticle-Rokt' }, { url: 'https://github.com/example/kit', product: 'Example-Kit', version: '1.2.3' }])"
    );
  });

  it('is idempotent, and a rerun with new settings replaces the call', () => {
    const once = applyMParticlePodfileMods(EXPO_PODFILE, spmProps);
    expect(applyMParticlePodfileMods(once, spmProps)).toBe(once);

    const pinned = applyMParticlePodfileMods(once, {
      ...spmProps,
      iosSdkVersion: '9.7.0',
    });
    expect(pinned.match(/\$RNMParticleUseSPM = true/g)).toHaveLength(1);
    expect(pinned.match(/mparticle_spm_post_install\(/g)).toHaveLength(1);
    expect(pinned).toContain("core_version: '9.7.0'");
  });

  it('rejects an iosKits name with no known Swift package', () => {
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...spmProps,
        iosKits: ['mParticle-Amplitude'],
      })
    ).toThrow(/"mParticle-Amplitude" has no known Swift package.*iosSpmKits/);
  });

  it('rejects values that would break out of the generated Ruby string', () => {
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...spmProps,
        iosSdkVersion: "9.6.1'); system('echo",
      })
    ).toThrow(/invalid iosSdkVersion/);
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...spmProps,
        iosSpmKits: [{ url: 'http://example.com/kit', product: 'Kit' }],
      })
    ).toThrow(/invalid Swift package URL/);
  });

  it('rejects an unknown dependency manager', () => {
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...baseProps,
        iosDependencyManager: 'carthage' as 'spm',
      })
    ).toThrow(/must be "cocoapods" or "spm"/);
  });
});

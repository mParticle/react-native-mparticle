import * as fs from 'fs';
import * as path from 'path';
import { applyMParticlePodfileMods } from '../../plugin/src/withMParticleIOS';
import type { MParticlePluginProps } from '../../plugin/src/withMParticle';

/**
 * The Expo config plugin's Podfile changes. Swift Package Manager (the default) writes only the
 * settings ios/mparticle_spm.rb reads; `iosDependencyManager: 'cocoapods'` opts out and keeps
 * producing the pods and pre_install hook earlier releases produced.
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

const START =
  '# mParticle Swift Package Manager settings (added by react-native-mparticle expo plugin)';
const END = '# end of mParticle Swift Package Manager settings';

const baseProps: MParticlePluginProps = {
  iosApiKey: 'key',
  iosApiSecret: 'secret',
  androidApiKey: 'key',
  androidApiSecret: 'secret',
  iosKits: ['mParticle-Rokt'],
};

const cocoaPodsProps: MParticlePluginProps = {
  ...baseProps,
  iosDependencyManager: 'cocoapods',
};

function withSettings(...lines: string[]): string {
  return EXPO_PODFILE.replace(
    "target 'MyApp' do",
    `${[START, ...lines, END].join('\n')}\n\ntarget 'MyApp' do`
  );
}

describe('applyMParticlePodfileMods', () => {
  it('defaults to Swift Package Manager and writes only the kit settings', () => {
    const podfile = applyMParticlePodfileMods(EXPO_PODFILE, baseProps);

    expect(podfile).toBe(
      withSettings("$RNMParticleSPMKits = ['mParticle-Rokt']")
    );
    expect(podfile).not.toContain('pre_install');
    expect(podfile).not.toContain("pod 'mParticle-Rokt'");
  });

  it('writes an empty kit list when no kits are set', () => {
    expect(
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...baseProps,
        iosKits: undefined,
      })
    ).toBe(withSettings('$RNMParticleSPMKits = []'));
  });

  it('passes the core version and extra kits through', () => {
    const podfile = applyMParticlePodfileMods(EXPO_PODFILE, {
      ...baseProps,
      iosKits: ['mParticle-Rokt', 'mParticle-Braze-14'],
      iosSdkVersion: '9.6.1',
      iosSpmKits: [
        {
          url: 'https://github.com/example/kit',
          product: 'Example-Kit',
          version: '1.2.3',
        },
      ],
    });

    expect(podfile).toBe(
      withSettings(
        "$RNMParticleSPMKits = ['mParticle-Rokt', 'mParticle-Braze-14', { url: 'https://github.com/example/kit', product: 'Example-Kit', version: '1.2.3' }]",
        "$RNMParticleSPMCoreVersion = '9.6.1'"
      )
    );
  });

  it('is idempotent, and a rerun with new settings replaces them', () => {
    const once = applyMParticlePodfileMods(EXPO_PODFILE, baseProps);
    expect(applyMParticlePodfileMods(once, baseProps)).toBe(once);

    const pinned = applyMParticlePodfileMods(once, {
      ...baseProps,
      iosSdkVersion: '9.7.0',
    });
    expect(pinned.split(START)).toHaveLength(2);
    expect(pinned).toBe(
      withSettings(
        "$RNMParticleSPMKits = ['mParticle-Rokt']",
        "$RNMParticleSPMCoreVersion = '9.7.0'"
      )
    );
  });

  it('opts out with cocoapods and keeps the pods output', () => {
    expect(applyMParticlePodfileMods(EXPO_PODFILE, cocoaPodsProps)).toBe(
      withSettings('$RNMParticleDisableSPM = true')
        .replace(
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
        )
        .replace(
          '  )\n\n  post_install',
          `  )

  # mParticle kits (added by react-native-mparticle expo plugin)
  pod 'mParticle-Rokt', '>= 9.3.1', '< 10.0'

  post_install`
        )
    );
  });

  it('rejects an iosKits name with no known Swift package', () => {
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...baseProps,
        iosKits: ['mParticle-Amplitude'],
      })
    ).toThrow(
      /"mParticle-Amplitude" has no known Swift package.*iosSpmKits.*"cocoapods"/
    );
  });

  it('rejects a Swift-package-only kit with cocoapods', () => {
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...cocoaPodsProps,
        iosKits: ['mParticle-Kochava-9'],
      })
    ).toThrow(/mParticle-Kochava-9 ships only as a Swift package/);
  });

  it('rejects values that would break out of the generated Ruby string', () => {
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...baseProps,
        iosSdkVersion: "9.6.1'); system('echo",
      })
    ).toThrow(/invalid iosSdkVersion/);
    expect(() =>
      applyMParticlePodfileMods(EXPO_PODFILE, {
        ...baseProps,
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
    ).toThrow(/must be "spm" or "cocoapods"/);
  });
});

describe('ios/mparticle_spm_kits.json', () => {
  const table = JSON.parse(
    fs.readFileSync(
      path.join(__dirname, '..', '..', 'ios', 'mparticle_spm_kits.json'),
      'utf-8'
    )
  );

  it('gives every kit a GitHub package URL and a product the Podfile can quote', () => {
    for (const [name, kit] of Object.entries<{ url: string; product: string }>(
      table.kits
    )) {
      expect(`${name} ${kit.url}`).toMatch(
        /^[A-Za-z0-9._+-]+ https:\/\/github\.com\/[A-Za-z0-9._/-]+$/
      );
      expect(kit.url).not.toMatch(/\.git$/);
      expect(kit.product).toMatch(/^[A-Za-z0-9._+-]+$/);
    }
  });

  it('lists every Swift-package-only kit as a kit', () => {
    for (const name of table.swiftPackageOnly) {
      expect(table.kits).toHaveProperty([name]);
    }
  });
});

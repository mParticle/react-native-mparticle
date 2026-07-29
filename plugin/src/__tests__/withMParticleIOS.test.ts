import { addKitPodsToPodfile } from '../withMParticleIOS';

const basePodfile = `platform :ios, '15.6'

target 'MParticleExpoTest' do
  config = use_native_modules!

  use_react_native!(
    :path => config[:reactNativePath],
    :app_path => "#{Pod::Config.instance.installation_root}/.."
  )
end
`;

describe('addKitPodsToPodfile', () => {
  it('declares the kit and its companion Rokt-Widget floor', () => {
    const result = addKitPodsToPodfile(basePodfile, ['mParticle-Rokt']);

    expect(result).toContain("pod 'mParticle-Rokt', '~> 9.3'");
    expect(result).toContain("pod 'Rokt-Widget', '~> 5.3'");
  });

  it('adds a missing companion pod to a Podfile that already declares the kit', () => {
    const upgraded = basePodfile.replace(
      /(\)\n)/,
      "$1\n  pod 'mParticle-Rokt', '~> 9.2'\n"
    );

    const result = addKitPodsToPodfile(upgraded, ['mParticle-Rokt']);

    expect(result).toContain("pod 'Rokt-Widget', '~> 5.3'");
    expect(result.match(/pod 'mParticle-Rokt'/g)).toHaveLength(1);
  });

  it('leaves a Podfile untouched when every required pod is present', () => {
    const complete = addKitPodsToPodfile(basePodfile, ['mParticle-Rokt']);

    expect(addKitPodsToPodfile(complete, ['mParticle-Rokt'])).toBe(complete);
  });

  it('declares kits without a pinned version or companions', () => {
    const result = addKitPodsToPodfile(basePodfile, ['mParticle-Amplitude']);

    expect(result).toContain("pod 'mParticle-Amplitude'");
    expect(result).not.toContain('Rokt-Widget');
  });
});

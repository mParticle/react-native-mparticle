import * as fs from 'fs';
import * as path from 'path';

/**
 * The podspec compiles every file under ios/ by glob, but Package.swift lists the Objective-C++
 * target's sources by hand, and CI does not build that manifest. Keep the two in step.
 */
const root = path.join(__dirname, '..', '..');

it('lists every ios/RNMParticle source in Package.swift', () => {
  const manifest = fs.readFileSync(path.join(root, 'Package.swift'), 'utf-8');
  const listed = new Set(
    [...manifest.matchAll(/"(ios\/RNMParticle\/[^"]+\.(?:h|m|mm))"/g)].map(
      match => match[1]
    )
  );
  const onDisk = fs
    .readdirSync(path.join(root, 'ios', 'RNMParticle'), { recursive: true })
    .map(String)
    .filter(file => /\.(h|m|mm)$/.test(file))
    .map(file => `ios/RNMParticle/${file}`);

  expect([...listed].sort()).toEqual(onDisk.sort());
});

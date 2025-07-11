#!/bin/bash
set -e

echo "🔨 Building..."
yarn build

echo "📦 Packing..."
yarn pack --filename react-native-mparticle-latest.tgz

echo "🔄 Updating sample..."
cd sample
rm -rf node_modules/react-native-mparticle
tar -xzf ../react-native-mparticle-latest.tgz
mv package node_modules/react-native-mparticle

echo "✅ Done! Sample updated with latest changes." 
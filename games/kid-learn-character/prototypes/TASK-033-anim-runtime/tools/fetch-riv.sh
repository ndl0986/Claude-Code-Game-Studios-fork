#!/bin/sh
# PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
# Fetches the placeholder Rive files at build time (not committed). Source: rive-app/rive-ios at tag 6.30.1,
# MIT licence (https://github.com/rive-app/rive-ios/blob/6.30.1/LICENSE). Pinned by tag and checked by SHA-256.
set -eu
cd "$(dirname "$0")/.."
mkdir -p rivassets
base=https://raw.githubusercontent.com/rive-app/rive-ios/6.30.1
curl -sSLf -o rivassets/mascot.riv "$base/Example-iOS/Assets/mascot.riv"
curl -sSLf -o rivassets/hosted_assets.riv "$base/Tests/Assets/hosted_assets.riv"
curl -sSLf -o rivassets/LICENSE-rive-ios.txt "$base/LICENSE"
shasum -a 256 rivassets/*.riv

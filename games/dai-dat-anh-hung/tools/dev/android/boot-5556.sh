#!/bin/zsh
# Boots game-dev-android's own emulator (devandroid002 on port 5556), headless. Never used for QC's mp17863 (5554).
exec ~/Android/sdk/emulator/emulator -avd devandroid002 -port 5556 -no-window -no-audio -no-boot-anim -no-snapshot-save

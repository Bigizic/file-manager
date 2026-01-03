#!/bin/bash

# Script to clean Xcode build artifacts and derived data
# This helps fix Xcode crashes and build issues

echo "🧹 Cleaning Xcode build artifacts..."

# 1. Clean DerivedData (main build cache location)
echo "📦 Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. Clean project-specific user data
echo "📁 Cleaning project user data..."
cd "$(dirname "$0")"
rm -rf fileManager.xcodeproj/xcuserdata
rm -rf fileManager.xcodeproj/project.xcworkspace/xcuserdata
rm -rf fileManager.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/configuration

# 3. Clean module cache
echo "🔧 Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# 4. Clean archives (if any)
echo "📦 Cleaning archives..."
rm -rf ~/Library/Developer/Xcode/Archives/*

# 5. Clean device support files (optional, can be large)
echo "📱 Cleaning device support (optional)..."
# Uncomment the next line if you want to clean device support files too
# rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*

# 6. Clean Swift Package Manager cache
echo "📚 Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm

echo "✅ Cleanup complete!"
echo ""
echo "Xcode build data locations:"
echo "  • DerivedData: ~/Library/Developer/Xcode/DerivedData/"
echo "  • Archives: ~/Library/Developer/Xcode/Archives/"
echo "  • Device Support: ~/Library/Developer/Xcode/iOS DeviceSupport/"
echo "  • Module Cache: ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
echo ""
echo "Now try opening the project in Xcode again."


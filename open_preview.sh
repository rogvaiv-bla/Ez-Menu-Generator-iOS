#!/bin/bash

# Ez Menu Generator - Preview Launcher
# This script opens Xcode with ContentView.swift and Canvas Preview enabled

PROJECT_PATH="/Users/eduard/Downloads/Ez Menu Generator"
PROJECT_FILE="Ez Menu Generator.xcodeproj"

echo "🚀 Starting Xcode Canvas Preview..."
echo ""
echo "📂 Project: $PROJECT_PATH"
echo ""

# Open Xcode with the project
open -a Xcode "$PROJECT_PATH/$PROJECT_FILE"

echo "✅ Xcode is opening..."
echo ""
echo "📝 Next steps:"
echo "1. Wait for Xcode to fully load (10-15 seconds)"
echo "2. Click on: ContentView.swift (or HouseholdOnboardingView.swift)"
echo "3. Press: ⌥ + ⌘ + ↩ (or use menu: Editor → Canvas)"
echo ""
echo "💡 Tip: Once Canvas opens, edits in the file will update preview in real-time!"
echo ""

# Optional: Open Canvas automatically after delay
# Uncomment the line below if you want automatic Canvas activation
# sleep 10 && osascript -e 'tell application "Xcode" to activate' \
#     -e 'tell application "System Events" to keystroke return using {command down, option down}'

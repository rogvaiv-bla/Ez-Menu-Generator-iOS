#!/usr/bin/env osascript

-- Ez Menu Generator - Open Xcode with Canvas Preview

tell application "Xcode"
    activate
    
    -- Open the project
    open "/Users/eduard/Downloads/Ez Menu Generator/Ez Menu Generator.xcodeproj"
    
    -- Wait for Xcode to fully load
    delay 3
    
    -- Try to open ContentView.swift
    tell application "System Events"
        keystroke "o" using command down
        delay 1
        
        -- Type filename
        keystroke "ContentView.swift"
        delay 0.5
        
        -- Press Enter to open
        key code 36 -- Return key
        delay 1
        
        -- Enable Canvas (Option + Cmd + Return)
        keystroke return using {command down, option down}
    end tell
    
end tell

display notification "✅ Canvas Preview activated!" with title "Ez Menu Generator" subtitle "Open Xcode to see live preview"

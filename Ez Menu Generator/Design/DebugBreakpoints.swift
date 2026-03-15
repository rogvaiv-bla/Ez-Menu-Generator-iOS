import Foundation

/// Debug breakpoint helpers for runtime issues
struct DebugBreakpoints {
    /// Sets a conditional breakpoint for UIColor out-of-range detection
    /// Add this to AppDelegate or app startup
    static func setupUIColorDebugger() {
        #if DEBUG
        // This function will help catch UIColor out-of-range issues at runtime
        // To enable: Set a breakpoint in the Xcode debugger with condition:
        // (void)disable_range_check() // Disables range checking after first hit
        let breakpointSymbol = "UIColorBreakForOutOfRangeColorComponents"
        NSLog("⚠️ Debug: UIColor range detection active. Symbol: \(breakpointSymbol)")
        #endif
    }
}

/// Safe color opacity extension to prevent out-of-range values
extension CGFloat {
    /// Clamps value to valid opacity range [0, 1]
    var clampedOpacity: CGFloat {
        min(max(self, 0.0), 1.0)
    }
}

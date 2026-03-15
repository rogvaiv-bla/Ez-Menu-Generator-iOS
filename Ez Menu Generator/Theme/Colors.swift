import SwiftUI

/// REDESIGN 2.0 - Dark Mode First Color System
/// All colors optimized for dark mode (#0A0E27 background)
/// Minimum contrast: 4.5:1 (WCAG AA)
struct EzColors {
    
    // MARK: - Background Colors
    struct Background {
        /// Primary background (#0A0E27)
        static let primary = Color(red: 0.039, green: 0.055, blue: 0.153)
        
        /// Secondary background - cards, elevated (#1A1F3A)
        static let secondary = Color(red: 0.102, green: 0.122, blue: 0.227)
        
        /// Tertiary background - subtle elevation (#2D3250)
        static let tertiary = Color(red: 0.176, green: 0.196, blue: 0.314)
        
        /// Surface - borders, dividers (#3D4563)
        static let surface = Color(red: 0.239, green: 0.271, blue: 0.388)
    }
    
    // MARK: - Text Colors
    struct Text {
        /// Primary text (#FFFFFF)
        static let primary = Color(red: 1.0, green: 1.0, blue: 1.0)
        
        /// Secondary text - captions, hints (#B4BAC4)
        static let secondary = Color(red: 0.706, green: 0.729, blue: 0.769)
        
        /// Tertiary text - disabled, collapsed (#7A8196)
        static let tertiary = Color(red: 0.478, green: 0.506, blue: 0.588)
    }
    
    // MARK: - Accent Colors
    struct Accent {
        /// Primary action color (#7C5CFF)
        static let primary = Color(red: 0.486, green: 0.361, blue: 1.0)
        
        /// Success / positive (#00D476)
        static let success = Color(red: 0.0, green: 0.831, blue: 0.463)
        
        /// Warning / caution (#FFB84D)
        static let warning = Color(red: 1.0, green: 0.722, blue: 0.302)
        
        /// Danger / destructive (#FF6B6B)
        static let danger = Color(red: 1.0, green: 0.420, blue: 0.420)
    }
    
    // MARK: - Nutrition Score Colors
    struct NutritionScore {
        /// Score 80-100: Excellent (#00D476)
        static let excellent = Color(red: 0.0, green: 0.831, blue: 0.463)
        
        /// Score 60-79: Good (#4ECB71)
        static let good = Color(red: 0.306, green: 0.796, blue: 0.443)
        
        /// Score 40-59: Fair (#FFD93D)
        static let fair = Color(red: 1.0, green: 0.851, blue: 0.239)
        
        /// Score 20-39: Poor (#FFB84D)
        static let poor = Color(red: 1.0, green: 0.722, blue: 0.302)
        
        /// Score <20: Very Poor (#FF6B6B)
        static let veryPoor = Color(red: 1.0, green: 0.420, blue: 0.420)
        
        static func color(for score: Int) -> Color {
            switch score {
            case 80...100: return excellent
            case 60..<80: return good
            case 40..<60: return fair
            case 20..<40: return poor
            default: return veryPoor
            }
        }
    }
    
    // MARK: - Eco Score Colors
    struct EcoScore {
        /// A: Excellent (#00D476)
        static let a = Color(red: 0.0, green: 0.831, blue: 0.463)
        
        /// B: Good (#4ECB71)
        static let b = Color(red: 0.306, green: 0.796, blue: 0.443)
        
        /// C: Fair (#FFD93D)
        static let c = Color(red: 1.0, green: 0.851, blue: 0.239)
        
        /// D: Poor (#FFB84D)
        static let d = Color(red: 1.0, green: 0.722, blue: 0.302)
        
        /// E: Very Poor (#FF6B6B)
        static let e = Color(red: 1.0, green: 0.420, blue: 0.420)
        
        static func color(for grade: String) -> Color {
            switch grade.uppercased() {
            case "A": return a
            case "B": return b
            case "C": return c
            case "D": return d
            case "E": return e
            default: return c
            }
        }
    }
    
    // MARK: - Category Colors (from existing, kept for backward compatibility)
    static let categoryColors: [String: Color] = [
        "Legume / Fructe 🥕🍎": Color(red: 0.2, green: 0.8, blue: 0.4),
        "Lactate și ouă 🧈🥚": Color(red: 0.9, green: 0.9, blue: 0.3),
        "Carne 🥩": Color(red: 0.8, green: 0.2, blue: 0.2),
        "Gospodarie 🧹": Color(red: 0.5, green: 0.5, blue: 0.5),
        "Ingrijire personală 🧴": Color(red: 0.4, green: 0.8, blue: 0.9),
        "Farmacie 💊": Color(red: 0.8, green: 0.3, blue: 0.6),
        "Băuturi 🥤": Color(red: 1.0, green: 0.7, blue: 0.2),
        "Brutarie 🍞": Color(red: 0.8, green: 0.6, blue: 0.2),
        "Pește 🐟": Color(red: 0.2, green: 0.6, blue: 0.8),
        "Cămară 🏠": Color(red: 0.6, green: 0.4, blue: 0.2),
        "Dulciuri 🍫": Color(red: 0.9, green: 0.5, blue: 0.7),
        "De îmbrăcat 👕": Color(red: 0.6, green: 0.3, blue: 0.8),
        "Altele ❓": Color.gray
    ]
}

// MARK: - Legacy Compatibility (deprecated, will be removed in v2.0)
extension Color {
    /// Backward compatibility - maps to new system
    static func ezBackground() -> Color {
        EzColors.Background.primary
    }
    
    static func ezCardBackground() -> Color {
        EzColors.Background.secondary
    }
    
    static func ezText() -> Color {
        EzColors.Text.primary
    }
    
    static func ezTextSecondary() -> Color {
        EzColors.Text.secondary
    }
    
    static func ezAccent() -> Color {
        EzColors.Accent.primary
    }
}

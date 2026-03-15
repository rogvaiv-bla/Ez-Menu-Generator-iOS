import SwiftUI
import UIKit

/// REDESIGN 3.0 - Haptic Feedback Manager
/// Provides tactile feedback following Apple HIG
/// Used for user actions, errors, and success confirmations

enum HapticManager {
    
    // MARK: - Impact Feedback
    
    /// Light impact for subtle interactions (toggle, checkbox)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact for standard interactions (button tap, card selection)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact for significant actions (delete, archive)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Rigid impact for precise actions (drag & drop, picker selection)
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// Soft impact for gentle actions (swipe, scroll)
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success feedback (item saved, action completed)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback (destructive action confirmation needed)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback (operation failed, validation error)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection change feedback (picker, segmented control)
    static func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Context-Specific Presets
    
    struct Context {
        /// Button tap (primary, secondary, tertiary)
        static func buttonTap(style: EzButtonStyle) {
            switch style {
            case .primary, .success:
                medium()
            case .danger:
                warning()
            case .secondary, .tertiary:
                light()
            }
        }
        
        /// Toggle switch changed
        static func toggle() {
            light()
        }
        
        /// Checkbox marked/unmarked
        static func checkbox() {
            light()
        }
        
        /// Item deleted
        static func delete() {
            heavy()
            // Add a small delay then warning for confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                warning()
            }
        }
        
        /// Item saved successfully
        static func saved() {
            success()
        }
        
        /// Network error occurred
        static func networkError() {
            error()
        }
        
        /// Validation error
        static func validationError() {
            warning()
        }
        
        /// Swipe action triggered
        static func swipeAction() {
            rigid()
        }
        
        /// Drag started
        static func dragStart() {
            rigid()
        }
        
        /// Item dropped
        static func drop() {
            medium()
        }
        
        /// Long press recognized
        static func longPress() {
            medium()
        }
        
        /// Picker value changed
        static func pickerChange() {
            selectionChanged()
        }
        
        /// Sheet/modal presented
        static func modalPresent() {
            light()
        }
        
        /// Sheet/modal dismissed
        static func modalDismiss() {
            light()
        }
    }
}

// MARK: - Usage Examples

/*
 
 // BUTTON TAP
 Button("Delete") {
     HapticManager.Context.delete()
     deleteItem()
 }
 
 // TOGGLE
 Toggle("Enable notifications", isOn: $isEnabled)
     .onChange(of: isEnabled) { _ in
         HapticManager.Context.toggle()
     }
 
 // CHECKBOX
 Button(action: {
     HapticManager.Context.checkbox()
     item.isChecked.toggle()
 }) {
     Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
 }
 
 // SAVE SUCCESS
 func saveRecipe() {
     // Save logic...
     HapticManager.Context.saved()
     showSuccessToast = true
 }
 
 // NETWORK ERROR
 func fetchData() {
     // Network request...
     if error {
         HapticManager.Context.networkError()
         showErrorAlert = true
     }
 }
 
 // SWIPE ACTION
 .swipeActions {
     Button(role: .destructive) {
         HapticManager.Context.swipeAction()
         deleteItem()
     } label: {
         Label("Delete", systemImage: "trash")
     }
 }
 
 */

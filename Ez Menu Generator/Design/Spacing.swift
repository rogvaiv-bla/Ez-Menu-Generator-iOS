import SwiftUI

/// REDESIGN 2.0 - Spacing System
/// Base unit: 8px
/// All spacing values are multiples of 8
struct EzSpacing {
    
    /// 4px - Icon padding, tight spacing (0.5 × base)
    static let xs: CGFloat = 4
    
    /// 8px - Base unit (1 × base)
    /// Component padding, badge spacing, small gaps
    static let sm: CGFloat = 8
    
    /// 12px - Medium component spacing (1.5 × base)
    static let base: CGFloat = 12
    
    /// 16px - Standard medium spacing (2 × base)
    /// Card padding, icon-text gap, section internal spacing
    static let md: CGFloat = 16
    
    /// 20px - Large component spacing (2.5 × base)
    static let lg: CGFloat = 20
    
    /// 24px - Major section spacing (3 × base)
    /// Section margins, card vertical spacing
    static let xl: CGFloat = 24
    
    /// 32px - Extra large inter-section gaps (4 × base)
    /// Between major sections, top/bottom padding
    static let xxl: CGFloat = 32
    
    /// 40px - Screen edge spacing (5 × base)
    static let screen: CGFloat = 40
    
    // MARK: - Named Spacing Groups
    
    /// Card & Component Spacing
    struct Component {
        /// Padding inside cards/containers
        static let padding: CGFloat = EzSpacing.md // 16
        
        /// Gap between icon and text
        static let iconTextGap: CGFloat = EzSpacing.sm // 8
        
        /// Vertical spacing between fields
        static let fieldGap: CGFloat = EzSpacing.md // 16
        
        /// Horizontal spacing in H stacks
        static let horizontalGap: CGFloat = EzSpacing.sm // 8
    }
    
    /// Section Spacing
    struct Section {
        /// Top/bottom padding of sections
        static let padding: CGFloat = EzSpacing.xl // 24
        
        /// Gap between sections
        static let gap: CGFloat = EzSpacing.xxl // 32
        
        /// Divider padding
        static let dividerPadding: CGFloat = EzSpacing.md // 16
    }
    
    /// List & Grid Spacing
    struct List {
        /// Vertical gap between items
        static let itemGap: CGFloat = EzSpacing.sm // 8
        
        /// Horizontal gap in grids
        static let columnGap: CGFloat = EzSpacing.md // 16
        
        /// Edge margins
        static let edgeMargin: CGFloat = EzSpacing.md // 16
    }
    
    /// Bottom Sheet & Modal Spacing
    struct Modal {
        /// Top padding from safe area
        static let topPadding: CGFloat = EzSpacing.xl // 24
        
        /// Horizontal padding
        static let horizontalPadding: CGFloat = EzSpacing.md // 16
        
        /// Bottom padding (with buttons)
        static let bottomPadding: CGFloat = EzSpacing.xl // 24
        
        /// Button height
        static let buttonHeight: CGFloat = 48
        
        /// Gap between buttons
        static let buttonGap: CGFloat = EzSpacing.sm // 8
    }
    
    /// Card-specific Spacing
    struct Card {
        /// External padding
        static let externalPadding: CGFloat = EzSpacing.md // 16
        
        /// Internal tight gaps
        static let tightGap: CGFloat = EzSpacing.sm // 8
        
        /// Internal medium gaps
        static let mediumGap: CGFloat = EzSpacing.base // 12
        
        /// Corner radius
        static let cornerRadius: CGFloat = 12
        
        /// Shadow elevation
        static let shadowRadius: CGFloat = 8
        static let shadowY: CGFloat = 2
    }
    
    /// Navigation Bar Spacing
    struct NavigationBar {
        /// Height
        static let height: CGFloat = 56
        
        /// Horizontal padding
        static let horizontalPadding: CGFloat = EzSpacing.md // 16
        
        /// Title/icon gaps
        static let elementGap: CGFloat = EzSpacing.sm // 8
    }
    
    /// Tab Bar Spacing
    struct TabBar {
        /// Height
        static let height: CGFloat = 60
        
        /// Icon size
        static let iconSize: CGFloat = 24
        
        /// Label font size
        static let labelFontSize: CGFloat = 10
        
        /// Vertical gap between icon and label
        static let iconLabelGap: CGFloat = EzSpacing.xs // 4
    }
}

// MARK: - Convenient Extensions

extension View {
    /// Apply standard section padding
    func sectionPadding() -> some View {
        padding(.vertical, EzSpacing.Section.padding)
            .padding(.horizontal, EzSpacing.Component.padding)
    }
    
    /// Apply card padding
    func cardPadding() -> some View {
        padding(EzSpacing.Card.externalPadding)
    }
    
    /// Apply modal padding
    func modalPadding() -> some View {
        padding(.top, EzSpacing.Modal.topPadding)
            .padding(.horizontal, EzSpacing.Modal.horizontalPadding)
            .padding(.bottom, EzSpacing.Modal.bottomPadding)
    }
}

// MARK: - Convenience Extensions (Note: Can't extend HStack/VStack directly)
// Instead, use spacing parameter when creating:
// HStack(spacing: EzSpacing.Component.horizontalGap) { ... }
// VStack(spacing: EzSpacing.Component.fieldGap) { ... }

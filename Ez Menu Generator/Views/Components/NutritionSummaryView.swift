import SwiftUI

/// Displays nutrition information in a beautiful, scannable format
/// Shows calories, protein, carbs, fat with visual progress indicators
struct NutritionSummaryView: View {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    var displayMode: DisplayMode = .pills
    
    enum DisplayMode {
        case pills        // Individual pills in a row
        case row          // Horizontal bar layout
        case grid         // 2x2 grid
        case compact      // Single line
    }
    
    var body: some View {
        switch displayMode {
        case .pills:
            pillsLayout
        case .row:
            rowLayout
        case .grid:
            gridLayout
        case .compact:
            compactLayout
        }
    }
    
    // MARK: - Pills Layout (Default - most elegant)
    private var pillsLayout: some View {
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Nutrition per serving")
                .font(EzTypography.Label.font)
                .foregroundColor(EzColors.Text.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            HStack(spacing: EzSpacing.md) {
                NutritionPill(
                    label: "Calories",
                    value: "\(calories)",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange,
                    progress: min(Double(calories) / 2000, 1.0)
                )
                
                NutritionPill(
                    label: "Protein",
                    value: String(format: "%.1f", protein),
                    unit: "g",
                    icon: "bolt.fill",
                    color: .red,
                    progress: min(protein / 50, 1.0)
                )
                
                NutritionPill(
                    label: "Carbs",
                    value: String(format: "%.1f", carbs),
                    unit: "g",
                    icon: "sparkles",
                    color: .cyan,
                    progress: min(carbs / 300, 1.0)
                )
                
                NutritionPill(
                    label: "Fat",
                    value: String(format: "%.1f", fat),
                    unit: "g",
                    icon: "drop.fill",
                    color: .yellow,
                    progress: min(fat / 70, 1.0)
                )
            }
        }
    }
    
    // MARK: - Row Layout
    private var rowLayout: some View {
        VStack(alignment: .leading, spacing: EzSpacing.sm) {
            Text("Nutrition Summary")
                .font(EzTypography.Label.font)
                .foregroundColor(EzColors.Text.secondary)
            
            VStack(spacing: EzSpacing.sm) {
                NutritionRow(label: "Calories", value: "\(calories) kcal", color: .orange)
                NutritionRow(label: "Protein", value: String(format: "%.1f g", protein), color: .red)
                NutritionRow(label: "Carbs", value: String(format: "%.1f g", carbs), color: .cyan)
                NutritionRow(label: "Fat", value: String(format: "%.1f g", fat), color: .yellow)
            }
        }
    }
    
    // MARK: - Grid Layout
    private var gridLayout: some View {
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Nutrition Facts")
                .font(EzTypography.Label.font)
                .foregroundColor(EzColors.Text.secondary)
            
            HStack(spacing: EzSpacing.md) {
                NutritionGridItem(
                    label: "Calories",
                    value: "\(calories)",
                    unit: "kcal",
                    color: .orange
                )
                NutritionGridItem(
                    label: "Protein",
                    value: String(format: "%.0f", protein),
                    unit: "g",
                    color: .red
                )
            }
            
            HStack(spacing: EzSpacing.md) {
                NutritionGridItem(
                    label: "Carbs",
                    value: String(format: "%.0f", carbs),
                    unit: "g",
                    color: .cyan
                )
                NutritionGridItem(
                    label: "Fat",
                    value: String(format: "%.0f", fat),
                    unit: "g",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Compact Layout
    private var compactLayout: some View {
        HStack(spacing: EzSpacing.md) {
            Label("\(calories) kcal", systemImage: "flame.fill")
                .font(EzTypography.Body.font)
                .foregroundColor(EzColors.Text.primary)
            
            Divider()
                .frame(height: 20)
            
            Label(String(format: "%.0fg P", protein), systemImage: "bolt.fill")
                .font(EzTypography.Body.font)
                .foregroundColor(EzColors.Text.primary)
            
            Divider()
                .frame(height: 20)
            
            Label(String(format: "%.0fg C", carbs), systemImage: "sparkles")
                .font(EzTypography.Body.font)
                .foregroundColor(EzColors.Text.primary)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

/// Individual nutrition pill with icon and progress
struct NutritionPill: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(spacing: EzSpacing.xs) {
            HStack(spacing: EzSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(label)
                    .font(EzTypography.Label.font)
                    .foregroundColor(EzColors.Text.secondary)
            }
            
            Text(value)
                .font(EzTypography.Title.font)
                .foregroundColor(EzColors.Text.primary)
                .lineLimit(1)
            
            Text(unit)
                .font(EzTypography.Helper.font)
                .foregroundColor(EzColors.Text.tertiary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(EzColors.Background.tertiary)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.8))
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)
        }
        .padding(EzSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(EzColors.Background.tertiary)
        )
    }
}

/// Row-based nutrition display
struct NutritionRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: EzSpacing.sm) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(EzTypography.Body.font)
                    .foregroundColor(EzColors.Text.primary)
            }
            
            Spacer()
            
            Text(value)
                .font(EzTypography.Title.font)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .padding(EzSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(EzColors.Background.tertiary)
        )
    }
}

/// Grid-based nutrition item
struct NutritionGridItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: EzSpacing.sm) {
            Text(value)
                .font(EzTypography.Display.font)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(label)
                    .font(EzTypography.Label.font)
                    .foregroundColor(EzColors.Text.primary)
                
                Text(unit)
                    .font(EzTypography.Helper.font)
                    .foregroundColor(EzColors.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(EzSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(EzColors.Background.tertiary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: EzSpacing.xl) {
        Text("Nutrition Summary Views")
            .font(EzTypography.Display.font)
            .foregroundColor(EzColors.Text.primary)
            .padding(.horizontal, EzSpacing.lg)
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Pills Layout (Default)")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
                .padding(.horizontal, EzSpacing.lg)
            
            NutritionSummaryView(
                calories: 450,
                protein: 25.5,
                carbs: 45.2,
                fat: 12.8,
                displayMode: .pills
            )
            .padding(EzSpacing.lg)
            .premiumCard()
        }
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Row Layout")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
                .padding(.horizontal, EzSpacing.lg)
            
            NutritionSummaryView(
                calories: 320,
                protein: 18.3,
                carbs: 38.5,
                fat: 8.2,
                displayMode: .row
            )
            .padding(EzSpacing.lg)
            .premiumCard()
        }
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Grid Layout")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
                .padding(.horizontal, EzSpacing.lg)
            
            NutritionSummaryView(
                calories: 580,
                protein: 32.0,
                carbs: 62.1,
                fat: 18.5,
                displayMode: .grid
            )
            .padding(EzSpacing.lg)
            .premiumCard()
        }
        
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Compact Layout")
                .font(EzTypography.Headline.font)
                .foregroundColor(EzColors.Text.secondary)
                .padding(.horizontal, EzSpacing.lg)
            
            NutritionSummaryView(
                calories: 400,
                protein: 22.0,
                carbs: 40.0,
                fat: 14.0,
                displayMode: .compact
            )
            .padding(EzSpacing.lg)
            .premiumCard()
        }
        
        Spacer()
    }
    .padding(EzSpacing.lg)
    .background(EzColors.Background.primary.ignoresSafeArea())
}

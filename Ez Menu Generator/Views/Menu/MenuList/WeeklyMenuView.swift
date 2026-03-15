import SwiftUI

/// Weekly menu planning view with daily cards and stats
struct WeeklyMenuView: View {
    let menu: Menu
    let onEditMenu: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: EzSpacing.md) {
            // Weekly Stats Widget
            WeeklyStatsWidget(menu: menu)
                .padding(EzSpacing.md)
            
            // Weekly Grid
            ScrollView {
                VStack(spacing: EzSpacing.md) {
                    // Days grid in 2-column layout for better mobile view
                    ForEach(Array(stride(from: 0, to: menu.meals.count, by: 2)), id: \.self) { firstDayIndex in
                        HStack(spacing: EzSpacing.md) {
                            // First day of row
                            if firstDayIndex < menu.meals.count {
                                DailyMealCard(
                                    dayIndex: firstDayIndex,
                                    dayMeals: menu.meals[firstDayIndex],
                                    onTap: onEditMenu
                                )
                                .frame(maxWidth: .infinity)
                            }
                            
                            // Second day of row
                            if firstDayIndex + 1 < menu.meals.count {
                                DailyMealCard(
                                    dayIndex: firstDayIndex + 1,
                                    dayMeals: menu.meals[firstDayIndex + 1],
                                    onTap: onEditMenu
                                )
                                .frame(maxWidth: .infinity)
                            } else {
                                Spacer(minLength: 0)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(EzSpacing.md)
            }
        }
        .background(EzColors.Background.primary)
    }
}

#Preview {
    WeeklyMenuView(menu: Menu(name: "Sample Menu", weekStartDate: Date()), onEditMenu: {})
        .background(EzColors.Background.primary)
}

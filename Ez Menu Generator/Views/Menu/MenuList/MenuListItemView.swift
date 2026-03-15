import SwiftUI

struct MenuListItemView: View {
    let menu: Menu
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(menu.name)
                        .headlineStyle()
                    Text(menu.weekStartDate.formatted(date: .abbreviated, time: .omitted))
                        .helperStyle()
                }
                Spacer()
            }
            
            // 7-day preview
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 2) {
                        Text(["L", "M", "M", "J", "V", "S", "D"][day])
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Circle()
                            .fill(hasRecipeForDay(day) ? EzColors.Accent.primary : EzColors.Background.tertiary.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func hasRecipeForDay(_ day: Int) -> Bool {
        guard day >= 0 && day < menu.meals.count else { return false }
        let dayMeal = menu.meals[day]
        return dayMeal.breakfast != nil || dayMeal.lunch != nil || dayMeal.dinner != nil
    }
}

#Preview {
    let menu = Menu(name: "Săptămâna 1", weekStartDate: Date())
    MenuListItemView(menu: menu)
}

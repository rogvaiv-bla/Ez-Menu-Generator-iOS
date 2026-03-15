//
//  ContentView.swift
//  Ez Menu Generator
//
//  Created by eduard on 29/01/2026.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Navigation Section Enum

enum AppSection: Int, CaseIterable, Identifiable {
    case home = 0
    case recipes = 1
    case shopping = 2
    case analyze = 3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .recipes: return "Recipes"
        case .shopping: return "Shop"
        case .analyze: return "Analyze"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "calendar.circle.fill"
        case .recipes: return "book.fill"
        case .shopping: return "cart.fill"
        case .analyze: return "magnifyingglass.circle.fill"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .home: return "Tab: Home - Weekly Menu Planning"
        case .recipes: return "Tab: Recipes Library"
        case .shopping: return "Tab: Shopping List"
        case .analyze: return "Tab: Product Analyzer"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("selectedTab") private var selectedTab: Int = 0
    @State private var isReady = false
    @State private var selectedSection: AppSection = .home
    
    @EnvironmentObject private var householdManager: HouseholdManager
    @StateObject private var menuListViewModel = MenuListViewModel()
    @StateObject private var recipeListViewModel = RecipeListViewModel()
    @StateObject private var shoppingListViewModel = ShoppingListViewModel()
    @State private var showProductSearch = false
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            // If household not set, show onboarding
            if householdManager.currentHousehold == nil {
                HouseholdOnboardingView()
            } else if isReady {
                // Adaptive layout: iPad uses NavigationSplitView, iPhone uses TabView
                if isIPad {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            } else {
                LoadingStateView(message: "Se încarcă...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(EzColors.Background.primary)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
            
            await MainActor.run {
                recipeListViewModel.fetchRecipes()
                shoppingListViewModel.fetchItems()
                menuListViewModel.fetchMenus()
                isReady = true
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            selectedSection = AppSection(rawValue: newValue) ?? .home
        }
        .preferredColorScheme(.dark)  // Force dark mode globally to prevent UIColor theme-switching issues
    }
    
    // MARK: - iPad Layout (NavigationSplitView)
    
    @ViewBuilder
    var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar
            List {
                ForEach(AppSection.allCases) { section in
                    Button(action: {
                        selectedSection = section
                    }) {
                        HStack {
                            Label(section.title, systemImage: section.icon)
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                            if selectedSection == section {
                                Image(systemName: "checkmark")
                                    .foregroundColor(EzColors.Accent.primary)
                            }
                        }
                    }
                    .listRowBackground(
                        selectedSection == section 
                            ? EzColors.Accent.primary.opacity(0.1)
                            : Color.clear
                    )
                    .accessibilityLabel(section.accessibilityLabel)
                }
            }
            .navigationTitle("Ez Menu")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.sidebar)
            .frame(minWidth: 200)
        } detail: {
            // Detail view based on selection
            switch selectedSection {
            case .home:
                MenuListView()
                    .environmentObject(menuListViewModel)
            case .recipes:
                NavigationStack {
                    RecipeListView()
                        .environmentObject(recipeListViewModel)
                }
            case .shopping:
                ShoppingListView()
                    .environmentObject(shoppingListViewModel)
            case .analyze:
                AnalyzeView()
            }
        }
        .accentColor(EzColors.Accent.primary)
        .onChange(of: selectedSection) { _, newValue in
            selectedTab = newValue.rawValue
        }
    }
    
    // MARK: - iPhone Layout (Premium TabView)
    
    @ViewBuilder
    var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // TAB 0: HOME - Weekly Planning Hub
                MenuListView()
                    .environmentObject(menuListViewModel)
                    .tag(0)
                
                // TAB 1: RECIPES - Discovery + Library
                NavigationStack {
                    RecipeListView()
                        .environmentObject(recipeListViewModel)
                }
                .tag(1)
                
                // TAB 2: SHOP - Collaborative Shopping List
                ShoppingListView()
                    .environmentObject(shoppingListViewModel)
                    .tag(2)
                
                // TAB 3: ANALYZE - Product Scanning + Tracking
                AnalyzeView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            
            // Premium Custom Tab Bar
            PremiumTabBar(selectedTab: $selectedTab)
        }
        .accentColor(EzColors.Accent.primary)
    }
}

// MARK: - Premium Tab Bar Component

struct PremiumTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs: [TabBarItem] = [
        TabBarItem(title: "Home", icon: "calendar.circle.fill", tag: 0),
        TabBarItem(title: "Recipes", icon: "book.fill", tag: 1),
        TabBarItem(title: "Shop", icon: "cart.fill", tag: 2),
        TabBarItem(title: "Analyze", icon: "magnifyingglass.circle.fill", tag: 3)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(EzColors.Background.tertiary)
            
            HStack(spacing: 0) {
                ForEach(tabs, id: \.tag) { tab in
                    VStack(spacing: EzSpacing.xs) {
                        // Icon with indicator
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(
                                    selectedTab == tab.tag
                                        ? AppTheme.Colors.primary
                                        : EzColors.Text.tertiary
                                )
                            
                            if selectedTab == tab.tag {
                                Circle()
                                    .fill(AppTheme.Colors.primary)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        // Label
                        Text(tab.title)
                            .font(EzTypography.Helper.font)
                            .fontWeight(selectedTab == tab.tag ? .semibold : .regular)
                            .foregroundColor(
                                selectedTab == tab.tag
                                    ? AppTheme.Colors.primary
                                    : EzColors.Text.tertiary
                            )
                            .lineLimit(1)
                        
                        // Bottom indicator
                        if selectedTab == tab.tag {
                            Capsule()
                                .fill(AppTheme.Colors.primary)
                                .frame(height: 3)
                                .transition(.scale)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, EzSpacing.md)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(AppTheme.springSnappy) {
                            selectedTab = tab.tag
                        }
                    }
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(
                        selectedTab == tab.tag ? .isSelected : []
                    )
                }
            }
            .background(EzColors.Background.secondary)
            .frame(height: 60)
        }
        .background(EzColors.Background.secondary)
    }
}

// MARK: - Tab Bar Item

struct TabBarItem {
    let title: String
    let icon: String
    let tag: Int
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Menu.self,
            Recipe.self,
            Ingredient.self,
            DayMeals.self,
            ShoppingItem.self,
            Household.self,
            HouseholdUser.self,
            ShoppingListV2.self,
            ShoppingItemV2.self,
            ActivityLog.self
        ], inMemory: true)
        .preferredColorScheme(.dark)
}

// MARK: - Settings Sheet

struct HouseholdSettingsSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var householdManager: HouseholdManager
    @State private var editedName: String = ""
    @State private var showSaved = false
    @State private var showLeaveConfirm = false
    @State private var showLeaveError = false
    @State private var leaveErrorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: EzSpacing.lg) {
                if let household = householdManager.currentHousehold {
                    // Household Info Card
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Household Info")
                            .headlineStyle()
                        
                        VStack(spacing: EzSpacing.sm) {
                            HStack {
                                Label("Nume", systemImage: "house.fill")
                                    .foregroundColor(EzColors.Text.secondary)
                                Spacer()
                                if householdManager.currentUser?.canManageUsers == true {
                                    TextField("Nume household", text: $editedName)
                                        .multilineTextAlignment(.trailing)
                                        .textInputAutocapitalization(.words)
                                        .foregroundColor(EzColors.Text.primary)
                                } else {
                                    Text(household.name)
                                        .bodyStyle()
                                        .foregroundColor(EzColors.Text.primary)
                                }
                            }

                            if householdManager.currentUser?.canManageUsers == true {
                                EzButton(
                                    showSaved ? "Salvat ✓" : "Salvează numele",
                                    style: .primary,
                                    size: .medium,
                                    fullWidth: true
                                ) {
                                    guard !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                    household.name = editedName
                                    householdManager.updateHousehold(household)
                                    showSaved = true
                                    HapticManager.success()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        showSaved = false
                                    }
                                }
                                .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        
                        Divider()
                            .background(EzColors.Background.tertiary)
                        
                        HStack {
                            Label("Household ID", systemImage: "number")
                                .foregroundColor(EzColors.Text.secondary)
                            Spacer()
                        }
                        Text(String((household.inviteKey ?? household.id).uuidString).uppercased())
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(EzColors.Text.tertiary)
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(EzSpacing.sm)

                    // Invite Card
                    VStack(alignment: .leading, spacing: EzSpacing.md) {
                        Text("Invite Members")
                            .headlineStyle()
                        
                        let inviteKey = household.inviteKey ?? household.id
                        if let qrImage = QRCodeGenerator.generateInviteQRCode(householdId: inviteKey) {
                            VStack(spacing: EzSpacing.md) {
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 200, maxHeight: 200)
                                    .background(Color.white)
                                    .cornerRadius(EzSpacing.xs)
                                
                                Text(inviteKey.uuidString.uppercased())
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(EzColors.Text.tertiary)
                                    
                                EzButton(
                                    "Copiază invite key",
                                    icon: "doc.on.doc",
                                    style: .secondary,
                                    size: .medium,
                                    fullWidth: true
                                ) {
                                    UIPasteboard.general.string = inviteKey.uuidString.uppercased()
                                    HapticManager.success()
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(EzSpacing.md)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(EzSpacing.sm)
                    
                    // Members Management
                    NavigationLink(destination: HouseholdTabView()) {
                        HStack {
                            Label("Manage Members", systemImage: "person.2.fill")
                                .foregroundColor(EzColors.Text.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(EzColors.Text.tertiary)
                        }
                        .padding(EzSpacing.md)
                        .background(EzColors.Background.secondary)
                        .cornerRadius(EzSpacing.sm)
                    }

                    // Leave Household
                    VStack(spacing: EzSpacing.xs) {
                        EzButton(
                            "Părăsește household-ul",
                            icon: "rectangle.portrait.and.arrow.right",
                            style: .danger,
                            size: .medium,
                            fullWidth: true
                        ) {
                            showLeaveConfirm = true
                        }
                        
                        Text("Vei fi deconectat și va trebui să te alături din nou")
                            .font(.caption)
                            .foregroundColor(EzColors.Text.tertiary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: EzSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(EzColors.Accent.warning)
                        Text("Nu există household activ")
                            .headlineStyle()
                            .foregroundColor(EzColors.Text.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(EzSpacing.xl)
                }
            }
            .padding(EzSpacing.md)
        }
        .background(EzColors.Background.primary)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(EzColors.Accent.primary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .onAppear {
            if let name = householdManager.currentHousehold?.name, editedName.isEmpty {
                editedName = name
            }
        }
        .onChange(of: householdManager.currentHousehold?.id) {
            if let name = householdManager.currentHousehold?.name {
                editedName = name
            }
        }
        .alert("Părăsești household-ul?", isPresented: $showLeaveConfirm) {
            Button("Anulează", role: .cancel) {}
            Button("Ieși", role: .destructive) {
                do {
                    try householdManager.leaveCurrentHousehold()
                    isPresented = false
                } catch {
                    leaveErrorMessage = error.localizedDescription
                    showLeaveError = true
                }
            }
        } message: {
            Text("Această acțiune nu poate fi anulată.")
        }
        .alert("Eroare", isPresented: $showLeaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(leaveErrorMessage)
        }
    }
}

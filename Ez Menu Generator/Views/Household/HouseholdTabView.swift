//
// HouseholdTabView.swift
// Ez Menu Generator
//

import SwiftUI

struct HouseholdTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject private var householdManager: HouseholdManager
    
    // User editing state
    @State private var selectedUser: HouseholdUser?
    @State private var showEditSheet = false
    @State private var newRole: HouseholdUser.UserRole = .member
    @State private var showDeleteConfirm = false
    @State private var deleteErrorMessage: String?
    @State private var showDeleteError = false
    
    var isCurrentUserAdmin: Bool {
        householdManager.currentUser?.canManageUsers ?? false
    }
    
    var body: some View {
        if let household = householdManager.currentHousehold {
            TabView(selection: $selectedTab) {
                // Tab 1: Users
                ScrollView {
                    VStack(spacing: EzSpacing.md) {
                        // Owner Section
                        if let owner = household.getOwner() {
                            VStack(alignment: .leading, spacing: EzSpacing.sm) {
                                Text("Proprietar")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(EzColors.Text.secondary)
                                    .padding(.horizontal, EzSpacing.md)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: EzSpacing.xs) {
                                        Text(owner.username)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(EzColors.Text.primary)
                                        Text(owner.role.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundColor(EzColors.Text.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(EzColors.Accent.warning)
                                }
                                .padding(EzSpacing.md)
                                .background(EzColors.Background.secondary)
                                .cornerRadius(EzSpacing.sm)
                            }
                        }
                        
                        // Members Section
                        VStack(alignment: .leading, spacing: EzSpacing.sm) {
                            Text("Membri")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(EzColors.Text.secondary)
                                .padding(.horizontal, EzSpacing.md)
                            
                            ForEach(household.users.filter { $0.role != .owner }) { user in
                                Button(action: {
                                    if isCurrentUserAdmin {
                                        selectedUser = user
                                        newRole = user.role
                                        showEditSheet = true
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: EzSpacing.xs) {
                                            Text(user.username)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(EzColors.Text.primary)
                                            if let email = user.email {
                                                Text(email)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(EzColors.Text.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text(user.role.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                            .padding(.horizontal, EzSpacing.sm)
                                            .padding(.vertical, EzSpacing.xs)
                                            .background(EzColors.Accent.primary.opacity(0.2))
                                            .foregroundColor(EzColors.Accent.primary)
                                            .cornerRadius(EzSpacing.xs)
                                        
                                        if isCurrentUserAdmin {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(EzColors.Text.tertiary)
                                        }
                                    }
                                    .padding(EzSpacing.md)
                                    .background(EzColors.Background.secondary)
                                    .cornerRadius(EzSpacing.sm)
                                }
                                .buttonStyle(.plain)
                                .disabled(!isCurrentUserAdmin)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                }
                .background(EzColors.Background.primary)
                .tabItem {
                    Label("Utilizatori", systemImage: "person.2")
                }
                .tag(0)
                
                // Tab 2: Shopping Lists
                ScrollView {
                    VStack(spacing: EzSpacing.md) {
                        if household.shoppingLists.isEmpty {
                            VStack(spacing: EzSpacing.md) {
                                Image(systemName: "cart")
                                    .font(.system(size: 48, weight: .thin))
                                    .foregroundColor(EzColors.Text.tertiary)
                                Text("Nicio listă de cumpărături")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(EzColors.Text.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, EzSpacing.xl)
                        } else {
                            ForEach(household.shoppingLists.sorted { $0.updatedAt > $1.updatedAt }) { list in
                                VStack(alignment: .leading, spacing: EzSpacing.sm) {
                                    HStack {
                                        Text(list.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(EzColors.Text.primary)
                                        Spacer()
                                        Text(list.status)
                                            .font(.system(size: 12, weight: .medium))
                                            .padding(.horizontal, EzSpacing.sm)
                                            .padding(.vertical, EzSpacing.xs)
                                            .background(statusColor(list.status).opacity(0.2))
                                            .foregroundColor(statusColor(list.status))
                                            .cornerRadius(EzSpacing.xs)
                                    }
                                    
                                    HStack(spacing: EzSpacing.sm) {
                                        Text("\(list.checkedCount)/\(list.totalCount)")
                                            .font(.system(size: 13))
                                            .foregroundColor(EzColors.Text.secondary)
                                        ProgressView(value: list.progressPercentage / 100)
                                            .tint(EzColors.Accent.primary)
                                            .frame(height: 4)
                                    }
                                    
                                    Text(list.createdByUsername)
                                        .font(.system(size: 12))
                                        .foregroundColor(EzColors.Text.tertiary)
                                }
                                .padding(EzSpacing.md)
                                .background(EzColors.Background.secondary)
                                .cornerRadius(EzSpacing.sm)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                }
                .background(EzColors.Background.primary)
                .tabItem {
                    Label("Liste", systemImage: "cart")
                }
                .tag(1)
                
                // Tab 3: Activity Log
                ScrollView {
                    VStack(spacing: EzSpacing.md) {
                        if household.activityLogs.isEmpty {
                            VStack(spacing: EzSpacing.md) {
                                Image(systemName: "clock")
                                    .font(.system(size: 48, weight: .thin))
                                    .foregroundColor(EzColors.Text.tertiary)
                                Text("Nicio activitate")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(EzColors.Text.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, EzSpacing.xl)
                        } else {
                            ForEach(household.activityLogs.sorted { $0.timestamp > $1.timestamp }) { log in
                                VStack(alignment: .leading, spacing: EzSpacing.xs) {
                                    Text(log.displayDescription)
                                        .font(.system(size: 15))
                                        .foregroundColor(EzColors.Text.primary)
                                    
                                    if let details = log.details {
                                        Text(details)
                                            .font(.system(size: 13))
                                            .foregroundColor(EzColors.Text.secondary)
                                    }
                                    
                                    Text(formatDate(log.timestamp))
                                        .font(.system(size: 11))
                                        .foregroundColor(EzColors.Text.tertiary)
                                }
                                .padding(EzSpacing.md)
                                .background(EzColors.Background.secondary)
                                .cornerRadius(EzSpacing.sm)
                            }
                        }
                    }
                    .padding(EzSpacing.md)
                }
                .background(EzColors.Background.primary)
                .tabItem {
                    Label("Activitate", systemImage: "clock")
                }
                .tag(2)
            }
            .navigationTitle(household.name)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditSheet) {
                if let user = selectedUser {
                    UserEditSheet(
                        user: user,
                        selectedRole: $newRole,
                        onSave: {
                            householdManager.changeUserRole(household, userId: user.id, newRole: newRole)
                            showEditSheet = false
                        },
                        onDelete: {
                            showDeleteConfirm = true
                        },
                        onCancel: {
                            showEditSheet = false
                        }
                    )
                }
            }
            .alert("Confirmare ștergere", isPresented: $showDeleteConfirm) {
                Button("Anulează", role: .cancel) { }
                Button("Șterge", role: .destructive) {
                    if let user = selectedUser {
                        householdManager.removeUserFromHousehold(household, userId: user.id)
                        showEditSheet = false
                        showDeleteConfirm = false
                        selectedUser = nil
                    }
                }
            } message: {
                Text("Ești sigur că vrei să ștergi pe \(selectedUser?.username ?? "utilizatorul") din household?")
            }
            .alert("Eroare", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage ?? "A apărut o eroare")
            }
        } else {
            VStack(spacing: EzSpacing.lg) {
                Image(systemName: "house.fill")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(EzColors.Text.tertiary)
                
                VStack(spacing: EzSpacing.xs) {
                    Text("Nu există household activ")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(EzColors.Text.primary)
                    
                    Text("Creează sau alătură-te unui household pentru a vedea membrii.")
                        .font(.system(size: 15))
                        .foregroundColor(EzColors.Text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, EzSpacing.lg)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(EzColors.Background.primary)
            .padding()
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        // Return pre-computed colors to avoid runtime calculation issues
        let colors: [String: Color] = [
            "active": EzColors.Accent.primary,
            "archived": EzColors.Text.tertiary,
            "completed": EzColors.Accent.success
        ]
        return colors[status] ?? EzColors.Text.tertiary
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - User Edit Sheet

struct UserEditSheet: View {
    let user: HouseholdUser
    @Binding var selectedRole: HouseholdUser.UserRole
    let onSave: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: EzSpacing.lg) {
                    userInfoCard
                    roleSelectionCard
                    actionButtons
                }
                .padding(EzSpacing.md)
            }
            .background(EzColors.Background.primary)
            .navigationTitle("Editează utilizator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { onCancel() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(EzColors.Accent.primary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
    
    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Utilizator")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(EzColors.Text.secondary)
            
            VStack(alignment: .leading, spacing: EzSpacing.sm) {
                Text(user.username)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(EzColors.Text.primary)
                
                if let email = user.email {
                    HStack(spacing: EzSpacing.xs) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 12))
                            .foregroundColor(EzColors.Text.tertiary)
                        Text(email)
                            .font(.system(size: 14))
                            .foregroundColor(EzColors.Text.secondary)
                    }
                }
            }
        }
        .padding(EzSpacing.md)
        .background(EzColors.Background.secondary)
        .cornerRadius(EzSpacing.sm)
    }
    
    private var roleSelectionCard: some View {
        VStack(alignment: .leading, spacing: EzSpacing.md) {
            Text("Rol")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(EzColors.Text.secondary)
            
            VStack(spacing: EzSpacing.xs) {
                ForEach([HouseholdUser.UserRole.admin, .member, .guest], id: \.self) { role in
                    RoleSelectionRow(
                        role: role,
                        isSelected: selectedRole == role,
                        onSelect: {
                            selectedRole = role
                            HapticManager.selectionChanged()
                        }
                    )
                }
            }
        }
        .padding(EzSpacing.md)
        .background(EzColors.Background.secondary)
        .cornerRadius(EzSpacing.sm)
    }
    
    private var actionButtons: some View {
        VStack(spacing: EzSpacing.md) {
            EzButton(
                "Salvează modificările",
                icon: "checkmark.circle.fill",
                style: .primary,
                size: .medium,
                fullWidth: true
            ) {
                HapticManager.success()
                onSave()
                dismiss()
            }
            .disabled(selectedRole == user.role)
            
            EzButton(
                "Șterge din household",
                icon: "trash.fill",
                style: .danger,
                size: .medium,
                fullWidth: true
            ) {
                onDelete()
            }
            
            EzButton(
                "Anulează",
                style: .secondary,
                size: .medium,
                fullWidth: true
            ) {
                onCancel()
            }
        }
    }
}

// MARK: - Role Selection Row Component

struct RoleSelectionRow: View {
    let role: HouseholdUser.UserRole
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: EzSpacing.xs) {
                    Text(roleDisplayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(EzColors.Text.primary)
                    Text(roleDescription)
                        .font(.system(size: 13))
                        .foregroundColor(EzColors.Text.secondary)
                }
                Spacer()
                
                let iconName = isSelected ? "checkmark.circle.fill" : "circle"
                let iconColor = isSelected ? EzColors.Accent.primary : EzColors.Text.tertiary
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            .padding(EzSpacing.sm)
            .background(backgroundColor)
            .cornerRadius(EzSpacing.xs)
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        isSelected ? EzColors.Accent.primary.opacity(0.1) : EzColors.Background.tertiary
    }
    
    private var roleDisplayName: String {
        switch role {
        case .owner: return "Proprietar"
        case .admin: return "Administrator"
        case .member: return "Membru"
        case .guest: return "Oaspete"
        }
    }
    
    private var roleDescription: String {
        switch role {
        case .owner: return "Control complet"
        case .admin: return "Poate gestiona membri și setări"
        case .member: return "Poate edita meniuri și rețete"
        case .guest: return "Poate doar vizualiza"
        }
    }
}

//
// HouseholdOnboardingView.swift
// Ez Menu Generator
//

import SwiftUI
import SwiftData

struct HouseholdOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var householdManager: HouseholdManager
    
    @State private var selectedMode: OnboardingMode = .create
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var createdHousehold: Household?
    @State private var inviteKey: String?
    
    enum OnboardingMode {
        case create
        case join
    }
    
    var body: some View {
        if let household = createdHousehold, let key = inviteKey {
            HouseholdSuccessView(
                household: household,
                inviteKey: key,
                onDone: {
                    householdManager.setCurrentHousehold(household)
                    createdHousehold = nil
                    inviteKey = nil
                }
            )
        } else {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 48))
                        .foregroundColor(EzColors.Accent.primary)
                    
                    Text("Bine ai venit!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Configurează-ți household-ul")
                        .font(.subheadline)
                        .foregroundColor(EzColors.Text.secondary)
                }
                .padding(.vertical, 32)
                
                Divider()
                    .padding(.vertical, 20)
                
                HStack(spacing: 0) {
                    Button(action: { selectedMode = .create }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Crează")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(selectedMode == .create ? EzColors.Text.primary : EzColors.Text.tertiary)
                        .background(selectedMode == .create ? EzColors.Accent.primary : EzColors.Background.tertiary)
                    }
                    
                    Button(action: { selectedMode = .join }) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                            Text("Alătură-te")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(selectedMode == .join ? EzColors.Text.primary : EzColors.Text.tertiary)
                        .background(selectedMode == .join ? EzColors.Accent.primary : EzColors.Background.tertiary)
                    }
                }
                .cornerRadius(12)
                .padding(.bottom, 32)
                
                if selectedMode == .create {
                    CreateHouseholdSection(
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        onSuccess: { household, key in
                            createdHousehold = household
                            inviteKey = key
                        }
                    )
                } else {
                    JoinHouseholdSection(
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        onSuccess: { _ in }
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1.0)
        }
    }
}

// MARK: - Create Household

struct CreateHouseholdSection: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var householdManager = HouseholdManager.shared
    
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    var onSuccess: (Household, String) -> Void
    
    @State private var householdName = ""
    @State private var username = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Nume Household", systemImage: "house")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextField("ex: Apartament 42", text: $householdName)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Numele tău", systemImage: "person")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextField("ex: Ion", text: $username)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(8)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(EzColors.Accent.danger)
                    .padding()
                    .background(EzColors.Accent.danger.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button(action: createHousehold) {
                Text("Crează Household")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(EzColors.Accent.primary)
                    .foregroundColor(EzColors.Text.primary)
                    .cornerRadius(8)
            }
            .disabled(householdName.isEmpty || username.isEmpty)
            
            Spacer()
        }
    }
    
    private func createHousehold() {
        guard !householdName.isEmpty, !username.isEmpty else {
            errorMessage = "Completează toate câmpurile"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let session = try await SupabaseAuthService.shared.createHousehold(
                    username: username,
                    householdName: householdName
                )

                await MainActor.run {
                    householdManager.applyRemoteSession(session, in: modelContext)
                    if let household = householdManager.currentHousehold {
                        onSuccess(household, session.household.inviteKey.uuidString.uppercased())
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Join Household

struct JoinHouseholdSection: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var householdManager = HouseholdManager.shared
    
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    var onSuccess: (Household) -> Void
    
    @State private var inviteKey = ""
    @State private var username = ""
    @State private var showScanner = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Cod de invitație", systemImage: "key")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    TextField("ex: A1B2C3D4", text: $inviteKey)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(EzColors.Background.secondary)
                        .cornerRadius(8)
                        .autocapitalization(.allCharacters)
                    
                    Button(action: { showScanner = true }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 18))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(EzColors.Accent.primary)
                            .foregroundColor(EzColors.Text.primary)
                            .cornerRadius(8)
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                QRCodeScannerSheet(inviteKey: $inviteKey, isPresented: $showScanner)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Numele tău", systemImage: "person")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextField("ex: Maria", text: $username)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(EzColors.Background.secondary)
                    .cornerRadius(8)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(EzColors.Accent.danger)
                    .padding()
                    .background(EzColors.Accent.danger.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button(action: joinHousehold) {
                Text("Alătură-te")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(EzColors.Accent.success)
                    .foregroundColor(EzColors.Text.primary)
                    .cornerRadius(8)
            }
            .disabled(inviteKey.isEmpty || username.isEmpty)
            
            Spacer()
        }
    }
    
    private func joinHousehold() {
        guard !inviteKey.isEmpty, !username.isEmpty else {
            errorMessage = "Completează toate"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let session = try await SupabaseAuthService.shared.joinHousehold(
                    username: username,
                    inviteKey: inviteKey.trimmingCharacters(in: .whitespacesAndNewlines)
                )

                await MainActor.run {
                    householdManager.applyRemoteSession(session, in: modelContext)
                    if let household = householdManager.currentHousehold {
                        onSuccess(household)
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Success View (Invite Key + QR Code)

struct HouseholdSuccessView: View {
    let household: Household
    let inviteKey: String
    let onDone: () -> Void
    
    @State private var qrImage: UIImage?
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(EzColors.Accent.success)
                
                Text("Household creat!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(household.name)
                    .font(.headline)
                    .foregroundColor(EzColors.Text.secondary)
            }
            .padding(.vertical, 32)
            
            Divider()
            
            VStack(spacing: 16) {
                Text("Invită alții")
                    .font(.headline)
                
                if let qrImage = qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                        .background(EzColors.Background.secondary)
                        .border(EzColors.Background.surface.opacity(0.3))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(EzColors.Background.secondary)
                        .frame(height: 200)
                        .overlay(ProgressView())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cheie de invitație").font(.caption).foregroundColor(EzColors.Text.secondary)
                    
                    HStack(spacing: 12) {
                        Text(inviteKey)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(EzColors.Background.secondary)
                            .cornerRadius(8)
                        
                        Button(action: copyKey) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 16))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(EzColors.Accent.primary)
                                .foregroundColor(EzColors.Text.primary)
                                .cornerRadius(6)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pași:").font(.caption).fontWeight(.semibold).foregroundColor(EzColors.Text.secondary)
                    Text("1. Distribuie codul QR sau cheia de invitație").font(.caption)
                    Text("2. Se alătură cu cheie + nume").font(.caption)
                    Text("3. Sincronizare listă în timp real").font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(EzColors.Accent.primary.opacity(0.1))
                .cornerRadius(6)
            }
            
            Button(action: onDone) {
                Text("Continuă în aplicație")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(EzColors.Accent.primary)
                    .foregroundColor(EzColors.Text.primary)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .onAppear {
            if let keyUUID = UUID(uuidString: inviteKey) {
                qrImage = QRCodeGenerator.generateInviteQRCode(householdId: keyUUID, size: CGSize(width: 300, height: 300))
            }
        }
    }
    
    private func copyKey() {
        UIPasteboard.general.string = inviteKey
        withAnimation {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copied = false
            }
        }
    }
}

#Preview {
    HouseholdOnboardingView()
}

// MARK: - QR Code Scanner Sheet

struct QRCodeScannerSheet: View {
    @Binding var inviteKey: String
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            QRCodeScannerView(
                onScanned: { householdId in
                    inviteKey = householdId.uppercased()
                    isPresented = false
                },
                onCancel: {
                    isPresented = false
                }
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Previews

#Preview("Onboarding - Create Mode") {
    HouseholdOnboardingView()
        .modelContainer(for: [Household.self, HouseholdUser.self], inMemory: true)
        .preferredColorScheme(.dark)
}

#Preview("Household Success") {
    let household = Household(
        name: "Familie Popescu",
        ownerId: UUID(),
        createdAt: Date(),
        updatedAt: Date()
    )
    
    return HouseholdSuccessView(
        household: household,
        inviteKey: "A1B2C3D4",
        onDone: {}
    )
    .preferredColorScheme(.dark)
}

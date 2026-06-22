import SwiftUI

struct FamilyView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: FamilyViewModel?
    @State private var familyNameInput: String = "My Family"
    @State private var inviteCodeInput: String = ""
    @State private var codeCopied: Bool = false
    @State private var showLeaveConfirm: Bool = false
    @State private var showDisbandConfirm: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.xl) {
                    if let vm = viewModel {
                        if vm.isLoading && vm.family == nil {
                            ProgressView()
                                .tint(Theme.Palette.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, Theme.Spacing.xxxl)
                        } else if let family = vm.family {
                            activeFamilySection(vm: vm, family: family)
                        } else {
                            noFamilySection(vm: vm)
                        }

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(AppFont.captionMedium)
                                .foregroundStyle(Theme.Palette.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#F5F7FA").ignoresSafeArea())
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") { dismiss() }
                        .font(AppFont.bodySemibold)
                        .foregroundStyle(Theme.Palette.accentMint)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = FamilyViewModel(familyRepo: env.familyRepo, session: session, env: env)
            }
            Task { await viewModel?.reload() }
        }
    }

    // MARK: - Active Family

    @ViewBuilder
    private func activeFamilySection(vm: FamilyViewModel, family: FamilyModel) -> some View {
        // Header card
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.Palette.accentMint.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "house.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.Palette.accentMint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(family.name)
                        .font(AppFont.title)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text("Family aktif · \(vm.members.count) anggota")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                Spacer()
            }
        }
        .glassCard()

        // Invite code
        inviteCodeCard(code: family.inviteCode)

        // Members
        membersSection(vm: vm)

        // Action
        if vm.isOwner {
            Button("Bubarkan Family") { showDisbandConfirm = true }
                .buttonStyle(GlassSecondaryButtonStyle())
                .disabled(vm.isLoading)
        } else {
            Button("Keluar dari Family") { showLeaveConfirm = true }
                .buttonStyle(GlassSecondaryButtonStyle())
                .disabled(vm.isLoading)
        }
    }

    private func inviteCodeCard(code: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("KODE UNDANGAN")
                .font(AppFont.overline)
                .tracking(1.2)
                .foregroundStyle(Theme.Palette.textSecondary)

            HStack(alignment: .center) {
                Text(code)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .tracking(8)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    withAnimation(Motion.snappy) { codeCopied = true }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation(Motion.snappy) { codeCopied = false }
                    }
                } label: {
                    Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(codeCopied ? Theme.Palette.accentMint : Theme.Palette.textSecondary)
                }
            }

            Text("Bagikan kode ini ke pasangan/anggota keluarga untuk bergabung.")
                .font(AppFont.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
        .confirmationDialog("Keluar dari Family?", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
            Button("Keluar", role: .destructive) { Task { await viewModel?.leaveFamily() } }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Data Anda sebelumnya tetap tersimpan.")
        }
        .confirmationDialog("Bubarkan Family?", isPresented: $showDisbandConfirm, titleVisibility: .visible) {
            Button("Bubarkan", role: .destructive) { Task { await viewModel?.disbandFamily() } }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Semua anggota akan keluar. Data tetap aman.")
        }
    }

    @ViewBuilder
    private func membersSection(vm: FamilyViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Anggota")
                .font(AppFont.titleMedium)
                .foregroundStyle(Theme.Palette.textPrimary)

            ForEach(vm.members) { member in
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(member.isOwner
                                  ? Theme.Palette.accentMint.opacity(0.18)
                                  : Theme.Palette.accentSky.opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: member.isOwner ? "crown.fill" : "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(member.isOwner ? Theme.Palette.accentMint : Theme.Palette.accentSky)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.displayName ?? "Anggota")
                            .font(AppFont.bodySemibold)
                            .foregroundStyle(Theme.Palette.textPrimary)
                        Text(member.isOwner ? "Pemilik" : "Anggota")
                            .font(AppFont.caption)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                    Spacer()
                    Text(member.joinedAt, style: .date)
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.Palette.textTertiary)
                }
                .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
            }
        }
    }

    // MARK: - No Family

    @ViewBuilder
    private func noFamilySection(vm: FamilyViewModel) -> some View {
        // Illustration
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.Palette.accentMint.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "house.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.Palette.accentMint)
            }
            Text("Belum Ada Family")
                .font(AppFont.titleMedium)
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("Buat family baru atau masuk dengan\nkode dari pasangan Anda.")
                .font(AppFont.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard()

        // Create
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("BUAT FAMILY BARU")
                .font(AppFont.overline)
                .tracking(1.2)
                .foregroundStyle(Theme.Palette.textSecondary)

            GlassTextField(
                title: "Nama keluarga (cth: Keluarga Hadi)",
                text: $familyNameInput,
                icon: "house.fill",
                autocap: .words
            )

            Button {
                Task { await vm.createFamily(name: familyNameInput) }
            } label: {
                HStack {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Label("Buat Family", systemImage: "plus.circle.fill")
                    }
                }
            }
            .buttonStyle(GlassPrimaryButtonStyle())
            .disabled(vm.isLoading)
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)

        // Divider
        HStack {
            Rectangle().fill(Theme.Palette.glassStroke).frame(height: 1)
            Text("atau")
                .font(AppFont.captionMedium)
                .foregroundStyle(Theme.Palette.textTertiary)
                .padding(.horizontal, 8)
            Rectangle().fill(Theme.Palette.glassStroke).frame(height: 1)
        }

        // Join
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("GABUNG FAMILY")
                .font(AppFont.overline)
                .tracking(1.2)
                .foregroundStyle(Theme.Palette.textSecondary)

            GlassTextField(
                title: "Kode undangan (8 karakter)",
                text: $inviteCodeInput,
                icon: "key.fill",
                autocap: .characters
            )

            Button {
                Task { await vm.joinFamily(code: inviteCodeInput) }
            } label: {
                HStack {
                    if vm.isLoading {
                        ProgressView().tint(Theme.Palette.bgDeep)
                    } else {
                        Label("Gabung Family", systemImage: "arrow.right.circle.fill")
                    }
                }
            }
            .buttonStyle(GlassSecondaryButtonStyle())
            .disabled(vm.isLoading)
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }
}

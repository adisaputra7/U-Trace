import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(AppEnvironment.self) private var env
    @State private var showFamily: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                avatarBlock

                familyCard

                infoCard

                Button {
                    Task { await session.logout() }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(GlassSecondaryButtonStyle())

                Spacer(minLength: 80)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.xxxl)
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showFamily) {
            FamilyView()
        }
    }

    private var avatarBlock: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.Palette.mintGradient)
                    .frame(width: 96, height: 96)
                    .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                    .shadow(color: Theme.Palette.accentMint.opacity(0.4), radius: 28, y: 12)
                Text(initials)
                    .font(AppFont.display)
                    .foregroundStyle(Theme.Palette.bgDeep)
            }

            Text(session.session?.email ?? "")
                .font(AppFont.titleMedium)
                .foregroundStyle(Theme.Palette.textPrimary)

            Text(env.currentFamily != nil ? "U Trace Family · \(env.currentFamily!.name)" : "U Trace member")
                .font(AppFont.captionMedium)
                .foregroundStyle(env.currentFamily != nil ? Theme.Palette.accentMint : Theme.Palette.textSecondary)
        }
    }

    private var familyCard: some View {
        Button { showFamily = true } label: {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Palette.accentMint.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: env.currentFamily != nil ? "house.fill" : "house")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Palette.accentMint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Family Sharing")
                        .font(AppFont.bodySemibold)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text(env.currentFamily != nil ? env.currentFamily!.name : "Belum bergabung")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            row(icon: "envelope.fill", label: "Email", value: session.session?.email ?? "—")
            row(icon: "key.fill", label: "Session token", value: maskedToken)
            row(icon: "icloud.fill", label: "Backend", value: "Insforge Cloud")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func row(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Palette.accentMint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.overline)
                    .tracking(1.0)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Text(value)
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
    }

    private var initials: String {
        guard let email = session.session?.email else { return "?" }
        let first = email.first.map { String($0).uppercased() } ?? "?"
        return first
    }

    private var maskedToken: String {
        guard let token = session.session?.token else { return "—" }
        return String(token.prefix(6)) + "••••"
    }
}

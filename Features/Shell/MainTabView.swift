import SwiftUI

struct MainTabView: View {
    @State private var selection: Tab = .dashboard
    @State private var showAdd: Bool = false

    enum Tab: Hashable { case dashboard, history, wallets, profile }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .dashboard: DashboardView()
                case .history:   TransactionHistoryView()
                case .wallets:   WalletListView()
                case .profile:   ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)

            BottomBar(selection: $selection) {
                withAnimation(Motion.snappy) { showAdd = true }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionSheet()
        }
    }
}

private struct BottomBar: View {
    @Binding var selection: MainTabView.Tab
    var onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.dashboard, icon: "house.fill", label: "Home")
            tabButton(.history,   icon: "list.bullet.rectangle.fill", label: "History")

            QuickAddFAB(action: onAddTapped)
                .padding(.horizontal, 8)
                .offset(y: -18)

            tabButton(.wallets, icon: "creditcard.fill", label: "Wallets")
            tabButton(.profile, icon: "person.fill", label: "Profile")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(Color.white)
        }
        .overlay {
            Capsule().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 4)
    }

    @ViewBuilder
    private func tabButton(_ tab: MainTabView.Tab, icon: String, label: String) -> some View {
        Button {
            withAnimation(Motion.snappy) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(selection == tab ? Theme.Palette.accentMint : Theme.Palette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .scaleEffect(selection == tab ? 1.05 : 1.0)
            .animation(Motion.snappy, value: selection)
        }
        .buttonStyle(.plain)
    }
}

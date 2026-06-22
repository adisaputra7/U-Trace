import SwiftUI

struct TransactionRow: View {
    let transaction: TransactionModel
    var isExpanded: Bool = false
    var onTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // — Summary row (always visible) —
            Button(action: onTap) {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.25))
                            .frame(width: 44, height: 44)
                        Image(systemName: transaction.category?.iconName ?? "questionmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(transaction.category?.name ?? "Uncategorized")
                                .font(AppFont.bodySemibold)
                                .foregroundStyle(Theme.Palette.textPrimary)
                            if let creator = transaction.createdByDisplayName {
                                HStack(spacing: 3) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 9, weight: .bold))
                                    Text(creator)
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundStyle(Theme.Palette.accentSky)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.Palette.accentSky.opacity(0.12)))
                            }
                        }
                        HStack(spacing: 6) {
                            Text(transaction.wallet?.name ?? "—")
                            Text("·")
                            Text(Formatter.dateRelative.string(from: transaction.date))
                        }
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                    }

                    Spacer()

                    HStack(alignment: .center, spacing: Theme.Spacing.sm) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formattedAmount)
                                .font(AppFont.bodySemibold)
                                .foregroundStyle(transaction.type == .income ? Theme.Palette.accentMint : Theme.Palette.textPrimary)
                            Text(transaction.type.displayName.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(Theme.Palette.textTertiary)
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.Palette.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(Motion.gentle, value: isExpanded)
                    }
                }
            }
            .buttonStyle(.plain)

            // — Detail panel (visible when expanded) —
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Divider()
                        .overlay(Theme.Palette.glassStroke)
                        .padding(.top, Theme.Spacing.sm)

                    detailRow(icon: "calendar", label: fullDate)
                    detailRow(icon: "creditcard", label: transaction.wallet?.name ?? "—")

                    if let note = transaction.note, !note.isEmpty {
                        detailRow(icon: "note.text", label: note)
                    }
                }
                .padding(.top, Theme.Spacing.sm)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(Motion.gentle, value: isExpanded)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func detailRow(icon: String, label: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Palette.textTertiary)
                .frame(width: 16)
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
    }

    private var iconColor: Color {
        if let hex = transaction.category?.colorHex { return Color(hex: hex) }
        return Theme.Palette.accentMint
    }

    private var formattedAmount: String {
        let sign = transaction.type == .income ? "+" : "−"
        return sign + Formatter.currency(transaction.amount)
    }

    private var fullDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: transaction.date)
    }
}

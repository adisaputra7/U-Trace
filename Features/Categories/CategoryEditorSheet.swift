import SwiftUI

struct CategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: CategoryViewModel
    var existing: CategoryModel?

    @State private var name: String = ""
    @State private var iconName: String = "tag.fill"
    @State private var colorHex: String = "#7CFFCB"
    @State private var scope: CategoryScope = .expense

    private let palette = ["#7CFFCB", "#FF7CCB", "#FFD37C", "#7CD8FF", "#A0A0FF", "#FF6B7A"]
    private let icons = [
        "tag.fill", "cart.fill", "fork.knife", "car.fill", "house.fill",
        "airplane", "gamecontroller.fill", "heart.fill", "graduationcap.fill",
        "tshirt.fill", "leaf.fill", "wand.and.stars", "bag.fill",
        "creditcard.fill", "wifi", "phone.fill", "music.note", "gift.fill"
    ]

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text(existing == nil ? "New Category" : "Edit Category")
                        .font(AppFont.display)
                        .foregroundStyle(Theme.Palette.textPrimary)

                    GlassTextField(title: "Category name", text: $name, icon: "tag.fill", autocap: .words)

                    scopePicker

                    iconGrid

                    colorPicker

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppFont.captionMedium)
                            .foregroundStyle(Theme.Palette.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: Theme.Spacing.xxxl)

                    Button {
                        Task { await save() }
                    } label: {
                        Text(existing == nil ? "Create Category" : "Save Changes")
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .onAppear {
            if let existing {
                name = existing.name
                iconName = existing.iconName
                colorHex = existing.colorHex
                scope = existing.scope
            }
        }
    }

    private var scopePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)
            HStack(spacing: 8) {
                ForEach(CategoryScope.allCases) { value in
                    Button(value.rawValue.capitalized) { scope = value }
                        .buttonStyle(GlassPillButtonStyle(isActive: scope == value))
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var iconGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Icon")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        iconName = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(iconName == icon ? Theme.Palette.bgDeep : Theme.Palette.textPrimary)
                            .frame(width: 40, height: 40)
                            .background {
                                Circle().fill(iconName == icon
                                              ? AnyShapeStyle(Theme.Palette.mintGradient)
                                              : AnyShapeStyle(Theme.Palette.glassFill))
                            }
                            .overlay(Circle().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(AppFont.overline)
                .tracking(1.0)
                .foregroundStyle(Theme.Palette.textSecondary)
            HStack(spacing: 12) {
                ForEach(palette, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(colorHex == hex ? Color.white : Color(hex: "#E2E8F0"), lineWidth: 2)
                            )
                            .scaleEffect(colorHex == hex ? 1.1 : 1.0)
                            .animation(Motion.snappy, value: colorHex)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let success: Bool
        if let existing {
            success = await viewModel.update(id: existing.id, name: trimmedName, iconName: iconName, colorHex: colorHex, scope: scope)
        } else {
            success = await viewModel.create(name: trimmedName, iconName: iconName, colorHex: colorHex, scope: scope)
        }
        if success { dismiss() }
    }
}

import SwiftUI

struct CategoryListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CategoryViewModel?
    @State private var showEditor: Bool = false
    @State private var editing: CategoryModel?

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Categories")
                                .font(AppFont.display)
                                .foregroundStyle(Theme.Palette.textPrimary)
                            Text("System and custom")
                                .font(AppFont.captionMedium)
                                .foregroundStyle(Theme.Palette.textSecondary)
                        }
                        Spacer()
                        Button {
                            editing = nil
                            showEditor = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.Palette.bgDeep)
                                .padding(10)
                                .background(Circle().fill(Theme.Palette.mintGradient))
                        }
                    }

                    if let viewModel {
                        ForEach(viewModel.categories) { category in
                            CategoryRow(category: category) {
                                editing = category
                                showEditor = true
                            } onDelete: {
                                Task { await viewModel.delete(id: category.id) }
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CategoryViewModel(categoryRepo: env.categoryRepo, session: session)
            }
            Task { await viewModel?.reload() }
        }
        .sheet(isPresented: $showEditor, onDismiss: {
            editing = nil
            Task { await viewModel?.reload() }
        }) {
            if let viewModel {
                CategoryEditorSheet(viewModel: viewModel, existing: editing)
            }
        }
    }
}

private struct CategoryRow: View {
    let category: CategoryModel
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex).opacity(0.25))
                    .frame(width: 40, height: 40)
                Image(systemName: category.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: category.colorHex))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(category.name)
                        .font(AppFont.bodySemibold)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    if category.isSystem {
                        Text("SYSTEM")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.Palette.glassFill))
                            .overlay(Capsule().strokeBorder(Theme.Palette.glassStroke, lineWidth: 1))
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                }
                Text(category.scope.rawValue.capitalized)
                    .font(AppFont.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }

            Spacer()

            if !category.isSystem {
                Menu {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .padding(6)
                }
            }
        }
        .glassCard(cornerRadius: Theme.Radius.md, padding: Theme.Spacing.lg)
    }
}

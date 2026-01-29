import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 220, idealWidth: 260)

            detail
                .frame(minWidth: 420, idealWidth: 560)
        }
        .navigationTitle("主页")
        .toolbar {
            ToolbarItemGroup {
                Button("刷新") { viewModel.refreshSelection() }
                    .disabled(viewModel.selectedExtension == nil || viewModel.isWorking)
                Button("清空日志") { viewModel.clearLogs() }
                    .disabled(viewModel.logs.isEmpty)
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索后缀（例如：pdf 或 .pdf）", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)

            List(selection: $viewModel.selectedRowID) {
                ForEach(viewModel.filteredPresetCategories, id: \.title) { category in
                    Section(category.title) {
                        ForEach(category.groups, id: \.title) { group in
                            Text(group.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)

                            ForEach(group.extensions, id: \.self) { ext in
                                Text(".\(ext)")
                                    .tag(presetRowID(category: category.title, group: group.title, ext: ext) as String?)
                            }
                        }
                    }
                }

                Section("自定义") {
                    ForEach(viewModel.filteredCustomExtensions, id: \.self) { ext in
                        Text(".\(ext)")
                            .tag(customRowID(ext: ext) as String?)
                            .contextMenu {
                                Button("移除") {
                                    viewModel.removeCustomExtension(ext)
                                }
                            }
                    }
                    .onDelete { offsets in
                        viewModel.removeCustomExtensions(at: offsets)
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            HStack(spacing: 8) {
                TextField("添加后缀（例如：webp, avif）", text: $viewModel.customExtensionInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { viewModel.addCustomExtensions() }
                Button("添加") { viewModel.addCustomExtensions() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(10)
        }
    }

    private func presetRowID(category: String, group: String, ext: String) -> String {
        "preset|\(category)|\(group)|\(ext)"
    }

    private func customRowID(ext: String) -> String {
        "custom|\(ext)"
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let ext = viewModel.selectedExtension {
                VStack(alignment: .leading, spacing: 2) {
                    Text(".\(ext)")
                        .font(.title2.weight(.semibold))
                    if let uti = viewModel.selectedUTI {
                        Text("UTI: \(uti)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox("当前默认应用") {
                    if let app = viewModel.currentDefaultApp {
                        appCard(app)
                    } else {
                        Text(viewModel.currentDefaultAppPlaceholder)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                }

                GroupBox("设置为") {
                    VStack(alignment: .leading, spacing: 10) {
                        if let app = viewModel.targetApp {
                            appCard(app)
                        } else {
                            Text("未选择")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }

                        HStack(spacing: 8) {
                            Button("选择应用…") { viewModel.pickTargetApplication() }
                            Button("使用当前默认") { viewModel.useCurrentAsTarget() }
                                .disabled(viewModel.currentDefaultApp == nil)
                            Spacer()
                            Button {
                                viewModel.applyTargetToSelection()
                            } label: {
                                if viewModel.isWorking {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text("应用设置")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canApply)
                        }
                    }
                    .padding(.vertical, 4)
                }

                DisclosureGroup("执行日志", isExpanded: $viewModel.isLogExpanded) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.logs) { entry in
                                Text(entry.renderedLine)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(entry.level.color)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(10)
                    }
                    .frame(minHeight: 120, idealHeight: 160)
                }
                .padding(.top, 4)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("请选择一个文件后缀")
                        .font(.headline)
                    Text("在左侧选择常用后缀，或添加自定义后缀。")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func appCard(_ app: HomeViewModel.ApplicationInfo) -> some View {
        HStack(spacing: 10) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

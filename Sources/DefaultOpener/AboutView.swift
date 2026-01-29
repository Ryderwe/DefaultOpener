import SwiftUI

struct AboutView: View {
    private let githubURL = URL(string: "https://github.com/Ryderwe/DefaultOpener")!
    @StateObject private var viewModel = AboutViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DefaultOpener")
                .font(.title2.weight(.semibold))
            Text("一个用于批量管理文件后缀默认打开应用的小工具。")
                .foregroundStyle(.secondary)

            GroupBox("版本") {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前版本：\(viewModel.currentVersion)")
                            .font(.callout)
                        statusLine
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("检查更新") { viewModel.checkForUpdates(showAlertOnNew: true) }
                        .disabled(isChecking)
                }
                .padding(.vertical, 4)
            }

            GroupBox("项目地址") {
                VStack(alignment: .leading, spacing: 6) {
                    Link(destination: githubURL) {
                        Label("github.com/Ryderwe/DefaultOpener", systemImage: "link")
                    }
                    .font(.callout)

                    Text("如果这个工具对你有帮助，欢迎在 GitHub 上点个 Star。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            Divider()
            Text("说明：某些类型的默认应用可能会被系统缓存影响，设置后可能需要重新打开 Finder 或重启相关应用后生效。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(16)
        .navigationTitle("关于")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            viewModel.checkForUpdates(showAlertOnNew: false)
        }
        .alert("发现新版本", isPresented: $viewModel.showUpdateAlert) {
            Button("前往下载") {
                if case .updateAvailable(let latest) = viewModel.status {
                    viewModel.open(latest.htmlURL)
                }
            }
            Button("稍后") { }
        } message: {
            if case .updateAvailable(let latest) = viewModel.status {
                Text("最新版本：\(latest.version)\n当前版本：\(viewModel.currentVersion)")
            } else {
                Text("已发现新版本。")
            }
        }
    }

    private var isChecking: Bool {
        if case .checking = viewModel.status { return true }
        return false
    }

    @ViewBuilder
    private var statusLine: some View {
        switch viewModel.status {
        case .idle:
            Text("自动检查更新已就绪。")
        case .checking:
            Text("正在检查更新…")
        case .upToDate:
            Text("已是最新版本。")
        case .updateAvailable(let latest):
            HStack(spacing: 6) {
                Text("有新版本：\(latest.version)")
                Button("打开 Release") { viewModel.open(latest.htmlURL) }
                    .buttonStyle(.link)
            }
        case .failed(let message):
            Text("检查失败：\(message)")
        }
    }
}

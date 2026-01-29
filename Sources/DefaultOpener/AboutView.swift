import SwiftUI

struct AboutView: View {
    private let githubURL = URL(string: "https://github.com/Ryderwe/DefaultOpener")!

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DefaultOpener")
                .font(.title2.weight(.semibold))
            Text("一个用于批量管理文件后缀默认打开应用的小工具。")
                .foregroundStyle(.secondary)

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
    }
}

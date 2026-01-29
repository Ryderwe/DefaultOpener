import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DefaultOpener")
                .font(.title2.weight(.semibold))
            Text("一个用于批量管理文件后缀默认打开应用的小工具。")
                .foregroundStyle(.secondary)
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


import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("提示") {
                Text("默认打开方式的修改会写入到当前用户的 Launch Services 关联设置。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(16)
        .navigationTitle("设置")
    }
}


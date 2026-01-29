# DefaultOpener

macOS 原生工具：批量管理文件后缀的默认打开应用（Launch Services）。

项目地址：`https://github.com/Ryderwe/DefaultOpener`（如果对你有帮助，欢迎点个 Star）

## 功能

- 左侧导航：主页 / 设置 / 关于
- 主页双栏：
  - 左栏：常用后缀列表 + 自定义后缀（可添加/删除，自动持久化）
  - 右栏：显示所选后缀当前默认应用；选择目标应用后一键应用
- 将后缀转换为 UTI（Uniform Type Identifier），并调用 Launch Services 设置默认关联：
  - 读取：`LSCopyDefaultRoleHandlerForContentType`
  - 写入：`LSSetDefaultRoleHandlerForContentType`
- 内置执行日志（包含 UTI、OSStatus 错误信息等）

## 系统要求

- macOS 13+（`Package.swift` 里指定）
- Xcode 15+ 或已安装 Swift toolchain（能运行 `swift build` / `swift run`）

## 运行

在项目根目录：

```bash
swift build
swift run
```

也可以用 Xcode 直接打开该目录（Swift Package）后 Run。

## 使用说明

1. 打开 **主页**
2. 在左栏选择一个后缀（如 `.png`），右栏会自动读取并显示“当前默认应用”
3. 点击“选择应用…”选中一个 `.app` 作为目标应用
4. 点击“应用设置”写入默认关联
5. 没有预设的后缀可以在左栏底部输入并“添加”（支持 `webp, avif` 这种逗号分隔输入）

## 注意事项 / 常见问题

- **UTI 转换失败**：系统无法识别的后缀可能无法转换为 UTI，因此无法设置默认应用（会在日志中提示）。
- **设置后未立即生效**：Launch Services 可能有缓存，偶发需要重启 Finder / 重新打开相关应用后才完全生效。
- **权限问题**：如果系统返回权限相关错误，日志会记录对应的 `OSStatus` 说明。

## 代码结构（MVVM）

- 入口：`Sources/DefaultOpener/DefaultOpenerApp.swift`
- 导航：`Sources/DefaultOpener/ContentView.swift`
- 主页 UI：`Sources/DefaultOpener/HomeView.swift`
- 主页逻辑：`Sources/DefaultOpener/HomeViewModel.swift`
- 设置页：`Sources/DefaultOpener/SettingsView.swift`
- 关于页：`Sources/DefaultOpener/AboutView.swift`

## 图标

仓库内包含一个简单的图标生成脚本与产物：

- 生成脚本：`Scripts/generate_app_icon.swift`
- PNG：`Assets/AppIcon-1024.png`
- ICNS：`Assets/DefaultOpener.icns`

重新生成：

```bash
swift Scripts/generate_app_icon.swift
```


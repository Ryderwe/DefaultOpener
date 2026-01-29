import AppKit
import CoreServices
import Foundation
import Security
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class HomeViewModel: ObservableObject {
    struct ApplicationInfo: Equatable {
        let url: URL?
        let bundleIdentifier: String
        let displayName: String
        let icon: NSImage
    }

    enum LogLevel: String {
        case info = "INFO"
        case success = "OK"
        case warning = "WARN"
        case error = "ERR"

        var color: Color {
            switch self {
            case .info: return .secondary
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }

    struct LogEntry: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let level: LogLevel
        let message: String

        var renderedLine: String {
            let timestamp = date.formatted(.dateTime.year().month().day().hour().minute().second())
            return "[\(timestamp)] [\(level.rawValue)] \(message)"
        }
    }

    private enum DefaultsKey {
        static let customExtensions = "DefaultOpener.customExtensions.v1"
    }

    @Published var customExtensionInput: String = ""
    @Published var selectedExtension: String? {
        didSet { refreshSelection() }
    }
    @Published private(set) var selectedUTI: String?
    @Published private(set) var currentDefaultApp: ApplicationInfo?
    @Published private(set) var targetApp: ApplicationInfo?
    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var isWorking: Bool = false
    @Published var isLogExpanded: Bool = false
    @Published private(set) var customExtensions: [String] = []

    let presetExtensions: [String] = [
        "png", "jpg", "jpeg", "gif", "webp", "heic", "tiff", "svg",
        "pdf",
        "txt", "md",
        "json", "yaml", "yml",
        "zip",
        "mp4", "mov"
    ]

    var canApply: Bool {
        !isWorking && selectedExtension != nil && targetApp != nil && selectedUTI != nil
    }

    var currentDefaultAppPlaceholder: String {
        if selectedUTI == nil {
            return "无法识别该后缀的 UTI（可能是未知类型）。"
        }
        return "当前没有可读取的默认应用。"
    }

    init() {
        loadCustomExtensions()
    }

    func addCustomExtensions() {
        let candidates = Self.parseExtensions(from: customExtensionInput)
        guard !candidates.isEmpty else { return }

        let existing = Set(customExtensions)
        let newOnes = candidates.filter { !existing.contains($0) && !presetExtensions.contains($0) }
        guard !newOnes.isEmpty else {
            customExtensionInput = ""
            return
        }

        customExtensions.append(contentsOf: newOnes)
        customExtensions.sort()
        saveCustomExtensions()
        customExtensionInput = ""
        appendLog("已添加自定义后缀：\(newOnes.map { ".\($0)" }.joined(separator: ", "))", level: .info)

        if selectedExtension == nil, let first = newOnes.first {
            selectedExtension = first
        }
    }

    func removeCustomExtensions(at offsets: IndexSet) {
        let removed = offsets.compactMap { idx in customExtensions.indices.contains(idx) ? customExtensions[idx] : nil }
        customExtensions.remove(atOffsets: offsets)
        saveCustomExtensions()
        if !removed.isEmpty {
            appendLog("已移除自定义后缀：\(removed.map { ".\($0)" }.joined(separator: ", "))", level: .info)
        }
    }

    func removeCustomExtension(_ ext: String) {
        guard let idx = customExtensions.firstIndex(of: ext) else { return }
        customExtensions.remove(at: idx)
        saveCustomExtensions()
        appendLog("已移除自定义后缀：.\(ext)", level: .info)
    }

    func refreshSelection() {
        guard let ext = selectedExtension else {
            selectedUTI = nil
            currentDefaultApp = nil
            targetApp = nil
            return
        }

        let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
        let uti = Self.utiIdentifier(forFilenameExtension: cleanExt)
        selectedUTI = uti
        currentDefaultApp = nil
        targetApp = nil

        guard let uti else {
            appendLog("后缀 .\(cleanExt) 无法转换为 UTI。", level: .warning)
            return
        }

        let bundleID = LSCopyDefaultRoleHandlerForContentType(uti as CFString, LSRolesMask.all)?
            .takeRetainedValue() as String?

        guard let bundleID, !bundleID.isEmpty else {
            appendLog("读取 .\(cleanExt) (\(uti)) 当前默认应用：未设置/不可用。", level: .info)
            return
        }

        let info = Self.applicationInfo(forBundleIdentifier: bundleID)
        currentDefaultApp = info
        targetApp = info
        appendLog("读取 .\(cleanExt) (\(uti)) 当前默认应用：\(bundleID)", level: .info)
    }

    func useCurrentAsTarget() {
        guard let currentDefaultApp else { return }
        targetApp = currentDefaultApp
    }

    func pickTargetApplication() {
        let panel = NSOpenPanel()
        panel.title = "选择应用程序"
        panel.prompt = "选择"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = false
        panel.resolvesAliases = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.applicationBundle]

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        guard let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier else {
            appendLog("无法读取应用的 Bundle Identifier：\(url.path)", level: .error)
            return
        }

        targetApp = Self.applicationInfo(forBundleIdentifier: bundleID, fallbackURL: url)
        appendLog("已选择目标应用：\(bundleID)", level: .info)
    }

    func applyTargetToSelection() {
        guard let ext = selectedExtension else { return }
        guard let uti = selectedUTI else {
            appendLog("后缀 .\(ext) 无法识别 UTI，无法设置。", level: .error)
            return
        }
        guard let app = targetApp else {
            appendLog("请先选择目标应用。", level: .warning)
            return
        }

        isWorking = true
        defer { isWorking = false }

        let status = LSSetDefaultRoleHandlerForContentType(
            uti as CFString,
            LSRolesMask.all,
            app.bundleIdentifier as CFString
        )

        if status == noErr {
            let current = LSCopyDefaultRoleHandlerForContentType(uti as CFString, LSRolesMask.all)?
                .takeRetainedValue() as String?
            if current == app.bundleIdentifier {
                appendLog("已设置 .\(ext) (\(uti)) 默认应用为 \(app.displayName)。", level: .success)
            } else if let current {
                appendLog("已写入 .\(ext) (\(uti))，但当前默认值为 \(current)。可能需要刷新系统缓存。", level: .warning)
            } else {
                appendLog("已写入 .\(ext) (\(uti))，但无法读取当前默认值。", level: .warning)
            }
            refreshSelection()
        } else {
            let message = Self.osStatusMessage(status) ?? "未知错误"
            appendLog("设置 .\(ext) (\(uti)) 失败：\(message) (OSStatus=\(status))", level: .error)
        }
    }

    func clearLogs() {
        logs.removeAll()
    }

    private func loadCustomExtensions() {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKey.customExtensions) else {
            customExtensions = []
            return
        }
        do {
            customExtensions = try JSONDecoder().decode([String].self, from: data)
        } catch {
            customExtensions = []
        }
    }

    private func saveCustomExtensions() {
        do {
            let data = try JSONEncoder().encode(customExtensions)
            UserDefaults.standard.set(data, forKey: DefaultsKey.customExtensions)
        } catch {
            appendLog("保存自定义后缀失败：\(error.localizedDescription)", level: .error)
        }
    }

    private func appendLog(_ message: String, level: LogLevel) {
        logs.append(LogEntry(date: Date(), level: level, message: message))
        if level == .error || level == .warning {
            isLogExpanded = true
        }
    }

    private static func parseExtensions(from input: String) -> [String] {
        input
            .split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == "\t" || $0 == " " })
            .map { String($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.hasPrefix(".") ? String($0.dropFirst()) : $0 }
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
            .filter { $0.range(of: #"^[a-z0-9]+$"#, options: .regularExpression) != nil }
    }

    private static func utiIdentifier(forFilenameExtension ext: String) -> String? {
        if let type = UTType(filenameExtension: ext) {
            return type.identifier
        }
        if let type = UTType(tag: ext, tagClass: .filenameExtension, conformingTo: .data) {
            return type.identifier
        }
        return nil
    }

    private static func applicationInfo(forBundleIdentifier bundleID: String, fallbackURL: URL? = nil) -> ApplicationInfo {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) ?? fallbackURL

        let displayName: String = {
            guard let url, let bundle = Bundle(url: url) else { return bundleID }
            return (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? url.deletingPathExtension().lastPathComponent
        }()

        let icon: NSImage = {
            if let url {
                let img = NSWorkspace.shared.icon(forFile: url.path)
                img.size = NSSize(width: 128, height: 128)
                return img
            }
            let img = NSImage(size: NSSize(width: 128, height: 128))
            return img
        }()

        return ApplicationInfo(url: url, bundleIdentifier: bundleID, displayName: displayName, icon: icon)
    }

    private static func osStatusMessage(_ status: OSStatus) -> String? {
        if let msg = SecCopyErrorMessageString(status, nil) {
            return msg as String
        }
        return nil
    }
}

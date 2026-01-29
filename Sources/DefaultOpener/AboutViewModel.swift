import AppKit
import Foundation

@MainActor
final class AboutViewModel: ObservableObject {
    struct LatestRelease: Equatable {
        let version: String
        let title: String?
        let htmlURL: URL
        let publishedAt: Date?
    }

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(LatestRelease)
        case failed(String)
    }

    @Published private(set) var currentVersion: String
    @Published private(set) var status: Status = .idle
    @Published var showUpdateAlert: Bool = false

    private let repoOwner = "Ryderwe"
    private let repoName = "DefaultOpener"

    init() {
        currentVersion = AboutViewModel.readCurrentAppVersion() ?? "dev"
    }

    func checkForUpdates(showAlertOnNew: Bool = true) {
        Task { @MainActor in
            await checkForUpdatesAsync(showAlertOnNew: showAlertOnNew)
        }
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func checkForUpdatesAsync(showAlertOnNew: Bool) async {
        status = .checking
        do {
            let latest = try await fetchLatestRelease()
            if AboutViewModel.isNewerVersion(latest.version, than: currentVersion) {
                status = .updateAvailable(latest)
                if showAlertOnNew {
                    showUpdateAlert = true
                }
            } else {
                status = .upToDate
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private func fetchLatestRelease() async throws -> LatestRelease {
        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("DefaultOpener/\(currentVersion) (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let message: String
            switch http.statusCode {
            case 403:
                message = "请求被拒绝（可能触发 GitHub 频率限制）。"
            case 404:
                message = "未找到 Release。"
            default:
                message = "请求失败（HTTP \(http.statusCode)）。"
            }
            throw NSError(domain: "DefaultOpener.UpdateCheck", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let decoded = try JSONDecoder.github.decode(GitHubReleaseResponse.self, from: data)
        let version = AboutViewModel.normalizeVersion(decoded.tagName) ?? decoded.tagName
        let htmlURL = decoded.htmlURL
        return LatestRelease(version: version, title: decoded.name, htmlURL: htmlURL, publishedAt: decoded.publishedAt)
    }
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let name: String?
    let htmlURL: URL
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlURL = "html_url"
        case publishedAt = "published_at"
    }
}

private extension JSONDecoder {
    static var github: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

private extension AboutViewModel {
    static func readCurrentAppVersion() -> String? {
        if let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !v.isEmpty {
            return v
        }
        return nil
    }

    static func normalizeVersion(_ s: String) -> String? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let noPrefix = trimmed.hasPrefix("v") || trimmed.hasPrefix("V") ? String(trimmed.dropFirst()) : trimmed
        let kept = noPrefix.filter { $0.isNumber || $0 == "." }
        return kept.isEmpty ? nil : kept
    }

    static func isNewerVersion(_ a: String, than b: String) -> Bool {
        guard let av = normalizeVersion(a), let bv = normalizeVersion(b) else { return false }
        let ap = av.split(separator: ".").compactMap { Int($0) }
        let bp = bv.split(separator: ".").compactMap { Int($0) }
        guard !ap.isEmpty, !bp.isEmpty else { return false }

        let n = max(ap.count, bp.count)
        for i in 0..<n {
            let ai = i < ap.count ? ap[i] : 0
            let bi = i < bp.count ? bp[i] : 0
            if ai != bi { return ai > bi }
        }
        return false
    }
}

import SwiftUI

struct ContentView: View {
    enum SidebarItem: Hashable, CaseIterable, Identifiable {
        case home
        case settings
        case about

        var id: Self { self }

        var title: String {
            switch self {
            case .home: return "主页"
            case .settings: return "设置"
            case .about: return "关于"
            }
        }

        var systemImage: String {
            switch self {
            case .home: return "house"
            case .settings: return "gearshape"
            case .about: return "info.circle"
            }
        }
    }

    @State private var selection: SidebarItem? = .home

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.systemImage)
                    .tag(item as SidebarItem?)
            }
            .listStyle(.sidebar)
            .navigationTitle("DefaultOpener")
        } detail: {
            switch selection ?? .home {
            case .home:
                HomeView()
            case .settings:
                SettingsView()
            case .about:
                AboutView()
            }
        }
    }
}

import SwiftUI

extension Color {
    static let sukoonBg   = Color(red: 17/255,  green: 7/255,  blue: 4/255)
    static let sukoonCard = Color(red: 27/255,  green: 13/255, blue: 7/255)
    static let sukoonSep  = Color(white: 1, opacity: 0.08)
}

struct ContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabView(selection: $state.selectedTab) {
            FormView()
                .tabItem { Label("Form",     systemImage: "doc.text.fill") }
                .tag(0)
            QuoteView()
                .tabItem { Label("Quote",    systemImage: "chart.bar.doc.horizontal.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(.white)
    }
}

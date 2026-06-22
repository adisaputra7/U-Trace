import SwiftUI

@main
struct U_TraceApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(environment.session)
                .preferredColorScheme(.dark)
                .task { await environment.bootstrap() }
        }
    }
}

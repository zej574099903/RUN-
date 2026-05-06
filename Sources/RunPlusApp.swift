import SwiftUI

@main
struct RunPlusApp: App {
    @StateObject private var healthManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(healthManager)
        }
    }
}

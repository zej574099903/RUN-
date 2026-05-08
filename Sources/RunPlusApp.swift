import SwiftUI

@main
struct RunPlusApp: App {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(healthManager)
                .environmentObject(subscriptionManager)
        }
    }
}

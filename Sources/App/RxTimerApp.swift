import SwiftUI

@main
struct RxTimerApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Migrate old UserDefaults keys from Quick Start to LastUsedConfig
        migrateUserDefaultsKeys()

        // Request notification permissions on launch
        NotificationService.shared.requestAuthorization()

        // Configure app appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

    private func configureAppearance() {
        // Customize navigation bar appearance for dark mode
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.078, green: 0.078, blue: 0.078, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        // Customize tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.078, green: 0.078, blue: 0.078, alpha: 1.0)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    // MARK: - UserDefaults Migration

    /// Migrate Quick Start UserDefaults keys to LastUsedConfig keys (one-time migration)
    private func migrateUserDefaultsKeys() {
        let defaults = UserDefaults.standard
        let migrationKey = "HasMigratedQuickStartKeys"

        // Only migrate once
        guard !defaults.bool(forKey: migrationKey) else { return }

        // Migrate each timer type
        for timerType in TimerType.allCases {
            let oldKey = "QuickStart.LastConfig.\(timerType.rawValue)"
            let newKey = "LastUsedConfig.\(timerType.rawValue)"

            // If old key exists and new key doesn't, copy the data
            if let data = defaults.data(forKey: oldKey), defaults.data(forKey: newKey) == nil {
                defaults.set(data, forKey: newKey)
            }

            // Remove old key
            defaults.removeObject(forKey: oldKey)
        }

        // Mark migration as complete
        defaults.set(true, forKey: migrationKey)
        defaults.synchronize()
    }
}

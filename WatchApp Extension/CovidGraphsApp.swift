//
//  CovidGraphsApp.swift
//  WatchApp Extension
//
//  Created by Miguel de Icaza on 10/9/20.
//

import SwiftUI

@main
struct CovidGraphsApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

//
//  Demo1App.swift
//  Demo1
//
//  Created by Lambda on 8/15/24.
//

import SwiftUI

@main
struct Demo1App: App {
    @StateObject private var notView = NotView()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notView)
             
        }
    }
}

//
//  To_FishApp.swift
//  To Fish
//
//  Created by alya Alabdulrahim on 10/09/1447 AH.
//
import SwiftUI
import SwiftData

@main
struct To_FishApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([TaskModel.self, Subtask.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRoot()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct AppRoot: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TaskViewModel()

    var body: some View {
        SplashView(viewModel: viewModel)
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
    }
}

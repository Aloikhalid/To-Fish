//
//  To_FishApp.swift
//  To Fish
//
//  Created by alya Alabdulrahim on 10/09/1447 AH.
//
import SwiftUI
import SwiftData
import UserNotifications
 
func registerFonts() {
    guard let fontURL = Bundle.main.url(forResource: "Kavoon-Regular", withExtension: "ttf") else { return }
    CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
}
 
 
@main
struct ToFishApp: App {
   
    @StateObject private var viewModel = TaskViewModel()
    
    // Create the model container for persistent storage
    let modelContainer: ModelContainer
 
    init() {
        registerFonts()
        configureAudioSession()
        NotificationManager.requestPermission()
        
        // Set up SwiftData container for persistent storage
        do {
            modelContainer = try ModelContainer(for: TaskModel.self, Subtask.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
 
    var body: some Scene {
        WindowGroup {
            SplashView(viewModel: viewModel)
                .modelContainer(modelContainer)
                .onAppear {
                    // Configure the view model with the model context
                    viewModel.configure(modelContext: modelContainer.mainContext)
                }
        }
    }
}

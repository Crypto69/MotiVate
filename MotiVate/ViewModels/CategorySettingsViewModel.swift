//
//  CategorySettingsViewModel.swift
//  MotiVate
//
//  Created by Chris Venter on 25/5/2025.
//

import SwiftUI
import Combine
import WidgetKit

/// ViewModel for the category settings screen.
/// Handles fetching categories from Supabase and managing user selections.
class CategorySettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The list of all available categories fetched from Supabase.
    @Published var categories: [CategoryItem] = []
    
    /// The set of selected category IDs (stored as strings for UserDefaults compatibility).
    @Published var selectedCategoryIDs: Set<String> = []
    
    /// Indicates whether categories are currently being loaded.
    @Published var isLoading: Bool = false
    
    /// Error message to display if category fetching fails.
    @Published var errorMessage: String? = nil
    
    // MARK: - Constants
    
    /// The App Group ID used for sharing UserDefaults between the main app and widget.
    private let appGroupID = "group.myaccessibility.ai.motivate"
    
    /// The UserDefaults key for storing selected category IDs.
    private let userDefaultsKey = "selectedCategoryIDs"
    
    /// The widget kind identifier for reloading timelines.
    private let widgetKind = "MotivationWidgetExtension"
    
    // MARK: - Private Properties
    
    /// Set of cancellables for managing Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Load any previously selected categories from UserDefaults
        loadSelectedCategories()
        
        // Set up automatic saving of selected categories when they change
        $selectedCategoryIDs
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Debounce to avoid excessive writes
            .sink { [weak self] _ in
                self?.saveSelectedCategories()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Fetches all categories from Supabase.
    /// Updates the `categories`, `isLoading`, and `errorMessage` properties.
    @MainActor
    func fetchCategoriesFromSupabase() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch categories directly as CategoryItem objects
            let fetchedCategories = try await SupabaseClient.shared.fetchAllCategories()
            
            self.categories = fetchedCategories
            self.isLoading = false
            print("CategorySettingsViewModel: Successfully fetched \(fetchedCategories.count) categories")
        } catch {
            self.errorMessage = "Failed to load categories: \(error.localizedDescription)"
            self.isLoading = false
            print("CategorySettingsViewModel: Error fetching categories - \(error)")
        }
    }
    
    /// Toggles the selection state of a category.
    /// - Parameter categoryID: The ID of the category to toggle.
    func toggleCategory(id: Int64) {
        let idString = String(id)
        
        if selectedCategoryIDs.contains(idString) {
            selectedCategoryIDs.remove(idString)
        } else {
            selectedCategoryIDs.insert(idString)
        }
        
        // Note: No need to call saveSelectedCategories() here as it's handled by the $selectedCategoryIDs publisher
    }
    
    /// Checks if a category is currently selected.
    /// - Parameter categoryID: The ID of the category to check.
    /// - Returns: `true` if the category is selected, `false` otherwise.
    func isCategorySelected(id: Int64) -> Bool {
        selectedCategoryIDs.contains(String(id))
    }
    
    // MARK: - Private Methods
    
    /// Loads selected category IDs from UserDefaults.
    private func loadSelectedCategories() {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            print("CategorySettingsViewModel: Failed to access App Group UserDefaults for suite: \(appGroupID)")
            return
        }
        
        let stringArray = userDefaults.stringArray(forKey: userDefaultsKey) ?? []
        self.selectedCategoryIDs = Set(stringArray)
        print("CategorySettingsViewModel: Loaded \(self.selectedCategoryIDs.count) selected category IDs from UserDefaults")
    }
    
    /// Saves selected category IDs to UserDefaults.
    private func saveSelectedCategories() {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            print("CategorySettingsViewModel: Failed to access App Group UserDefaults for suite: \(appGroupID) for saving")
            return
        }
        
        userDefaults.set(Array(selectedCategoryIDs), forKey: userDefaultsKey)
        print("CategorySettingsViewModel: Saved \(selectedCategoryIDs.count) selected category IDs to UserDefaults")
        
        // Reload widget timelines to reflect the changes immediately
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        print("CategorySettingsViewModel: Requested widget timeline reload")
    }
}
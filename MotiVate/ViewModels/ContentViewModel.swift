//
//  ContentViewModel.swift
//  MotiVate
//
//  Created by Chris Venter on 25/5/2025.
//

import SwiftUI
import Combine // For @Published if more complex state arises, though not strictly needed for this simple version

// ImageResponse struct is now defined in SharedModels.swift and should be accessible.

@MainActor
class ContentViewModel: ObservableObject {
    @Published var motivationalImage: Image?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isFromOffline: Bool = false

    private let appGroupID = "group.myaccessibility.ai.motivate"
    private let userDefaultsKey = "selectedCategoryIDs"

    init() {
        Task {
            await fetchMotivationalImage()
        }
    }

    func fetchMotivationalImage() async {
        isLoading = true
        errorMessage = nil
        motivationalImage = nil // Clear previous image
        isFromOffline = false

        // 1. Get selected category IDs from UserDefaults
        let userDefaults = UserDefaults(suiteName: appGroupID)
        let selectedCategoryIDsStrings = userDefaults?.stringArray(forKey: userDefaultsKey) ?? []
        let categoryIDsForRPC: [Int64]? = selectedCategoryIDsStrings.isEmpty ? nil : selectedCategoryIDsStrings.compactMap { Int64($0) }
        
        print("ContentViewModel: Fetching image with category IDs: \(categoryIDsForRPC?.map(String.init).joined(separator: ", ") ?? "None (fully random)")")

        // 2. Use the new getImageWithFallback method from SupabaseClient
        let (imageData, fromOffline, imageId) = await SupabaseClient.shared.getImageWithFallback(categoryIds: categoryIDsForRPC)
        
        if let imageData = imageData {
            // 3. Convert data to appropriate Image type
            #if os(macOS)
            if let nsImage = NSImage(data: imageData) {
                self.motivationalImage = Image(nsImage: nsImage)
                self.isFromOffline = fromOffline
                self.isLoading = false
                
                if fromOffline {
                    print("ContentViewModel: Successfully loaded offline image, size: \(imageData.count) bytes")
                } else {
                    print("ContentViewModel: Successfully loaded online image, ID: \(imageId ?? -1), size: \(imageData.count) bytes")
                }
            } else {
                self.errorMessage = "Failed to convert image data"
                self.isLoading = false
                print("ContentViewModel: Failed to convert image data to NSImage")
            }
            #elseif os(iOS) || os(watchOS) || os(tvOS)
            if let uiImage = UIImage(data: imageData) {
                self.motivationalImage = Image(uiImage: uiImage)
                self.isFromOffline = fromOffline
                self.isLoading = false
                
                if fromOffline {
                    print("ContentViewModel: Successfully loaded offline image, size: \(imageData.count) bytes")
                } else {
                    print("ContentViewModel: Successfully loaded online image, ID: \(imageId ?? -1), size: \(imageData.count) bytes")
                }
            } else {
                self.errorMessage = "Failed to convert image data"
                self.isLoading = false
                print("ContentViewModel: Failed to convert image data to UIImage")
            }
            #endif
        } else {
            self.errorMessage = fromOffline ? "No offline images available" : "Network error and no offline fallback"
            self.isLoading = false
            print("ContentViewModel: Failed to load any image (both online and offline failed)")
        }
    }
}
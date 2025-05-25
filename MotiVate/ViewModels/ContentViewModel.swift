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

    private let appGroupID = "group.ai.myaccessibility.motivate"
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

        do {
            // 1. Get selected category IDs from UserDefaults
            let userDefaults = UserDefaults(suiteName: appGroupID)
            let selectedCategoryIDsStrings = userDefaults?.stringArray(forKey: userDefaultsKey) ?? []
            let categoryIDsForRPC: [Int64]? = selectedCategoryIDsStrings.isEmpty ? nil : selectedCategoryIDsStrings.compactMap { Int64($0) }
            
            print("ContentViewModel: Fetching image with category IDs: \(categoryIDsForRPC?.map(String.init).joined(separator: ", ") ?? "None (fully random)")")

            // 2. Call RPC to get image metadata
            let imageResponse: ImageResponse = try await SupabaseClient.shared.client // Use shared ImageResponse
                .rpc("get_random_image", params: ["category_ids": categoryIDsForRPC])
                .single()
                .execute()
                .value

            print("ContentViewModel: RPC Response - ID: \(imageResponse.id), Filename: \(imageResponse.image_url)")

            // 3. Construct full image URL
            guard let imageURL = SupabaseClient.shared.publicImageURL(filename: imageResponse.image_url) else {
                throw MotivDBError.urlConversionFailed // Or a more specific error
            }
            print("ContentViewModel: Constructed image URL: \(imageURL.absoluteString)")

            // 4. Download image data
            let (data, urlResponse) = try await URLSession.shared.data(from: imageURL)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? -1
                print("ContentViewModel: Image download failed. Status code: \(statusCode)")
                throw NSError(domain: "ImageDownloadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to download image. Status: \(statusCode)"])
            }
            
            print("ContentViewModel: Downloaded \(data.count) bytes.")

            // 5. Convert data to NSImage (for macOS) then to SwiftUI Image
            #if os(macOS)
            if let nsImage = NSImage(data: data) {
                self.motivationalImage = Image(nsImage: nsImage)
            } else {
                throw NSError(domain: "ImageConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert downloaded data to NSImage."])
            }
            #elseif os(iOS) || os(watchOS) || os(tvOS)
            if let uiImage = UIImage(data: data) {
                self.motivationalImage = Image(uiImage: uiImage)
            } else {
                throw NSError(domain: "ImageConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert downloaded data to UIImage."])
            }
            #endif
            
            self.isLoading = false
        } catch {
            print("ContentViewModel: Error fetching motivational image - \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
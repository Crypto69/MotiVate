//
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import Supabase
import Foundation

// Custom error for clarity when fetching data
enum MotivDBError: Error {
    case emptyBucket       // Bucket has no files
    case imageFetchFailed  // Could not fetch image URL
    case urlConversionFailed // Could not convert string to URL
    case categoriesFetchFailed // Could not fetch categories
}

struct SupabaseClient {
    static let shared = SupabaseClient() // Singleton instance

    // Public constants for storage configuration
    public static let imageBucketName = "motivational-images"
    // Note: The leading and trailing slashes are important for URL construction.
    // The base Supabase URL already ends without a slash.
    // The bucket name is followed by a slash, then the filename.
    public static let imageStoragePublicPath = "storage/v1/object/public/" // No leading slash if appended to URL.absoluteString

    // Make client accessible for RPC calls from other modules if needed,
    // or consider adding specific RPC helper methods here.
    // For now, assuming direct access is intended as per Provider.swift usage.
    let client: Supabase.SupabaseClient // Changed from private to internal (default) or public if needed
    let baseURL: URL // Store the base URL for internal use

    private init() { // Private initializer for singleton
        // --- ⚠️ IMPORTANT: REPLACE WITH YOUR ACTUAL SUPABASE DETAILS ---
        let supabaseURLString = "https://vwvhpnxnumfvxasbopcq.supabase.co" // e.g., "https://xyzabc.supabase.co"
        let supabaseAnonKeyString = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3dmhwbnhudW1mdnhhc2JvcGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc3MjI1MTEsImV4cCI6MjA2MzI5ODUxMX0.6fXIgzKlqrZp-IWZ8m8JFgZb5pItGoLUVq2C8ubEOO0"
        // --- END IMPORTANT ---

        guard let supabaseURL = URL(string: supabaseURLString) else {
            fatalError("Invalid Supabase URL: \(supabaseURLString)")
        }
        self.baseURL = supabaseURL // Store the validated URL

        self.client = Supabase.SupabaseClient(
            supabaseURL: self.baseURL, // Use the stored baseURL
            supabaseKey: supabaseAnonKeyString
        )
    }

    /// Fetches a list of all files in the "motivational-images" bucket,
    /// picks one randomly, and returns its public URL.
    func randomImageURL() async throws -> URL {
        let storage = client.storage.from("motivational-images") // Ensure this matches your bucket name

        // 1. List all files at the root of the bucket
        let files: [FileObject]
        do {
            files = try await storage.list() // You can specify a 'path' if images are in a subfolder
        } catch {
            print("Error listing files: \(error)")
            throw MotivDBError.imageFetchFailed
        }

        // 2. Ensure the bucket is not empty and pick a random file
        guard let randomFile = files.randomElement() else {
            print("The 'motivational-images' bucket is empty or no files were found.")
            throw MotivDBError.emptyBucket
        }

        // 3. Get the public URL for the chosen file
        //    The path here is just the file name since we listed files at the root.
        let publicURL: URL
        do {
            publicURL = try storage.getPublicURL(path: randomFile.name)
        } catch {
            print("Error getting public URL for \(randomFile.name): \(error)")
            throw MotivDBError.urlConversionFailed
        }

        print("Selected image URL: \(publicURL.absoluteString)")
        return publicURL

        // Alternative for a *private* bucket (not used in this plan but good to know):
        // This would require users to be authenticated.
        // return try await storage.createSignedURL(path: randomFile.name, expiresIn: 3600) // URL valid for 1 hour
    }

    /// Constructs the full public URL for a given image filename in the configured bucket.
    public func publicImageURL(filename: String) -> URL? {
        var components = URLComponents()
        components.scheme = self.baseURL.scheme
        components.host = self.baseURL.host
        
        // Construct the full path, ensuring it starts with a single leading slash
        // and includes the double slash before the filename as per example.
        // SupabaseClient.imageStoragePublicPath = "storage/v1/object/public/"
        // SupabaseClient.imageBucketName = "motivational-images"
        let constructedPath = "/" + SupabaseClient.imageStoragePublicPath + SupabaseClient.imageBucketName + "//" + filename
        components.path = constructedPath
        
        // For debugging, uncomment to see the constructed parts:
        // print("SupabaseClient: publicImageURL - Scheme: \(components.scheme ?? "nil"), Host: \(components.host ?? "nil"), Path: \(components.path ?? "nil"), Result URL: \(components.url?.absoluteString ?? "nil")")
        
        return components.url
    }
    
    /// Fetches all categories from the 'categories' table.
    /// - Returns: An array of `CategoryItem` objects ordered by name.
    /// - Throws: `MotivDBError.categoriesFetchFailed` if the fetch operation fails.
    public func fetchAllCategories() async throws -> [CategoryItem] {
        do {
            // Query the 'categories' table directly using PostgREST, following Supabase documentation pattern
            let categories: [CategoryItem] = try await client.from("categories")
                .select() // Fetches all columns by default
                .order("name") // Sort alphabetically by name
                .execute()
                .value // Access the decoded value directly from the chained call
            
            print("SupabaseClient: fetchAllCategories - Successfully fetched \(categories.count) categories")
            return categories
        } catch {
            print("SupabaseClient: fetchAllCategories - Error fetching categories: \(error.localizedDescription)")
            throw MotivDBError.categoriesFetchFailed
        }
    }
}

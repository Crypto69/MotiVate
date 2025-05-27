//
//  CategorySettingsView.swift
//  MotiVate
//
//  Created by Chris Venter on 25/5/2025.
//

import SwiftUI

/// A view that allows users to select which categories of motivational images
/// they want to see in the widget.
struct CategorySettingsView: View {
    // MARK: - Properties
    
    /// The view model that manages category data and selection state.
    @StateObject private var viewModel = CategorySettingsViewModel()
    /// Environment object to access the ContentViewModel for triggering image refreshes.
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom header above the list for full wrapping
            Text("Refine your message categories. If none are selected, images will be chosen randomly from all categories.")
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding([.top, .horizontal])

            List {
                Section {
                    if viewModel.isLoading && viewModel.categories.isEmpty {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if viewModel.categories.isEmpty {
                        emptyStateView
                    } else {
                        categoriesList
                    }
                } footer: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .padding(.top, 2)
                        Text("Right click on your desktop , select 'Edit Widgets', and then add the MotiVate widget to your home screen. The large size works best.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 12)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Motivation Categories")
        .onAppear {
            // Only fetch categories if we don't already have them
            if viewModel.categories.isEmpty && !viewModel.isLoading {
                Task {
                    await viewModel.fetchCategoriesFromSupabase()
                }
            }
        }
        .refreshable {
            // Allow pull-to-refresh to reload categories
            await viewModel.fetchCategoriesFromSupabase()
        }
    }
    
    // MARK: - Subviews
    
    /// View displayed when categories are being loaded.
    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Loading Categories...")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 32)
            Spacer()
        }
    }
    
    /// View displayed when there's an error loading categories.
    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Error Loading Categories")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    await viewModel.fetchCategoriesFromSupabase()
                }
            }) {
                Text("Try Again")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding(.vertical, 8)
    }
    
    /// View displayed when no categories are available.
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No Categories Available")
                .font(.headline)
            
            Text("There are currently no categories to choose from. Please try again later.")
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    await viewModel.fetchCategoriesFromSupabase()
                }
            }) {
                Text("Refresh")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding(.vertical, 8)
    }
    
    /// List of categories with toggle switches.
    private var categoriesList: some View {
        ForEach(viewModel.categories) { category in
            categoryRow(for: category)
        }
    }
    
    /// Individual row for a category with a toggle switch.
    private func categoryRow(for category: CategoryItem) -> some View {
        Toggle(isOn: Binding(
            get: { viewModel.isCategorySelected(id: category.id) },
            set: { newValue in // Capture the new value, though not strictly needed here as toggleCategory handles the logic
                viewModel.toggleCategory(id: category.id)
                // After toggling the category, trigger a refresh of the motivational image
                Task {
                    await contentViewModel.fetchMotivationalImage()
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                
                if let description = category.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Preview

#Preview {
    // Updated Preview to provide a mock ContentViewModel
    NavigationView {
        CategorySettingsView()
            .environmentObject(ContentViewModel()) // Provide a mock for preview
    }
}
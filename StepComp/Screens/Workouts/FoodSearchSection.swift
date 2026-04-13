//
//  FoodSearchSection.swift
//  FitComp
//

import SwiftUI

struct FoodSearchSection: View {
    @Binding var foodQuery: String
    @ObservedObject var viewModel: FoodLogViewModel
    var onSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SEARCH FOOD")
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundColor(FitCompColors.textSecondary)

            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(FitCompColors.textSecondary)
                    TextField("e.g. 2 eggs and toast", text: $foodQuery)
                        .font(.system(size: 14, weight: .medium))
                        .submitLabel(.search)
                        .onSubmit { onSearch() }
                }
                .padding(12)
                .background(FitCompColors.textSecondary.opacity(0.08))
                .cornerRadius(12)

                Button(action: onSearch) {
                    if viewModel.isSearching {
                        ProgressView()
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(FitCompColors.primary)
                    }
                }
                .disabled(viewModel.isSearching || foodQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }
        }
    }
}

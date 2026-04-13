//
//  MealEntryRow.swift
//  FitComp
//

import SwiftUI

struct MealEntryRow: View {
    let entry: FoodLogEntry
    @ObservedObject var viewModel: FoodLogViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.description)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)

                    HStack(spacing: 12) {
                        Text("\(Int(entry.totalCalories)) cal")
                            .font(.system(size: 12, weight: .black))
                        Text("P: \(Int(entry.totalProteinG))g")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FitCompColors.cyan)
                        Text("C: \(Int(entry.totalCarbsG))g")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FitCompColors.accent)
                        Text("F: \(Int(entry.totalFatG))g")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FitCompColors.purple)
                    }

                    Text(timeString(entry.loggedAt))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(FitCompColors.textTertiary)
                }

                Spacer()

                if let photoName = entry.photoFileName,
                   let image = viewModel.loadPhoto(named: photoName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if entry.items.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.items) { item in
                        HStack {
                            Text(item.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                            Spacer()
                            Text("\(Int(item.calories)) cal")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

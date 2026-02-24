//
//  ExercisePickerView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return Exercise.allExercises
        }
        return Exercise.search(searchText)
    }
    
    private var groupedExercises: [(String, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { exercise in
            String(exercise.name.prefix(1))
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search exercises", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(20)
                    
                    // Exercise list
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedExercises, id: \.0) { letter, exercises in
                                Section(header: sectionHeader(letter)) {
                                    ForEach(exercises) { exercise in
                                        ExerciseRow(exercise: exercise) {
                                            onSelect(exercise)
                                            HapticManager.shared.soft()
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sectionHeader(_ letter: String) -> some View {
        HStack {
            Text(letter)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(StepCompColors.background)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(exercise.targetMuscles)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(StepCompColors.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
}

//
//  SuggestedWorkoutsView.swift
//  FitComp
//

import SwiftUI

// MARK: - Card (embedded in WorkoutsView)

struct SuggestedWorkoutsCard: View {
    @Binding var showingSuggestions: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }

    var body: some View {
        Button(action: { showingSuggestions = true }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("SUGGESTED WORKOUTS")
                        .font(.system(size: 13, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(FitCompColors.textSecondary)
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FitCompColors.primary)
                }

                Text("Browse popular splits or pick muscles to train")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WorkoutSplitTemplate.allTemplates.prefix(4)) { template in
                            splitChip(template)
                        }
                    }
                }

                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 14, weight: .bold))
                    Text("Explore All Splits & Custom Builder")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FitCompColors.textSecondary.opacity(0.5))
                }
                .foregroundColor(FitCompColors.primary)
            }
            .padding(20)
            .background(cardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func splitChip(_ template: WorkoutSplitTemplate) -> some View {
        HStack(spacing: 6) {
            Image(systemName: template.icon)
                .font(.system(size: 11, weight: .bold))
            Text(template.name)
                .font(.system(size: 11, weight: .bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(FitCompColors.primary.opacity(0.1))
        .foregroundColor(FitCompColors.primary)
        .cornerRadius(20)
    }
}

// MARK: - Full Sheet

struct SuggestedWorkoutsSheet: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab = 0
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var generatedExercises: [WorkoutExercise] = []
    @State private var previewSplitDay: SplitDay?
    @State private var previewExercises: [WorkoutExercise] = []
    @State private var showingPreview = false
    @State private var previewTitle = ""
    @State private var showingSaveSchedule = false
    @State private var pendingSaveName = ""
    @State private var pendingSaveExercises: [WorkoutExercise] = []
    @State private var pendingSaveIsBatch = false
    @State private var pendingSaveBatchItems: [(name: String, exercises: [WorkoutExercise])] = []

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    tabPicker

                    ScrollView {
                        if selectedTab == 0 {
                            splitBrowserContent
                        } else {
                            musclePickerContent
                        }
                    }
                }
            }
            .navigationTitle("Suggested Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPreview) {
                WorkoutPreviewSheet(
                    title: previewTitle,
                    exercises: previewExercises,
                    workoutViewModel: workoutViewModel,
                    onDismissParent: { dismiss() }
                )
            }
            .sheet(isPresented: $showingSaveSchedule) {
                SaveWorkoutScheduleSheet(
                    workoutViewModel: workoutViewModel,
                    workoutName: pendingSaveName,
                    exercises: pendingSaveExercises,
                    isBatch: pendingSaveIsBatch,
                    batchItems: pendingSaveBatchItems,
                    onComplete: { dismiss() }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton("Popular Splits", tag: 0)
            tabButton("Pick Muscles", tag: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func tabButton(_ title: String, tag: Int) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tag } }) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedTab == tag ? FitCompColors.primary : FitCompColors.textSecondary)
                Rectangle()
                    .fill(selectedTab == tag ? FitCompColors.primary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Split Browser

    private var splitBrowserContent: some View {
        VStack(spacing: 16) {
            ForEach(WorkoutSplitTemplate.allTemplates) { template in
                splitCard(template)
            }
        }
        .padding(20)
        .padding(.bottom, 60)
    }

    private func splitCard(_ template: WorkoutSplitTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FitCompColors.primary)
                    .frame(width: 36, height: 36)
                    .background(FitCompColors.primary.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(FitCompColors.textPrimary)
                    Text(template.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }

                Spacer()

                Text("\(template.daysPerWeek)x/wk")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(FitCompColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(FitCompColors.primary.opacity(0.1))
                    .cornerRadius(10)
            }

            HStack(spacing: 4) {
                Image(systemName: "target")
                    .font(.system(size: 10, weight: .bold))
                Text(template.bestFor)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(FitCompColors.accent)

            Text(template.scheduleExample)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(FitCompColors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(FitCompColors.textSecondary.opacity(0.06))
                .cornerRadius(8)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(template.pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: 4) {
                            Text("+")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(FitCompColors.green)
                            Text(pro)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(template.cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: 4) {
                            Text("−")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(FitCompColors.error)
                            Text(con)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(template.days) { day in
                        Button(action: { openPreview(day: day) }) {
                            VStack(spacing: 4) {
                                Text(day.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text(day.muscleGroups.map(\.rawValue).joined(separator: ", "))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(FitCompColors.textSecondary)
                                    .lineLimit(1)
                                if !day.pinnedExercises.isEmpty {
                                    Text("\(day.pinnedExercises.count) exercises")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(FitCompColors.primary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(FitCompColors.textSecondary.opacity(0.06))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            Button(action: { addFullSplit(template) }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add All \(template.days.count) Workouts")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FitCompColors.primary)
                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                .cornerRadius(14)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Muscle Picker

    private var musclePickerContent: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you want to train?")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(FitCompColors.textPrimary)
                Text("Select muscle groups and we'll build a workout for you")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            muscleGrid

            if !selectedMuscles.isEmpty {
                generateButton
            }

            if !generatedExercises.isEmpty {
                generatedPreview
            }
        }
        .padding(20)
        .padding(.bottom, 60)
    }

    private var muscleGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(MuscleGroup.allCases) { group in
                let isSelected = selectedMuscles.contains(group)
                Button(action: {
                    if isSelected {
                        selectedMuscles.remove(group)
                    } else {
                        selectedMuscles.insert(group)
                    }
                    generatedExercises = []
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: group.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 28)
                        Text(group.rawValue)
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.3))
                    }
                    .padding(14)
                    .background(isSelected ? FitCompColors.primary.opacity(0.1) : FitCompColors.textSecondary.opacity(0.05))
                    .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textPrimary)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? FitCompColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var generateButton: some View {
        Button(action: {
            generatedExercises = WorkoutGenerator.generate(for: selectedMuscles, exercisesPerGroup: 2)
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                Text("Generate Workout (\(selectedMuscles.count) groups)")
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FitCompColors.primary)
            .foregroundColor(FitCompColors.buttonTextOnPrimary)
            .cornerRadius(16)
        }
    }

    @ViewBuilder
    private var generatedPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR WORKOUT")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                Text("\(generatedExercises.count) exercises")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
            }

            ForEach(generatedExercises) { exercise in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exercise.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(FitCompColors.textPrimary)
                        Text(exercise.exercise.targetMuscles)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FitCompColors.textSecondary)
                    }
                    Spacer()
                    Text("\(exercise.sets.count) sets")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                }
                .padding(12)
                .background(FitCompColors.textSecondary.opacity(0.05))
                .cornerRadius(12)
            }

            HStack(spacing: 10) {
                Button(action: {
                    generatedExercises = WorkoutGenerator.generate(for: selectedMuscles, exercisesPerGroup: 2)
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Shuffle")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FitCompColors.textSecondary.opacity(0.08))
                    .foregroundColor(FitCompColors.textPrimary)
                    .cornerRadius(14)
                }

                Button(action: { startCustomWorkout() }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Now")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FitCompColors.primary)
                    .foregroundColor(FitCompColors.buttonTextOnPrimary)
                    .cornerRadius(14)
                }

                Button(action: { saveCustomWorkout() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FitCompColors.primary)
                    .foregroundColor(FitCompColors.buttonTextOnPrimary)
                    .cornerRadius(14)
                }
            }
        }
    }

    // MARK: - Actions

    private func openPreview(day: SplitDay) {
        previewTitle = day.name
        previewExercises = WorkoutGenerator.generate(from: day)
        showingPreview = true
    }

    private func addFullSplit(_ template: WorkoutSplitTemplate) {
        pendingSaveIsBatch = true
        pendingSaveBatchItems = template.days.map { day in
            (name: "\(template.name) - \(day.name)", exercises: WorkoutGenerator.generate(from: day))
        }
        pendingSaveName = template.name
        pendingSaveExercises = []
        showingSaveSchedule = true
    }

    private func startCustomWorkout() {
        let muscleNames = selectedMuscles.map(\.rawValue).joined(separator: " + ")
        let workout = Workout(name: muscleNames, exercises: generatedExercises, assignedDays: [])
        workoutViewModel.addWorkout(workout)
        workoutViewModel.startWorkout(workout)
        HapticManager.shared.success()
        dismiss()
    }

    private func saveCustomWorkout() {
        let muscleNames = selectedMuscles.map(\.rawValue).joined(separator: " + ")
        pendingSaveIsBatch = false
        pendingSaveBatchItems = []
        pendingSaveName = muscleNames
        pendingSaveExercises = generatedExercises
        showingSaveSchedule = true
    }
}

// MARK: - Single-Day Workout Preview Sheet

struct WorkoutPreviewSheet: View {
    let title: String
    @State var exercises: [WorkoutExercise]
    @ObservedObject var workoutViewModel: WorkoutViewModel
    var onDismissParent: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSaveSchedule = false

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(exercises) { exercise in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.exercise.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(FitCompColors.textPrimary)
                                    Text(exercise.exercise.targetMuscles)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(FitCompColors.textSecondary)
                                }
                                Spacer()
                                Text("\(exercise.sets.count) x 10")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            .padding(14)
                            .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
                            .cornerRadius(14)
                        }

                        Button(action: {
                            exercises = exercises.shuffled()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Shuffle Exercises")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(FitCompColors.textSecondary.opacity(0.08))
                            .foregroundColor(FitCompColors.textPrimary)
                            .cornerRadius(14)
                        }

                        HStack(spacing: 10) {
                            Button(action: { startWorkout() }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Now")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(FitCompColors.primary)
                                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                                .cornerRadius(16)
                            }

                            Button(action: { showingSaveSchedule = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(FitCompColors.primary)
                                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSaveSchedule) {
                SaveWorkoutScheduleSheet(
                    workoutViewModel: workoutViewModel,
                    workoutName: title,
                    exercises: exercises,
                    onComplete: {
                        dismiss()
                        onDismissParent()
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func startWorkout() {
        let workout = Workout(name: title, exercises: exercises, assignedDays: [])
        workoutViewModel.addWorkout(workout)
        workoutViewModel.startWorkout(workout)
        HapticManager.shared.success()
        dismiss()
        onDismissParent()
    }
}

// MARK: - Save Workout Schedule Sheet

struct SaveWorkoutScheduleSheet: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let workoutName: String
    let exercises: [WorkoutExercise]
    var isBatch: Bool = false
    var batchItems: [(name: String, exercises: [WorkoutExercise])] = []
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedOption: ScheduleOption?
    @State private var selectedDays: Set<DayOfWeek> = []

    private enum ScheduleOption {
        case todayOnly
        case weekly
    }

    private let weekDays: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Schedule Workout")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(FitCompColors.textPrimary)
                            Text(isBatch ? "How do you want to schedule these workouts?" : "How do you want to schedule this workout?")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                        .padding(.top, 8)

                        optionButton(
                            icon: "sun.max.fill",
                            title: "Today Only",
                            subtitle: "Add to today's workouts (\(DayOfWeek.from(date: Date()).fullName))",
                            option: .todayOnly
                        )

                        optionButton(
                            icon: "calendar",
                            title: "Weekly Schedule",
                            subtitle: "Repeat on specific days each week",
                            option: .weekly
                        )

                        if selectedOption == .weekly {
                            dayPickerSection
                        }

                        if canSave {
                            saveButton
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FitCompColors.textSecondary)
                }
            }
        }
    }

    private var canSave: Bool {
        switch selectedOption {
        case .todayOnly: return true
        case .weekly: return !selectedDays.isEmpty
        case .none: return false
        }
    }

    private func optionButton(icon: String, title: String, subtitle: String, option: ScheduleOption) -> some View {
        let isSelected = selectedOption == option
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedOption = option
                if option == .todayOnly { selectedDays = [] }
            }
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? FitCompColors.primary.opacity(0.1) : FitCompColors.textSecondary.opacity(0.06))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.3))
            }
            .padding(16)
            .background(isSelected ? FitCompColors.primary.opacity(0.05) : (colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? FitCompColors.primary.opacity(0.3) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dayPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT DAYS")
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundColor(FitCompColors.textSecondary)

            VStack(spacing: 8) {
                ForEach(weekDays) { day in
                    let isSelected = selectedDays.contains(day)
                    Button(action: {
                        if isSelected {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }) {
                        HStack {
                            Text(day.fullName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textPrimary)

                            Spacer()

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(isSelected ? FitCompColors.primary.opacity(0.08) : FitCompColors.textSecondary.opacity(0.04))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var saveButton: some View {
        Button(action: { performSave() }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Save Workout")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FitCompColors.primary)
            .foregroundColor(FitCompColors.buttonTextOnPrimary)
            .cornerRadius(16)
        }
    }

    private func performSave() {
        let assignedDays: [DayOfWeek]
        switch selectedOption {
        case .todayOnly:
            assignedDays = [DayOfWeek.from(date: Date())]
        case .weekly:
            assignedDays = weekDays.filter { selectedDays.contains($0) }
        case .none:
            return
        }

        if isBatch {
            for item in batchItems {
                let workout = Workout(name: item.name, exercises: item.exercises, assignedDays: assignedDays)
                workoutViewModel.addWorkout(workout)
            }
        } else {
            let workout = Workout(name: workoutName, exercises: exercises, assignedDays: assignedDays)
            workoutViewModel.addWorkout(workout)
        }

        HapticManager.shared.success()
        dismiss()
        onComplete()
    }
}

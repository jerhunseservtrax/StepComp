//
//  UpcomingWorkoutCard.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import SwiftUI

struct UpcomingWorkoutCard: View {
    let workout: Workout
    let date: Date
    let onTap: () -> Void
    var tabManager: TabSelectionManager?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingWorkoutDetail = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var dateText: String {
        if isToday {
            return "Today"
        }
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        Button(action: { showingWorkoutDetail = true }) {
            HStack(spacing: 16) {
                // Workout Icon
                ZStack {
                    Circle()
                        .fill(StepCompColors.primary.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(StepCompColors.primary)
                }
                
                // Workout Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Workout")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StepCompColors.textSecondary)
                    
                    Text(workout.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(dateText)
                            .font(.system(size: 12, weight: .medium))
                        Text("•")
                        Text("\(workout.exercises.count) exercises")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(StepCompColors.textSecondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(StepCompColors.textSecondary)
            }
            .padding(16)
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
            .cornerRadius(20)
            .shadow(color: StepCompColors.shadowSecondary, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWorkoutDetail) {
            WorkoutDetailView(
                workout: workout,
                selectedDate: date,
                viewModel: WorkoutViewModel.shared,
                tabManager: tabManager
            )
        }
    }
}

#Preview {
    let sampleWorkout = Workout(
        name: "Upper Body",
        exercises: [],
        assignedDays: [.monday]
    )
    return UpcomingWorkoutCard(
        workout: sampleWorkout,
        date: Date(),
        onTap: {}
    )
    .padding()
    .background(StepCompColors.background)
}

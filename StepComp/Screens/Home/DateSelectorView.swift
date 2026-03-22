//
//  DateSelectorView.swift
//  FitComp
//
//  Horizontal scrolling date selector
//

import SwiftUI

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    
    // Generate dates for the past 30 days (scrollable history)
    private var dates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (-29...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dates, id: \.self) { date in
                        let isFuture = date > calendar.startOfDay(for: Date())
                        DateButton(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isFuture: isFuture
                        ) {
                            // Only allow selection of current or past dates
                            guard !isFuture else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                                HapticManager.shared.soft()
                            }
                        }
                        .id(date)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .onAppear {
                // Scroll to selected date (today) on appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(selectedDate, anchor: .trailing)
                    }
                }
            }
        }
    }
}

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let isFuture: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let calendar = Calendar.current
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.stepLabel())
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundColor(textColor)
                
                Text(dayNumber)
                    .font(.system(size: 18, weight: isSelected ? .heavy : .bold, design: .rounded))
                    .foregroundColor(numberColor)
            }
            .frame(width: 52, height: 72)
            .background(
                Group {
                    if isSelected && !isFuture {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(FitCompColors.primaryGradient(for: colorScheme))
                            .shadow(
                                color: FitCompColors.primary.opacity(0.4),
                                radius: 12,
                                x: 0,
                                y: 4
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(FitCompColors.surface)
                            .shadow(
                                color: FitCompColors.shadowSecondary,
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    }
                }
            )
            .scaleEffect(isSelected && !isFuture ? 1.08 : 1.0)
            .opacity(isFuture ? 0.4 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFuture)
    }
    
    private var textColor: Color {
        if isFuture {
            return FitCompColors.textTertiary
        } else if isSelected {
            return .white
        } else {
            return FitCompColors.textSecondary
        }
    }
    
    private var numberColor: Color {
        if isFuture {
            return FitCompColors.textTertiary
        } else if isSelected {
            return .white
        } else {
            return FitCompColors.textPrimary
        }
    }
}

#Preview {
    DateSelectorView(selectedDate: .constant(Date()))
        .background(Color(.systemGray6))
}


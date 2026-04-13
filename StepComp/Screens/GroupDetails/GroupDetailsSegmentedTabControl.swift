//
//  GroupDetailsSegmentedTabControl.swift
//  FitComp
//

import SwiftUI

struct SegmentedTabControl: View {
    @Binding var selectedTab: GroupDetailTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(GroupDetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.displayName)
                        .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                        .foregroundColor(selectedTab == tab ? .black : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? FitCompColors.primary : Color.clear)
                        .cornerRadius(999)
                }
            }
        }
        .padding(6)
        .background(Color(.systemBackground))
        .cornerRadius(999)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

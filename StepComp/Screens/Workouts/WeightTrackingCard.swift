//
//  WeightTrackingCard.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import SwiftUI

struct WeightTrackingCard: View {
    @ObservedObject var viewModel: WeightViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @Binding var showingWeightEntry: Bool
    
    var body: some View {
        Button(action: { showingWeightEntry = true }) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon at top
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                
                Spacer()
                
                // Value and label at bottom
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEIGHT")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Color.black.opacity(0.4))
                        .tracking(0.5)
                    
                    if let weight = viewModel.latestWeight {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(unitManager.formatWeight(weight, decimals: 0))
                                .font(.system(size: 32, weight: .black))
                                .italic()
                                .foregroundColor(.black)
                            Text(unitManager.weightUnit.lowercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                    } else {
                        Text("Add Weight")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(StepCompColors.primary)
            .cornerRadius(24)
            .shadow(color: StepCompColors.primary.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

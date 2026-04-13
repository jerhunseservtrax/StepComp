//
//  GroupDetailsHeaderView.swift
//  FitComp
//

import SwiftUI

struct GroupDetailsHeader: View {
    let challengeName: String
    let onBack: () -> Void
    let onInvite: () -> Void
    let onChat: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18))
                    .foregroundColor(FitCompColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(FitCompColors.surface)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }

            Spacer()

            Text(challengeName)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            Spacer()

            HStack(spacing: 8) {
                Button(action: onChat) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(999)
                        .shadow(color: Color.white.opacity(0.5), radius: 8, x: 0, y: 2)
                }

                Button(action: onInvite) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16))
                        Text("Invite")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(FitCompColors.buttonTextOnPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(FitCompColors.primary)
                    .cornerRadius(999)
                    .shadow(color: FitCompColors.primary.opacity(0.4), radius: 8, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(
            FitCompColors.surface
                .opacity(0.9)
                .background(.ultraThinMaterial)
        )
    }
}

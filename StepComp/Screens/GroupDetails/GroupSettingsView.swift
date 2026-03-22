//
//  GroupSettingsView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct GroupSettingsView: View {
    @ObservedObject var viewModel: GroupViewModel
    @Binding var showingSettings: Bool
    
    @State private var showingLeaveAlert = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                if viewModel.canDelete {
                    Section {
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Text("Delete Challenge")
                        }
                    }
                } else {
                    Section {
                        Button(role: .destructive, action: {
                            showingLeaveAlert = true
                        }) {
                            Text("Leave Challenge")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
            .alert("Leave Challenge", isPresented: $showingLeaveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    Task {
                        await viewModel.leaveChallenge()
                        showingSettings = false
                    }
                }
            } message: {
                Text("Are you sure you want to leave this challenge?")
            }
            .alert("Delete Challenge", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteChallenge()
                        showingSettings = false
                    }
                }
            } message: {
                Text("Are you sure you want to delete this challenge? This action cannot be undone.")
            }
        }
    }
}


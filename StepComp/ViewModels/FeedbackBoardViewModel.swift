//
//  FeedbackBoardViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse

import Foundation
import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class FeedbackBoardViewModel: ObservableObject {
    @Published var feedbackPosts: [FeedbackPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: FeedbackCategory?
    @Published var selectedSort: FeedbackSortOption = .recent
    
    private let limit = 50
    private var offset = 0
    
    func loadFeedback() async {
        isLoading = true
        errorMessage = nil
        
        do {
            #if canImport(Supabase)
            let search = searchText.isEmpty ? nil : searchText
            let category = selectedCategory?.rawValue
            
            let response = try await supabase
                .rpc("get_feedback_posts", params: [
                    "p_search": search as Any,
                    "p_category": category as Any,
                    "p_status": nil as Any,
                    "p_sort_by": selectedSort.rawValue,
                    "p_limit": limit,
                    "p_offset": offset
                ])
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            feedbackPosts = try decoder.decode([FeedbackPost].self, from: response.data)
            print("✅ Loaded \(feedbackPosts.count) feedback posts")
            #endif
        } catch {
            print("❌ Error loading feedback: \(error)")
            errorMessage = "Failed to load feedback: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createFeedback(title: String, description: String, category: FeedbackCategory) async -> Bool {
        guard !title.isEmpty, !description.isEmpty else {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        guard title.count >= 3, title.count <= 200 else {
            errorMessage = "Title must be between 3 and 200 characters"
            return false
        }
        
        guard description.count >= 10, description.count <= 2000 else {
            errorMessage = "Description must be between 10 and 2000 characters"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            #if canImport(Supabase)
            let userId = try await supabase.auth.session.user.id.uuidString
            
            let newPost: [String: Any] = [
                "user_id": userId,
                "title": title,
                "description": description,
                "category": category.rawValue
            ]
            
            try await supabase
                .from("feedback_posts")
                .insert(newPost)
                .execute()
            
            print("✅ Feedback post created successfully")
            
            // Reload feedback
            await loadFeedback()
            #endif
            
            isLoading = false
            return true
        } catch {
            print("❌ Error creating feedback: \(error)")
            errorMessage = "Failed to create feedback: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func updateFeedback(postId: String, title: String, description: String, category: FeedbackCategory) async -> Bool {
        guard !title.isEmpty, !description.isEmpty else {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            #if canImport(Supabase)
            let updates: [String: Any] = [
                "title": title,
                "description": description,
                "category": category.rawValue,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabase
                .from("feedback_posts")
                .update(updates)
                .eq("id", value: postId)
                .execute()
            
            print("✅ Feedback post updated successfully")
            
            // Reload feedback
            await loadFeedback()
            #endif
            
            isLoading = false
            return true
        } catch {
            print("❌ Error updating feedback: \(error)")
            errorMessage = "Failed to update feedback: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func deleteFeedback(postId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            #if canImport(Supabase)
            let response = try await supabase
                .rpc("delete_feedback_post", params: ["p_post_id": postId])
                .execute()
            
            print("✅ Feedback post deleted successfully")
            
            // Remove from local array
            feedbackPosts.removeAll { $0.id == postId }
            #endif
            
            isLoading = false
            return true
        } catch {
            print("❌ Error deleting feedback: \(error)")
            errorMessage = "Failed to delete feedback: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func vote(on postId: String, voteType: VoteType?) async {
        do {
            #if canImport(Supabase)
            let voteTypeStr = voteType == nil ? "remove" : voteType!.rawValue
            
            let response = try await supabase
                .rpc("vote_on_feedback", params: [
                    "p_post_id": postId,
                    "p_vote_type": voteTypeStr
                ])
                .execute()
            
            print("✅ Vote recorded successfully")
            
            // Update local post
            if let index = feedbackPosts.firstIndex(where: { $0.id == postId }) {
                var updatedPost = feedbackPosts[index]
                
                // Update vote counts based on previous and new vote
                let previousVote = updatedPost.userVote
                
                // Remove previous vote counts
                if previousVote == .up {
                    updatedPost.upvotes -= 1
                } else if previousVote == .down {
                    updatedPost.downvotes -= 1
                }
                
                // Add new vote counts
                if voteType == .up {
                    updatedPost.upvotes += 1
                } else if voteType == .down {
                    updatedPost.downvotes += 1
                }
                
                updatedPost.userVote = voteType
                feedbackPosts[index] = updatedPost
            }
            #endif
        } catch {
            print("❌ Error voting: \(error)")
            errorMessage = "Failed to vote: \(error.localizedDescription)"
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedSort = .recent
    }
}


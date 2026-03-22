//
//  FeedbackBoardViewModel.swift
//  FitComp
//
//  Created by Jeffery Erhunse

import Foundation
import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

// MARK: - Feedback Parameter Structs

nonisolated struct FeedbackParams: Encodable, Sendable {
    let p_sort_by: String
    let p_limit: Int
    let p_offset: Int
    let p_search: String?
    let p_category: String?
    let p_status: String?
}

nonisolated struct NewFeedbackPost: Encodable, Sendable {
    let user_id: String
    let title: String
    let description: String
    let category: String
}

nonisolated struct UpdateFeedbackPost: Encodable, Sendable {
    let title: String
    let description: String
    let category: String
    let updated_at: String
}

// MARK: - View Model

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
            let logData1 = "{\"location\":\"FeedbackBoardViewModel.swift:53\",\"message\":\"loadFeedback called\",\"data\":{\"searchText\":\"\(searchText)\",\"category\":\"\(selectedCategory?.rawValue ?? "nil")\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"initial\",\"hypothesisId\":\"A,B,C\"}\n"
            try? logData1.write(toFile: "/Users/jefferyerhunse/GitRepos/FitComp/.cursor/debug.log", atomically: false, encoding: .utf8)
            
            let search = searchText.isEmpty ? nil : searchText
            let category = selectedCategory?.rawValue
            
            let params = FeedbackParams(
                p_sort_by: selectedSort.rawValue,
                p_limit: limit,
                p_offset: offset,
                p_search: search,
                p_category: category,
                p_status: nil // Don't filter by status by default
            )
            
            let logData2 = "{\"location\":\"FeedbackBoardViewModel.swift:71\",\"message\":\"Calling RPC get_feedback_posts\",\"data\":{\"sort\":\"\(selectedSort.rawValue)\",\"limit\":\(limit)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"initial\",\"hypothesisId\":\"A\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/FitComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData2.data(using: .utf8)!); fileHandle.closeFile() }
            
            let response = try await supabase
                .rpc("get_feedback_posts", params: params)
                .execute()
            
            if let rawJSON = String(data: response.data, encoding: .utf8) {
                let truncated = String(rawJSON.prefix(1000)).replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
                let logData3 = "{\"location\":\"FeedbackBoardViewModel.swift:83\",\"message\":\"Raw response from Supabase\",\"data\":{\"rawJSON\":\"\(truncated)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"initial\",\"hypothesisId\":\"A,B,C,D,E\"}\n"
                if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/FitComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData3.data(using: .utf8)!); fileHandle.closeFile() }
            }
            
            let decoder = JSONDecoder()
            // Use custom date decoding to handle various formats from PostgreSQL
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try ISO8601 with fractional seconds first (PostgreSQL default)
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Try standard ISO8601
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Try PostgreSQL timestamp format with timezone
                let postgresFormatter = DateFormatter()
                postgresFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                postgresFormatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = postgresFormatter.date(from: dateString) {
                    return date
                }
                
                // Try without fractional seconds
                postgresFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = postgresFormatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            }
            // Don't use convertFromSnakeCase - we have explicit CodingKeys in FeedbackPost
            
            let logData4 = "{\"location\":\"FeedbackBoardViewModel.swift:93\",\"message\":\"About to decode with flexible date strategy\",\"data\":{},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"initial\",\"hypothesisId\":\"B,C\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/FitComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData4.data(using: .utf8)!); fileHandle.closeFile() }
            
            feedbackPosts = try decoder.decode([FeedbackPost].self, from: response.data)
            
            let logData5 = "{\"location\":\"FeedbackBoardViewModel.swift:100\",\"message\":\"Successfully decoded feedback posts\",\"data\":{\"count\":\(feedbackPosts.count)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"initial\",\"hypothesisId\":\"SUCCESS\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/FitComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData5.data(using: .utf8)!); fileHandle.closeFile() }
            
            print("✅ Loaded \(feedbackPosts.count) feedback posts")
            #endif
        } catch {
            let errorDesc = String(describing: error).replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
            let logData6 = "{\"location\":\"FeedbackBoardViewModel.swift:109\",\"message\":\"Error caught during loadFeedback\",\"data\":{\"error\":\"\(errorDesc)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"initial\",\"hypothesisId\":\"A,B,C,D,E\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/FitComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData6.data(using: .utf8)!); fileHandle.closeFile() }
            
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
            
            let newPost = NewFeedbackPost(
                user_id: userId,
                title: title,
                description: description,
                category: category.rawValue
            )
            
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
            let updates = UpdateFeedbackPost(
                title: title,
                description: description,
                category: category.rawValue,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
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
            _ = try await supabase
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
            
            _ = try await supabase
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


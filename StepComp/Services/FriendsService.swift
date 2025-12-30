//
//  FriendsService.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine // Required for @Published and ObservableObject

@MainActor
final class FriendsService: ObservableObject {
    @Published var friends: [User] = []
    
    private let friendsKey = "friends"
    
    init() {
        loadFriends()
    }
    
    func addFriend(_ user: User) {
        guard !friends.contains(where: { $0.id == user.id }) else { return }
        friends.append(user)
        saveFriends()
    }
    
    func removeFriend(_ userId: String) {
        friends.removeAll { $0.id == userId }
        saveFriends()
    }
    
    func getFriend(_ userId: String) -> User? {
        friends.first { $0.id == userId }
    }
    
    func updateFriendSteps(_ userId: String, todaySteps: Int) {
        guard let index = friends.firstIndex(where: { $0.id == userId }) else { return }
        friends[index].totalSteps = todaySteps
        saveFriends()
    }
    
    private func saveFriends() {
        if let encoded = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(encoded, forKey: friendsKey)
        }
    }
    
    private func loadFriends() {
        guard let data = UserDefaults.standard.data(forKey: friendsKey),
              let decoded = try? JSONDecoder().decode([User].self, from: data) else {
            // Load mock friends for testing
            loadMockFriends()
            return
        }
        friends = decoded
    }
    
    private func loadMockFriends() {
        // Create some mock friends for testing
        friends = [
            User(
                id: "friend1",
                displayName: "Sarah Chen",
                avatarURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDayMlHVGCDatlPdfkSR0CEK1YxUpeDb0Dj77cCeHyJHAABvJu643G6DqrAvSIlUexSsy-wdTyKU1GSzygltZ3flIBTIfRqKnGwbKLFlXnm-nYZ1jbFQWd2C8vk8Ux5wbSgXAs7tNxUeIoxIEBeEB7ILvYDPdb49fLSypwfufX2Ibvfe4_LCW1AMGbgsHIEyxu8aOVrnKIaTEmeTY6EtOgCOxvNiJfD7jAJUn0UcQR7AyntYLrS4mwEXYVn-2W2w2bwkBodHnbvsg",
                email: "sarah@example.com",
                totalSteps: 8500,
                totalChallenges: 2
            ),
            User(
                id: "friend2",
                displayName: "Mike Johnson",
                avatarURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuB8J9muV284_SRN4ApSLk0ad2alWfqqo90ea-kS77VWBVfF31PUvJ-Vprk56jcDGdPSt-GMdd2ilByLOlxXBqSTew40su0qiyA83EWlFmvGXg6kNrhra1poVt0Vyzz578KLFjCNlLTgRA3VfjroxoI3VkNO4JwNUczZICmnp2yVRcJDDDNBWqbrvTvAlCaiv0L0M9slJNsNtCqZEuHCtcN746ISQtC7-sVFv-leetp2ifbgSxZXebU6Ehu5dTnHUgnjBvFWMKE2Fw",
                email: "mike@example.com",
                totalSteps: 12000,
                totalChallenges: 4
            ),
            User(
                id: "friend3",
                displayName: "Emma Wilson",
                avatarURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuCJxcKsJM2uoALenKraNCISl_43-_oSCKZjQsvL-TqxegKPjsHc3DJquQ7ixW1ppYe4cLCHGPgvlLM3w_ISyQ64qSNZDMj8WGrC3-GX5_AqiBoYSZwGDNbxeOcTaDmbtmpTpuywMh6Vt3ZMT7-MADlxiuCc2hslDzKWeOvUca-zLnTqjKw92hiaVaJ0_c9OEBQeGjbYjfBc-fXL7vmAeIw9Z0XT9MNfBqnabdOrGyPQdLPboZg64KUwPCuKuwGjy_41nnH6BqagjQ",
                email: "emma@example.com",
                totalSteps: 6500,
                totalChallenges: 1
            ),
            User(
                id: "friend4",
                displayName: "Alex Rivera",
                avatarURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuBvpb55uwN9_R3-EL_WZXz5p4w8UzFsg44Wfh0oMycbWoCxOH_LWfqakpkhzRQQEIm0dOl31J0lDSQGz-zJuuTYfwo8LplNAORCzzvz9eEN6jtc4-watgozKespc9dsUxP6n2mwasWRfocwkYO7XLbY0-6F8GfFZWNI70z0JwIAvIXqgSqwLA3ukWctPCgTLaowV4cnps9_uMuoxsUN95I-1AcptbbnrIa2Ow7eZyf8Lwy4IYLmTC895K9ZY_4l8MnooHE8-KFjDQ",
                email: "alex@example.com",
                totalSteps: 15000,
                totalChallenges: 5
            )
        ]
        saveFriends()
    }
}


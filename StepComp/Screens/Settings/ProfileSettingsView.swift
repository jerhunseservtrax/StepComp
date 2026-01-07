//
//  ProfileSettingsView.swift
//  StepComp
//
//  Edit profile information (name, username, avatar, photo, height/weight)
//

import SwiftUI
import PhotosUI
#if canImport(Supabase)
import Supabase
#endif

struct ProfileSettingsView: View {
    let user: User
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var username: String
    @State private var email: String
    @State private var selectedAvatar: String
    @State private var isSaving = false
    @State private var isSyncingHealth = false
    @State private var errorMessage: String?
    @State private var usernameError: String?
    @State private var isCheckingUsername = false
    @State private var selectedTab: ProfileTab = .personal
    
    // Photo picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var profileImageURL: String?
    
    // Height & Weight - Editable inputs
    @State private var heightFeetText: String = "5"
    @State private var heightInchesText: String = "9"
    @State private var weightText: String = "150"
    
    // Password
    @State private var showingChangePassword = false
    @State private var isPasswordVisible = false
    @Environment(\.colorScheme) private var colorScheme
    
    enum ProfileTab: String, CaseIterable {
        case personal = "Personal"
        case measurements = "Body"
        case security = "Security"
    }
    
    init(user: User) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _username = State(initialValue: user.username)
        _email = State(initialValue: user.email ?? "")
        _selectedAvatar = State(initialValue: user.avatarURL ?? "👽")
        _profileImageURL = State(initialValue: user.avatarURL)
        
        // Load height/weight from UserDefaults
        let height = UserDefaults.standard.integer(forKey: "userHeight")
        let weight = UserDefaults.standard.integer(forKey: "userWeight")
        
        if height > 0 {
            let imperial = Self.cmToImperial(height)
            _heightFeetText = State(initialValue: "\(imperial.feet)")
            _heightInchesText = State(initialValue: "\(imperial.inches)")
        }
        
        if weight > 0 {
            _weightText = State(initialValue: "\(Self.kgToLbs(weight))")
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Photo Header
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            // Avatar with dashed border
                            ZStack {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    .foregroundColor(.gray.opacity(0.3))
                                    .frame(width: 144, height: 144)
                                
                                Group {
                                    if let photoData = selectedPhotoData,
                                       let uiImage = UIImage(data: photoData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 136, height: 136)
                                            .clipShape(Circle())
                                    } else {
                                        AvatarView(
                                            displayName: "\(firstName) \(lastName)",
                                            avatarURL: profileImageURL,
                                            size: 136
                                        )
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                            }
                            
                            // Camera Button
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(StepCompColors.primary)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(StepCompColors.buttonTextOnPrimary)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(StepCompColors.background, lineWidth: 4)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                            }
                            .offset(x: -4, y: -4)
                        }
                        
                        Text("\(firstName) \(lastName)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(StepCompColors.textPrimary)
                        
                        Text("@\(username)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(StepCompColors.textSecondary)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                    
                    // Tab Selector
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(ProfileTab.allCases, id: \.self) { tab in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedTab = tab
                                    }
                                } label: {
                                    Text(tab.rawValue)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(selectedTab == tab ? StepCompColors.buttonTextOnPrimary : StepCompColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedTab == tab ? StepCompColors.primary : Color.clear
                                        )
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(6)
                        .background(StepCompColors.surface)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(StepCompColors.cardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .background(StepCompColors.background)
                    
                    // Content
                    VStack(spacing: 24) {
                        switch selectedTab {
                        case .personal:
                            personalSection
                        case .measurements:
                            measurementsSection
                        case .security:
                            securitySection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .background(StepCompColors.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await saveProfile()
                        }
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(StepCompColors.buttonTextOnPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(StepCompColors.primary)
                            .cornerRadius(20)
                    }
                    .disabled(isSaving || firstName.isEmpty || username.isEmpty || usernameError != nil)
                    .opacity(isSaving || firstName.isEmpty || username.isEmpty || usernameError != nil ? 0.5 : 1)
                }
            }
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: StepCompColors.primary))
                                .scaleEffect(1.5)
                            
                            Text("Saving...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(StepCompColors.textPrimary)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(StepCompColors.surface)
                        )
                    }
                }
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
            }
        }
    }
    
    // MARK: - Personal Section
    
    var personalSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 0) {
                // Section Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(StepCompColors.primary.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(StepCompColors.primary)
                    }
                    
                    Text("Personal Info")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                    
                    Spacer()
                }
                .padding()
                .background(StepCompColors.surface)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                
                // Fields
                VStack(spacing: 20) {
                    // Name Row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FIRST NAME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(StepCompColors.textSecondary)
                                .tracking(0.5)
                            
                            TextField("First", text: $firstName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(StepCompColors.textPrimary)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(StepCompColors.surfaceElevated)
                                .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LAST NAME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(StepCompColors.textSecondary)
                                .tracking(0.5)
                            
                            TextField("Last", text: $lastName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(StepCompColors.textPrimary)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(StepCompColors.surfaceElevated)
                                .cornerRadius(16)
                        }
                    }
                    
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USERNAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                            .tracking(0.5)
                        
                        HStack {
                            Text("@")
                                .foregroundColor(StepCompColors.textSecondary)
                                .font(.system(size: 16, weight: .bold))
                            TextField("username", text: $username)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(StepCompColors.textPrimary)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: username) { oldValue, newValue in
                                    username = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                    
                                    if newValue != user.username && !newValue.isEmpty {
                                        Task {
                                            await checkUsernameAvailability(newValue)
                                        }
                                    } else {
                                        usernameError = nil
                                    }
                                }
                            
                            if isCheckingUsername {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if usernameError != nil {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            } else if username != user.username && !username.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(StepCompColors.surfaceElevated)
                        .cornerRadius(16)
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL ADDRESS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                            .tracking(0.5)
                        
                        Text(email.isEmpty ? "No email set" : email)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(email.isEmpty ? StepCompColors.textSecondary : StepCompColors.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(StepCompColors.surfaceElevated)
                            .cornerRadius(16)
                        
                        Text("Used for notifications and login.")
                            .font(.system(size: 10))
                            .foregroundColor(StepCompColors.textSecondary.opacity(0.8))
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(StepCompColors.surface)
                .cornerRadius(24, corners: [.bottomLeft, .bottomRight])
            }
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(StepCompColors.cardBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Measurements Section
    
    var measurementsSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 0) {
                // Section Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Measurements")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                    
                    Spacer()
                }
                .padding()
                .background(StepCompColors.surface)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                
                // Fields
                VStack(spacing: 20) {
                    // Height
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HEIGHT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                            .tracking(0.5)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                TextField("0", text: $heightFeetText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(StepCompColors.textPrimary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity)
                                
                                Text("FT")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(StepCompColors.textSecondary)
                            }
                            .padding()
                            .background(StepCompColors.surfaceElevated)
                            .cornerRadius(16)
                            
                            HStack(spacing: 4) {
                                TextField("0", text: $heightInchesText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(StepCompColors.textPrimary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity)
                                
                                Text("IN")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(StepCompColors.textSecondary)
                            }
                            .padding()
                            .background(StepCompColors.surfaceElevated)
                            .cornerRadius(16)
                        }
                    }
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WEIGHT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                            .tracking(0.5)
                        
                        HStack(spacing: 4) {
                            TextField("0", text: $weightText)
                                .keyboardType(.numberPad)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(StepCompColors.textPrimary)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity)
                            
                            Text("LBS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(StepCompColors.textSecondary)
                                .padding(.trailing, 4)
                        }
                        .padding()
                        .background(StepCompColors.surfaceElevated)
                        .cornerRadius(16)
                    }
                    
                    // Sync from Apple Health Button
                    Button {
                        Task {
                            await syncFromAppleHealth()
                        }
                    } label: {
                        HStack {
                            if isSyncingHealth {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 16))
                                Text("Sync from Apple Health")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(16)
                    }
                    .disabled(isSyncingHealth)
                }
                .padding()
                .background(StepCompColors.surface)
                .cornerRadius(24, corners: [.bottomLeft, .bottomRight])
            }
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(StepCompColors.cardBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Security Section
    
    var securitySection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 0) {
                // Section Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    
                    Text("Account Security")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                    
                    Spacer()
                }
                .padding()
                .background(StepCompColors.surface)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                
                // Fields
                VStack(spacing: 20) {
                    // Password Display
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CURRENT PASSWORD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                            .tracking(0.5)
                        
                        HStack {
                            HStack(spacing: 4) {
                                ForEach(0..<8, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.gray.opacity(0.6))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            Spacer()
                            
                            Text("Updated 3mo ago")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StepCompColors.textSecondary.opacity(0.7))
                        }
                        .padding()
                        .background(StepCompColors.surfaceElevated)
                        .cornerRadius(16)
                    }
                    
                    // Change Password Button
                    Button {
                        showingChangePassword = true
                    } label: {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 16))
                            Text("Change Password")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(StepCompColors.textPrimary.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(StepCompColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(StepCompColors.cardBorder.opacity(0.4), lineWidth: 2)
                        )
                        .cornerRadius(16)
                    }
                }
                .padding()
                .background(StepCompColors.surface)
                .cornerRadius(24, corners: [.bottomLeft, .bottomRight])
            }
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(StepCompColors.cardBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private static func cmToImperial(_ cm: Int) -> (feet: Int, inches: Int) {
        let totalInches = Double(cm) / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
    
    private static func imperialToCm(feet: Int, inches: Int) -> Int {
        let totalInches = Double(feet * 12 + inches)
        return Int(totalInches * 2.54)
    }
    
    private static func kgToLbs(_ kg: Int) -> Int {
        return Int(Double(kg) * 2.20462)
    }
    
    private static func lbsToKg(_ lbs: Int) -> Int {
        return Int(Double(lbs) / 2.20462)
    }
    
    private func syncFromAppleHealth() async {
        isSyncingHealth = true
        
        do {
            // Get height from HealthKit
            if let heightCm = try await healthKitService.getHeight() {
                let imperial = Self.cmToImperial(Int(heightCm))
                heightFeetText = "\(imperial.feet)"
                heightInchesText = "\(imperial.inches)"
            }
            
            // Get weight from HealthKit
            if let weightKg = try await healthKitService.getWeight() {
                weightText = "\(Self.kgToLbs(Int(weightKg)))"
            }
        } catch {
            errorMessage = "Failed to sync from Apple Health: \(error.localizedDescription)"
        }
        
        isSyncingHealth = false
    }
    
    private func checkUsernameAvailability(_ username: String) async {
        isCheckingUsername = true
        usernameError = nil
        
        #if canImport(Supabase)
        do {
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("username", value: username)
                .execute()
                .value
            
            if !profiles.isEmpty {
                usernameError = "Username is already taken"
            }
        } catch {
            print("⚠️ Error checking username: \(error.localizedDescription)")
        }
        #endif
        
        isCheckingUsername = false
    }
    
    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        
        // Parse height and weight from text fields
        let feet = Int(heightFeetText) ?? 5
        let inches = Int(heightInchesText) ?? 9
        let weight = Int(weightText) ?? 150
        
        do {
            // Convert height and weight to metric
            let heightCm = Self.imperialToCm(feet: feet, inches: inches)
            let weightKg = Self.lbsToKg(weight)
            
            // Save to UserDefaults
            UserDefaults.standard.set(heightCm, forKey: "userHeight")
            UserDefaults.standard.set(weightKg, forKey: "userWeight")
            
            #if canImport(Supabase)
            var avatarUrl: String? = profileImageURL
            
            // Upload photo to Supabase Storage if new photo selected
            if let photoData = selectedPhotoData {
                do {
                    // Delete all old avatars for this user (keep only one)
                    do {
                        let existingFiles = try await supabase.storage
                            .from("avatars")
                            .list(path: user.id)
                        
                        if !existingFiles.isEmpty {
                            for file in existingFiles {
                                let filePath = "\(user.id)/\(file.name)"
                                try await supabase.storage
                                    .from("avatars")
                                    .remove(paths: [filePath])
                            }
                        }
                    } catch {
                        // Continue with upload even if delete fails
                    }
                    
                    // Upload new avatar (single file per user)
                    let fileName = "\(user.id)/avatar.jpg"
                    
                    try await supabase.storage
                        .from("avatars")
                        .upload(
                            fileName,
                            data: photoData,
                            options: FileOptions(contentType: "image/jpeg", upsert: true)
                        )
                    
                    // Get authenticated URL (for private bucket)
                    let signedURL = try await supabase.storage
                        .from("avatars")
                        .createSignedURL(path: fileName, expiresIn: 31536000) // 1 year expiry
                    
                    avatarUrl = signedURL.absoluteString
                } catch {
                    // Provide helpful error messages based on common issues
                    if error.localizedDescription.contains("not found") {
                        errorMessage = "Storage bucket 'avatars' not found. Please ensure it exists in your Supabase Storage dashboard."
                    } else if error.localizedDescription.contains("permission") || error.localizedDescription.contains("policy") {
                        errorMessage = "Permission denied. Please check your storage bucket policies allow authenticated users to upload to their own folder."
                    } else {
                        errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
                    }
                    
                    isSaving = false
                    return
                }
            }
            
            // Update profile in database
            struct ProfileUpdate: Encodable {
                let first_name: String
                let last_name: String
                let display_name: String // ✅ NEW: Update display name
                let username: String
                let height: Int
                let weight: Int
                let avatar_url: String?
            }
            
            let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            
            // #region agent log
            let logUpdate = "{\"location\":\"ProfileSettingsView.swift:775\",\"message\":\"Updating profile with display_name\",\"data\":{\"firstName\":\"\(firstName)\",\"lastName\":\"\(lastName)\",\"displayName\":\"\(displayName)\",\"username\":\"\(username)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"profile-update\",\"hypothesisId\":\"H1,H2\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                fileHandle.seekToEndOfFile()
                if let data = logUpdate.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            // #endregion
            
            let profileUpdate = ProfileUpdate(
                first_name: firstName,
                last_name: lastName,
                display_name: displayName,
                username: username,
                height: heightCm,
                weight: weightKg,
                avatar_url: avatarUrl
            )
            
            try await supabase
                .from("profiles")
                .update(profileUpdate)
                .eq("id", value: user.id)
                .execute()
            
            // Reload the user's session to get updated profile
            authService.checkSupabaseSession()
            
            // Wait a bit for the session to reload
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            #endif
            
            isSaving = false
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

// Note: RoundedCorner extension is defined in JoinChallengeView.swift

// MARK: - Change Password View

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var isCurrentPasswordVisible = false
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(StepCompColors.primary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 36))
                            .foregroundColor(StepCompColors.primary)
                    }
                    .padding(.top, 20)
                    
                    Text("Create a strong password with at least 8 characters")
                        .font(.system(size: 14))
                        .foregroundColor(StepCompColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        // Current Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(StepCompColors.textSecondary)
                            
                            HStack {
                                if isCurrentPasswordVisible {
                                    TextField("Enter current password", text: $currentPassword)
                                        .foregroundColor(StepCompColors.textPrimary)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Enter current password", text: $currentPassword)
                                        .textInputAutocapitalization(.never)
                                }
                                
                                Button {
                                    isCurrentPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isCurrentPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                        .foregroundColor(StepCompColors.textSecondary)
                                }
                            }
                            .padding()
                            .background(StepCompColors.surfaceElevated)
                            .cornerRadius(16)
                        }
                        
                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(StepCompColors.textSecondary)
                            
                            HStack {
                                if isNewPasswordVisible {
                                    TextField("Enter new password", text: $newPassword)
                                        .foregroundColor(StepCompColors.textPrimary)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textInputAutocapitalization(.never)
                                }
                                
                                Button {
                                    isNewPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isNewPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                        .foregroundColor(StepCompColors.textSecondary)
                                }
                            }
                            .padding()
                            .background(StepCompColors.surfaceElevated)
                            .cornerRadius(16)
                            
                            if !newPassword.isEmpty && newPassword.count < 8 {
                                Text("Password must be at least 8 characters")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(StepCompColors.textSecondary)
                            
                            HStack {
                                if isConfirmPasswordVisible {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .foregroundColor(StepCompColors.textPrimary)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textInputAutocapitalization(.never)
                                }
                                
                                Button {
                                    isConfirmPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                        .foregroundColor(StepCompColors.textSecondary)
                                }
                            }
                            .padding()
                            .background(StepCompColors.surfaceElevated)
                            .cornerRadius(16)
                            
                            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Update Button
                    Button {
                        Task {
                            await changePassword()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: StepCompColors.buttonTextOnPrimary))
                            } else {
                                Text("Update Password")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(StepCompColors.buttonTextOnPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? StepCompColors.primary : StepCompColors.primary.opacity(0.4))
                        .cornerRadius(16)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(StepCompColors.textSecondary)
                }
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been successfully updated.")
            }
        }
    }
    
    private func changePassword() async {
        isLoading = true
        errorMessage = nil
        
        #if canImport(Supabase)
        do {
            try await supabase.auth.update(user: .init(password: newPassword))
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        #endif
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    ProfileSettingsView(
        user: User(
            id: "123",
            username: "johndoe",
            firstName: "John",
            lastName: "Doe",
            avatarURL: "👽",
            email: "user@example.com",
            publicProfile: true
        )
    )
    .environmentObject(AuthService.shared)
    .environmentObject(HealthKitService())
}

#Preview("Change Password") {
    ChangePasswordView()
}

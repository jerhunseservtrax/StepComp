# 🎨 Custom Challenge Images Feature

## 📸 Feature Added

Challenge creators can now upload custom images that display as beautiful gradient backgrounds on discover challenge cards!

---

## ✨ What It Does

When creating a challenge:
1. **User uploads an image** via the photo picker
2. **Image is uploaded to Supabase Storage** (`challenges` bucket)
3. **Public URL is saved** to the `challenges.image_url` column
4. **Discover cards display the image** with:
   - Gradient overlay at 50% opacity (for readability)
   - Blurred edges that fade into the background
   - Seamless blending with the rest of the UI

---

## 🎯 Visual Design

### **Before (Default):**
```
┌──────────────────────────────┐
│   Category gradient          │
│   + blur circles             │
│   + icon watermark           │
│                              │
│   Challenge Name             │
│   Category • Participants    │
│                              │
│   👤👤👤  |  7d left        │
└──────────────────────────────┘
```

### **After (With Custom Image):**
```
┌──────────────────────────────┐
│  📸 User's uploaded image    │
│  + Gradient overlay (50%)    │
│  + Blurred edges (gradient)  │
│                              │
│   Challenge Name             │
│   Category • Participants    │
│                              │
│   👤👤👤  |  7d left        │
└──────────────────────────────┘
```

---

## 🔧 Technical Implementation

### **1. Database Schema (`image_url` column)**

**Added to `challenges` table:**
```sql
ALTER TABLE public.challenges
ADD COLUMN IF NOT EXISTS image_url TEXT;
```

**Models Updated:**
- `Challenge.swift`: Added `imageUrl: String?`
- `SupabaseChallenge.swift`: Added `imageUrl: String?` with `image_url` CodingKey
- `ChallengeService.swift`: Maps `imageUrl` when converting between models

---

### **2. Image Upload (Create Challenge Flow)**

**CreateChallengeViewModel.swift:**
```swift
private func uploadChallengeImage(imageData: Data) async throws -> String? {
    let filePath = "challenge-images/\(UUID().uuidString).jpg"
    
    // Upload to Supabase Storage
    try await supabase
        .storage
        .from("challenges")
        .upload(filePath, data: imageData, options: FileOptions(...))
    
    // Get public URL
    let publicURL = try supabase
        .storage
        .from("challenges")
        .getPublicURL(path: filePath)
    
    return publicURL.absoluteString
}
```

**Storage bucket:** `challenges/challenge-images/`
**File format:** JPEG (compressed to ~1MB max)
**Access:** Public read, authenticated write

---

### **3. Display (Discover Challenge Cards)**

**DiscoverChallengesTab.swift:**
```swift
if let imageUrl = challenge.imageUrl, !imageUrl.isEmpty {
    ZStack {
        // User uploaded image
        AsyncImage(url: URL(string: imageUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure, .empty, @unknown default:
                // Fallback gradient
                LinearGradient(colors: gradientColors, ...)
            }
        }
        
        // Gradient overlay (50% opacity)
        LinearGradient(
            colors: [
                gradientColors[0].opacity(0.5),
                gradientColors[1].opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.multiply)
        
        // Edge gradient blur
        LinearGradient(
            colors: [
                StepCompColors.background.opacity(0),
                StepCompColors.background.opacity(0),
                StepCompColors.background.opacity(0.1),
                StepCompColors.background.opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
} else {
    // Default gradient (no custom image)
    LinearGradient(colors: gradientColors, ...)
}
```

---

## 📊 Design Decisions

### **Why 50% opacity gradient overlay?**
- **Text readability**: Ensures challenge name/details are always readable
- **Consistent branding**: Category colors still influence the look
- **Balanced aesthetics**: Not too washed out, not too overpowering

### **Why blurred edges?**
- **Seamless blending**: Cards don't look "cut out" from the background
- **Modern design**: Creates depth and hierarchy
- **Smooth transitions**: Gradient blur from 0% → 30% opacity

### **Why multiply blend mode?**
- **Color tinting**: Preserves category colors in the image
- **Visual coherence**: All cards feel part of the same design system
- **Better than overlay**: Darker, more readable text

---

## 🔒 Security & Storage

### **Storage Bucket: `challenges`**

**RLS Policies:**
```sql
-- Authenticated users can upload challenge images
CREATE POLICY "Authenticated users can upload challenge images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'challenges' AND (storage.foldername(name))[1] = 'challenge-images');

-- Public can view challenge images
CREATE POLICY "Public can view challenge images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'challenges');

-- Users can update their own challenge images
CREATE POLICY "Users can update their own challenge images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'challenges' AND owner = auth.uid());

-- Users can delete their own challenge images
CREATE POLICY "Users can delete their own challenge images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'challenges' AND owner = auth.uid());
```

**Access Control:**
- ✅ **Upload**: Only authenticated users
- ✅ **View**: Public (for discover page)
- ✅ **Update/Delete**: Only image owner

---

## 📱 User Experience Flow

### **Creating a Challenge:**

1. **Select Image** → Tap camera icon in create challenge screen
2. **Choose Photo** → Pick from camera roll
3. **Image Compresses** → Auto-compressed to ~1MB (1200px max)
4. **Upload** → Uploaded to Supabase Storage
5. **Challenge Created** → Image URL saved to database

### **Discovering Challenges:**

1. **Browse Discover Page** → Scroll through challenges
2. **Load Images** → `AsyncImage` loads custom images
3. **See Beautiful Cards** → Image + gradient overlay + blurred edges
4. **Fallback Gracefully** → If image fails, show default gradient

---

## 🎨 Design Specifications

### **Image Display:**
- **Aspect ratio**: Fill entire card (0.77 aspect ratio)
- **Gradient overlay**: 50% opacity of category colors
- **Edge blur gradient**: 4-step fade (0% → 0% → 10% → 30%)
- **Blend mode**: Multiply (for color tinting)
- **Corner radius**: 32pt (matches card)

### **Fallback Behavior:**
- **No image uploaded**: Show default gradient + decorative elements
- **Image load failure**: Show default gradient
- **Image loading**: Show default gradient as placeholder

---

## 🚀 Benefits

✅ **Personalization** - Creators can express their challenge theme
✅ **Visual appeal** - More engaging than plain gradients
✅ **Branding** - Corporate challenges can use company logos
✅ **Recognition** - Users recognize challenges by their images
✅ **Professionalism** - Elevated, modern design

---

## 🔄 Migration Steps

### **For Existing Databases:**

1. **Run SQL migration**: Execute `ADD_CHALLENGE_IMAGE_URL.sql`
2. **Create storage bucket**: Ensure `challenges` bucket exists
3. **Set RLS policies**: Apply storage policies from SQL script
4. **Test upload**: Create a test challenge with an image
5. **Verify display**: Check discover page shows image correctly

### **SQL Migration:**
```bash
# Run in Supabase SQL Editor:
psql -h your-host -U postgres -d postgres -f ADD_CHALLENGE_IMAGE_URL.sql
```

Or copy/paste the contents of `ADD_CHALLENGE_IMAGE_URL.sql` into Supabase SQL Editor.

---

## 📝 Files Modified

### **Models:**
- `StepComp/Models/Challenge.swift` - Added `imageUrl` property
- `StepComp/Models/SupabaseChallenge.swift` - Added `imageUrl` + CodingKey

### **Services:**
- `StepComp/Services/ChallengeService.swift` - Map `imageUrl` in conversions

### **ViewModels:**
- `StepComp/ViewModels/CreateChallengeViewModel.swift` - Added `uploadChallengeImage()`

### **Views:**
- `StepComp/Screens/Challenges/DiscoverChallengesTab.swift` - Display custom images

### **SQL:**
- `ADD_CHALLENGE_IMAGE_URL.sql` - Database migration script

---

## 🧪 Testing

### **Test Upload:**
```swift
1. Open app
2. Go to Create Challenge
3. Tap camera icon
4. Select an image
5. Fill in challenge details
6. Tap Create
7. Check console logs for "✅ Image uploaded successfully"
```

### **Test Display:**
```swift
1. Create a public challenge with an image
2. Navigate to Discover tab
3. Find your challenge
4. Verify:
   - Image loads and displays
   - Gradient overlay is applied
   - Edges are blurred
   - Text is readable
   - Card looks seamless
```

### **Test Fallback:**
```swift
1. Create a challenge WITHOUT an image
2. Navigate to Discover tab
3. Verify:
   - Default gradient shows
   - Decorative blur circles show
   - Icon watermark shows
```

---

## 💡 Future Enhancements

### **Potential Additions:**

1. **Image Filters** 🎨
   - Brightness/contrast adjustment
   - Built-in filters (vintage, vibrant, etc.)
   - Auto-enhance for better text contrast

2. **Smart Cropping** ✂️
   - Face detection centering
   - Auto-crop to optimal composition
   - Aspect ratio guides

3. **Image Templates** 🖼️
   - Pre-designed backgrounds
   - Category-specific templates
   - Seasonal themes

4. **Image Analytics** 📊
   - Track which images get most joins
   - A/B testing for challenge images
   - Suggest optimal images

5. **AI-Generated Images** 🤖
   - Generate images from challenge description
   - DALL-E/Midjourney integration
   - Text-to-image for quick creation

---

## ✅ Summary

**Added:**
- ✅ `image_url` column to `challenges` table
- ✅ Image upload to Supabase Storage
- ✅ Custom image display on discover cards
- ✅ Gradient overlay for readability
- ✅ Blurred edges for seamless blending
- ✅ Graceful fallback to default gradients

**Benefits:**
- 🎨 Personalized, beautiful challenge cards
- 📸 Professional, branded challenges
- 🚀 Enhanced user engagement
- ✨ Modern, polished design

**Result:**
Challenges now look AMAZING with custom images that blend seamlessly with the UI! 🎉✨


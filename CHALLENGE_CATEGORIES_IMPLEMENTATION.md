# Challenge Category & Tagging System Implementation

## Overview
Implemented a comprehensive tagging system for public challenges that allows users to categorize their challenges. Categories only appear when creating public challenges, ensuring better discoverability and organization.

---

## 🎯 Features Implemented

### 1. **Challenge Categories**
Five distinct categories for public challenges:

| Category | Icon | Description |
|----------|------|-------------|
| **Short Term** | ⚡ bolt.fill | Quick burst challenges (1-7 days) |
| **Friends** | 👥 person.3.fill | Compete with friends |
| **Corporate** | 🏢 building.2.fill | Company team challenges |
| **Marathon** | 🏃 figure.run | Long-term endurance challenges |
| **Fun** | 🎉 party.popper.fill | Casual & entertaining challenges |

### 2. **Smart UI Flow**
- **Privacy Toggle** moved to top (right after name input)
- **Category Selection** appears ONLY when "Public" is selected
- Smooth fade/slide animation when showing/hiding categories
- Required validation for public challenges

### 3. **Database Schema**
- New `category` column added to `challenges` table
- CHECK constraint ensures only valid categories
- Indexed for fast queries on public challenges
- RPC function to query challenges by category

---

## 📁 Files Modified

### 1. **ADD_CHALLENGE_CATEGORIES.sql** (NEW)
Complete database migration script including:
- `category` column addition with validation
- Index for performance (`idx_challenges_public_category`)
- RPC function: `get_public_challenges_by_category()`
- RPC function: `get_challenge_category_stats()`
- Verification queries

### 2. **StepComp/Models/Challenge.swift**
```swift
// Added ChallengeCategory enum
enum ChallengeCategory: String, Codable, CaseIterable {
    case shortTerm = "short_term"
    case friends = "friends"
    case corporate = "corporate"
    case marathon = "marathon"
    case fun = "fun"
    
    var displayName: String { /* ... */ }
    var icon: String { /* ... */ }
    var description: String { /* ... */ }
}

// Added category property
var category: ChallengeCategory?
```

### 3. **StepComp/ViewModels/CreateChallengeViewModel.swift**
```swift
// Added
@Published var selectedCategory: Challenge.ChallengeCategory? = nil

// Updated createChallenge() to:
// 1. Validate category is selected for public challenges
// 2. Include category in Challenge object
// 3. Only set category for public challenges (nil for private)

// Updated reset() to clear selectedCategory
```

### 4. **StepComp/Screens/CreateChallenge/CreateChallengeView.swift**
```swift
// Moved PrivacyToggleView to top (after name input)

// Added conditional category selector
if !viewModel.isPrivate {
    CategorySelectorView(selectedCategory: $viewModel.selectedCategory)
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .top)))
}

// Added new components:
// - CategorySelectorView
// - CategoryButton
```

---

## 🎨 UI Design

### Category Selector Card
- **Header**: "Choose a Category" with tag icon
- **Badge**: "Required for public" in gray
- **Horizontal Scroll**: 5 category buttons
- **Background**: Light gray tinted card with rounded corners

### Category Button
- **Circular Icon**: Large icon in circle (yellow when selected)
- **Title**: Bold category name
- **Description**: 2-line description
- **Selection State**: 
  - Selected: Yellow border, yellow circle background, bold text
  - Unselected: Gray border, white background, regular text
- **Animation**: Spring animation on tap

---

## 🔄 User Flow

### Creating a Private Challenge
1. Enter challenge name
2. See "Private" toggle (default ON)
3. ✅ No category selection appears
4. Continue with duration, start date, etc.

### Creating a Public Challenge
1. Enter challenge name
2. Toggle "Private" to OFF (becomes "Public")
3. 🎉 Category selector smoothly fades in
4. **Must select a category** (validation enforced)
5. Continue with duration, start date, etc.

### Validation
- If user tries to create public challenge without category → Error message
- Private challenges don't require category (automatically set to `nil`)

---

##  Database Functions

### Query Public Challenges by Category

```sql
-- Get all public challenges
SELECT * FROM get_public_challenges_by_category(NULL, 50, 0);

-- Get only "Friends" challenges
SELECT * FROM get_public_challenges_by_category('friends', 20, 0);

-- Get "Marathon" challenges
SELECT * FROM get_public_challenges_by_category('marathon', 10, 0);
```

**Returns:**
- Challenge details
- Creator profile (username, display_name, avatar_url)
- Member count
- Only active/upcoming challenges (end_date > NOW())

### Get Category Statistics

```sql
SELECT * FROM get_challenge_category_stats();
```

**Returns:**
- Category name
- Challenge count
- Total member count

---

## 🚀 How to Deploy

### Step 1: Run SQL Migration
```bash
# In Supabase SQL Editor, paste and run:
ADD_CHALLENGE_CATEGORIES.sql
```

### Step 2: Verify Database
```sql
-- Check column exists
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'challenges' AND column_name = 'category';

-- Check index exists
SELECT indexname FROM pg_indexes 
WHERE tablename = 'challenges' AND indexname = 'idx_challenges_public_category';
```

### Step 3: Test in App
1. Build and run the app
2. Tap "Create Challenge"
3. Enter a name
4. Toggle "Private" to OFF
5. ✅ Category selector should appear
6. Select a category
7. Complete challenge creation
8. ✅ Challenge should be created with category

---

## 🧪 Testing Checklist

- [ ] Privacy toggle appears right after name input
- [ ] Category selector hidden when "Private" is ON
- [ ] Category selector appears when "Public" is selected
- [ ] Smooth fade-in animation for category selector
- [ ] All 5 categories display correctly
- [ ] Category icons match descriptions
- [ ] Selecting a category shows yellow highlight
- [ ] Can switch between categories
- [ ] Cannot create public challenge without category (validation error)
- [ ] Private challenges create successfully without category
- [ ] Public challenges save category to database
- [ ] Created challenges show category in discovery tab

---

## 📊 Database Schema Details

### `challenges` Table - Updated

```sql
CREATE TABLE challenges (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    is_public BOOLEAN DEFAULT TRUE,
    category TEXT CHECK (category IN ('short_term', 'friends', 'corporate', 'marathon', 'fun')),
    invite_code TEXT UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast category queries
CREATE INDEX idx_challenges_public_category 
ON challenges (category, is_public) 
WHERE is_public = TRUE;
```

### Category Values
- `short_term` → "Short Term"
- `friends` → "Friends"
- `corporate` → "Corporate"
- `marathon` → "Marathon"
- `fun` → "Fun"

---

## 🔮 Future Enhancements

### Phase 2
1. **Filter Discovery Tab by Category**
   - Add category filter chips at top of discovery
   - Show challenge count per category
   - Allow multi-select filtering

2. **Category-Based Recommendations**
   - Suggest challenges based on user's past participation
   - "Similar Challenges" section

3. **Category Statistics**
   - Show trending categories
   - Display category-specific leaderboards

### Phase 3
4. **Custom Categories**
   - Allow users to create custom categories
   - Community voting on popular custom categories
   - Admin approval system

5. **Category Achievements**
   - Badges for completing challenges in each category
   - "Category Master" achievements

6. **Smart Category Suggestions**
   - AI-based category recommendations based on:
     - Challenge duration
     - Challenge name
     - Time of year
     - User's friend group

---

## 🐛 Troubleshooting

### Category selector not appearing
- **Issue**: Toggle is ON (Private mode)
- **Solution**: Toggle "Private" to OFF

### Can't create challenge - validation error
- **Issue**: Category not selected for public challenge
- **Solution**: Select one of the 5 categories

### Category not saving to database
- **Issue**: SQL migration not run
- **Solution**: Run `ADD_CHALLENGE_CATEGORIES.sql` in Supabase

### Category showing for private challenges
- **Issue**: UI bug
- **Solution**: Check `if !viewModel.isPrivate` condition in CreateChallengeView

---

## 📝 Code Examples

### Querying Challenges by Category in Swift

```swift
// Get all public "Friends" challenges
let response = try await supabase
    .rpc("get_public_challenges_by_category", params: [
        "p_category": "friends",
        "p_limit": 20,
        "p_offset": 0
    ])
    .execute()

let challenges = try response.decoded() as [Challenge]
```

### Creating a Public Challenge with Category

```swift
let challenge = Challenge(
    name: "Weekend Warriors",
    description: "Let's get moving!",
    startDate: Date(),
    endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
    targetSteps: 10000,
    creatorId: userId,
    category: .friends // Category set for public challenge
)

try await challengeService.createChallenge(challenge, isPublic: true)
```

---

## ✅ Summary

### What Was Implemented
✅ Database migration with `category` column
✅ 5 predefined categories with icons and descriptions
✅ Privacy toggle moved to top of form
✅ Conditional category selector (public only)
✅ Category validation for public challenges
✅ Smooth animations and transitions
✅ RPC functions for querying by category
✅ Updated Challenge model with ChallengeCategory enum
✅ Updated ViewModel with category logic
✅ New CategorySelectorView and CategoryButton components

### What's Ready to Test
🎉 Users can now create categorized public challenges
🎉 Category selection is intuitive and required for public challenges
🎉 Database is ready to store and query challenges by category
🎉 UI follows app's design system (yellow primary color)

**Status**: ✅ Complete and ready for testing!


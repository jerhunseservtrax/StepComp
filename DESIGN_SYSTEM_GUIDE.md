//
//  StepCompDesignSystemGuide.md
//  StepComp
//
//  Complete design system implementation guide
//

# StepComp Modern Dark Design System 🎨

## Overview
Modern, sleek dark UI inspired by fitness tracking apps with:
- Deep navy blue backgrounds
- Soft gradients
- Warm coral/orange accents
- SF Pro Rounded typography
- Glass-morphism effects

---

## 📐 Color System

### Background Colors
```swift
StepCompColors.background           // Deep navy #121929
StepCompColors.surface              // Card bg #1A2338
StepCompColors.surfaceElevated      // Elevated #212E47
```

### Primary & Accent
```swift
StepCompColors.primary              // Coral #F56B52
StepCompColors.accent               // Yellow #FDC233
StepCompColors.primaryYellow        // Legacy yellow (for compatibility)
```

### Text Colors
```swift
StepCompColors.textPrimary          // White 100%
StepCompColors.textSecondary        // White 65%
StepCompColors.textTertiary         // White 45%
```

### Accent Colors
```swift
StepCompColors.cyan                 // #3DC7D8
StepCompColors.purple               // #9473E0
StepCompColors.green                // #57CC8F
StepCompColors.orange               // #FA943D
```

### Status Colors
```swift
StepCompColors.success              // Green
StepCompColors.warning              // Yellow
StepCompColors.error                // Red #EF544F
```

---

## 🎨 Gradients

### Available Gradients
```swift
StepCompColors.primaryGradient      // Coral → Orange
StepCompColors.accentGradient       // Yellow → Light Yellow
StepCompColors.backgroundGradient   // Navy variations
StepCompColors.surfaceGradient      // Card gradients
```

### Usage
```swift
Rectangle()
    .fill(StepCompColors.primaryGradient)
```

---

## 🔤 Typography (SF Pro Rounded)

### Display Fonts (Large Headings)
```swift
.font(.stepDisplay())              // 34pt Bold
.font(.stepDisplayMedium())        // 28pt Bold
```

### Title Fonts
```swift
.font(.stepTitle())                // 24pt Bold
.font(.stepTitleMedium())          // 20pt Semibold
.font(.stepTitleSmall())           // 18pt Semibold
```

### Body Fonts
```swift
.font(.stepBody())                 // 16pt Medium
.font(.stepBodyRegular())          // 16pt Regular
.font(.stepBodySmall())            // 14pt Medium
```

### Caption/Label Fonts
```swift
.font(.stepCaption())              // 13pt Regular
.font(.stepCaptionBold())          // 13pt Semibold
.font(.stepLabel())                // 12pt Medium
.font(.stepLabelSmall())           // 11pt Medium
```

### Number/Stats Fonts (Monospaced)
```swift
.font(.stepNumber())               // 32pt Bold Monospaced
.font(.stepNumberMedium())         // 24pt Bold Monospaced
.font(.stepNumberSmall())          // 18pt Bold Monospaced
```

---

## 🃏 Card Styles

### 1. Dark Card (Default)
```swift
DarkCard {
    VStack {
        Text("Title").font(.stepTitle())
        Text("Content").font(.stepBody())
    }
}
```

**Features:**
- Surface background (#1A2338)
- Subtle border
- Drop shadow
- Customizable padding & radius

### 2. Elevated Card
```swift
ElevatedCard {
    // Content
}
```

**Features:**
- Elevated background (#212E47)
- Lighter border
- Softer shadow
- Feels "raised"

### 3. Gradient Card
```swift
GradientCard(gradient: StepCompColors.primaryGradient) {
    // Content
}
```

**Features:**
- Custom gradient background
- Glowing shadow matching gradient
- Eye-catching for CTAs

### 4. Glass Card (Frosted Glass)
```swift
GlassCard {
    // Content
}
```

**Features:**
- Ultra-thin material background
- Gradient border
- Frosted glass effect
- Modern, premium feel

---

## 🎭 View Modifiers

### Card Modifiers
```swift
VStack {
    // Content
}
.darkCard(padding: 20, cornerRadius: 20, showShadow: true)

VStack {
    // Content
}
.glassCard(padding: 16, cornerRadius: 16)
```

### Text Modifiers
```swift
Text("Primary")
    .stepTextPrimary()      // White 100%

Text("Secondary")
    .stepTextSecondary()    // White 65%

Text("Tertiary")
    .stepTextTertiary()     // White 45%
```

---

## 📱 Usage Examples

### Stats Card
```swift
DarkCard {
    VStack(spacing: 12) {
        HStack {
            Image(systemName: "figure.walk")
                .foregroundColor(StepCompColors.cyan)
            
            Spacer()
            
            Text("7,243")
                .font(.stepNumber())
                .stepTextPrimary()
        }
        
        Text("Steps Today")
            .font(.stepCaption())
            .stepTextSecondary()
    }
}
```

### CTA Button
```swift
GradientCard(gradient: StepCompColors.primaryGradient) {
    HStack {
        Text("Start Challenge")
            .font(.stepBody())
            .foregroundColor(.white)
        
        Spacer()
        
        Image(systemName: "arrow.right")
            .foregroundColor(.white)
    }
}
```

### Profile Card
```swift
GlassCard {
    HStack(spacing: 16) {
        Circle()
            .fill(StepCompColors.primaryGradient)
            .frame(width: 60, height: 60)
        
        VStack(alignment: .leading, spacing: 4) {
            Text("John Doe")
                .font(.stepTitleSmall())
                .stepTextPrimary()
            
            Text("Rank #3")
                .font(.stepCaption())
                .foregroundColor(StepCompColors.accent)
        }
        
        Spacer()
    }
}
```

---

## 🌈 Color Usage Guidelines

### When to Use Each Color

**Coral/Primary (`StepCompColors.primary`):**
- Primary CTAs
- Important alerts
- Winner/top performer highlights

**Yellow/Accent (`StepCompColors.accent`):**
- Secondary CTAs
- Achievements/badges
- Positive notifications

**Cyan (`StepCompColors.cyan`):**
- Walking/steps metrics
- Distance indicators
- Progress bars

**Purple (`StepCompColors.purple`):**
- Premium features
- Challenges
- Social features

**Green (`StepCompColors.green`):**
- Success states
- Goal completion
- Health metrics

**Orange (`StepCompColors.orange`):**
- Warnings
- Calories/energy
- Active states

---

## 🎯 Migration Guide

### Replacing Existing Colors

**Old → New:**
```swift
// Old
Color.black → StepCompColors.background
Color(.systemBackground) → StepCompColors.surface
Color(red: 0.976, green: 0.961, blue: 0.024) → StepCompColors.accent

// Old fonts
.font(.system(size: 28, weight: .bold)) → .font(.stepDisplayMedium())
.font(.system(size: 16, weight: .medium)) → .font(.stepBody())
```

### Replacing Card Styles

**Old → New:**
```swift
// Old
VStack {
    // Content
}
.padding()
.background(Color(.systemBackground))
.cornerRadius(16)
.shadow(radius: 4)

// New
DarkCard {
    // Content
}
```

---

## ✅ Best Practices

### DO's ✅
- Use SF Pro Rounded for consistency
- Stick to defined color palette
- Use `DarkCard` for most content
- Use gradients for emphasis
- Use monospaced fonts for numbers
- Apply semantic text colors

### DON'Ts ❌
- Don't use pure black backgrounds
- Don't mix font designs (.default, .serif)
- Don't create custom colors outside palette
- Don't use hard shadows (keep them soft)
- Don't override `.preferredColorScheme(.dark)`

---

## 🚀 Quick Start Checklist

1. ✅ Import color system: `StepCompColors`
2. ✅ Import fonts: `.font(.stepTitle())`
3. ✅ Wrap content in `DarkCard`
4. ✅ Use `.stepTextPrimary()` for white text
5. ✅ Use `.stepTextSecondary()` for muted text
6. ✅ Apply gradients for CTAs
7. ✅ Test in dark mode (forced globally)

---

## 📦 File Structure

```
StepComp/
└── Utilities/
    ├── StepCompColors.swift        ← Color definitions
    ├── StepCompFonts.swift         ← Typography system
    └── StepCompCardStyles.swift    ← Card components
```

---

## 🎨 Design Tokens Summary

| Token | Value | Usage |
|-------|-------|-------|
| **background** | #121929 | Main screen bg |
| **surface** | #1A2338 | Card bg |
| **surfaceElevated** | #212E47 | Elevated cards |
| **primary** | #F56B52 | CTAs, winners |
| **accent** | #FDC233 | Badges, achievements |
| **cyan** | #3DC7D8 | Steps, walking |
| **purple** | #9473E0 | Challenges, social |
| **green** | #57CC8F | Success, goals |

---

## 🔮 Advanced Techniques

### Custom Gradient Buttons
```swift
Button(action: {}) {
    Text("Start")
        .font(.stepBody())
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(StepCompColors.primaryGradient)
        .cornerRadius(16)
        .shadow(color: StepCompColors.primary.opacity(0.4), radius: 20, y: 10)
}
```

### Animated Gradient Cards
```swift
@State private var animateGradient = false

GradientCard(
    gradient: LinearGradient(
        colors: animateGradient 
            ? [StepCompColors.primary, StepCompColors.orange]
            : [StepCompColors.cyan, StepCompColors.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
) {
    // Content
}
.animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
.onAppear { animateGradient = true }
```

### Glass Overlay Modal
```swift
ZStack {
    // Background content
    
    // Overlay
    GlassCard {
        VStack {
            Text("Modal Title")
                .font(.stepTitle())
            // Modal content
        }
    }
    .padding()
}
```

---

## 🎓 Typography Hierarchy Example

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Display")
        .font(.stepDisplay())
        .stepTextPrimary()
    
    Text("Title")
        .font(.stepTitle())
        .stepTextPrimary()
    
    Text("Body content goes here")
        .font(.stepBody())
        .stepTextSecondary()
    
    Text("Caption or metadata")
        .font(.stepCaption())
        .stepTextTertiary()
}
```

---

## 🌟 Result

A modern, cohesive design system that feels:
- **Premium** - Glass effects and gradients
- **Readable** - High contrast, rounded typography
- **Consistent** - Semantic colors and fonts
- **Native** - SF Pro Rounded feels iOS-native
- **Dark** - Easy on eyes, modern aesthetic

Perfect for a fitness tracking app! 🏃‍♂️💪


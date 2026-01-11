# StepComp Typography Guide 🎨

Typography system matching the Yendo reference UI with **SF Pro Rounded** design.

---

## Font Hierarchy

### 📐 Display Fonts (Large Headings)
For branding, hero sections, large emphasis.

```swift
Text("StepComp")
    .font(.stepDisplay())  // 34pt, bold, rounded

Text("Welcome Back")
    .font(.stepDisplayMedium())  // 28pt, semibold, rounded
```

---

### 🎯 Title Fonts (Card Headers, Section Titles)
For section headers, card titles, modal headers.

```swift
Text("Daily Progress")
    .font(.stepTitle())  // 22pt, bold, rounded

Text("Active Challenges")
    .font(.stepTitleMedium())  // 18pt, semibold, rounded

Text("Today's Summary")
    .font(.stepTitleSmall())  // 16pt, semibold, rounded
```

---

### 📝 Body Fonts (Regular Content)
For descriptions, paragraphs, general text.

```swift
Text("Keep going! You're 60% to your goal.")
    .font(.stepBody())  // 15pt, medium, rounded

Text("Last updated 5 minutes ago")
    .font(.stepBodyRegular())  // 15pt, regular, rounded

Text("Tap to view details")
    .font(.stepBodySmall())  // 13pt, regular, rounded
```

---

### 🏷️ Caption/Label Fonts (Small Labels)
For metadata, timestamps, small labels like "Total Steps", "Deep".

```swift
Text("TOTAL STEPS")
    .font(.stepCaption())  // 12pt, regular, rounded

Text("3 DAYS AGO")
    .font(.stepCaptionBold())  // 12pt, semibold, rounded

Text("Active Now")
    .font(.stepLabel())  // 11pt, medium, rounded

Text("Online")
    .font(.stepLabelSmall())  // 10pt, medium, rounded
```

---

### 🔢 Number/Stats Fonts (Numeric Values)
For step counts, metrics, time values. **Monospaced digits** for alignment.

```swift
// Large main numbers (like "400" in reference)
Text("12,450")
    .font(.stepNumberLarge())  // 48pt, bold, rounded, monospaced

// Medium stats (like "3.0")
Text("8,920")
    .font(.stepNumber())  // 32pt, bold, rounded, monospaced

// Small numbers (like "3h45m")
Text("3h45m")
    .font(.stepNumberMedium())  // 22pt, semibold, rounded, monospaced

// Tiny numbers (graph labels)
Text("450")
    .font(.stepNumberSmall())  // 14pt, semibold, rounded, monospaced
```

---

## 🎨 Combined Style Modifiers

Quick shortcuts for common text styles with color included:

```swift
// Heading style (bold + white)
Text("Your Progress")
    .headingStyle()

// Subheading style (semibold + white)
Text("Weekly Summary")
    .subheadingStyle()

// Body style (medium + secondary color)
Text("You've completed 75% of your goal today.")
    .bodyStyle()

// Caption style (regular + tertiary color, muted)
Text("Updated 2m ago")
    .captionStyle()

// Stat style (large bold numbers + white)
Text("10,000")
    .statStyle()
```

---

## 🌈 Color Combinations

Match the reference UI by pairing fonts with the right colors:

```swift
// Primary text (white)
Text("Steps").font(.stepTitle()).stepTextPrimary()

// Secondary text (muted blue-gray)
Text("Total Steps").font(.stepCaption()).stepTextSecondary()

// Tertiary text (darker muted)
Text("Last week").font(.stepLabelSmall()).stepTextTertiary()
```

---

## 📱 Usage Examples from Reference UI

### Main Step Counter Card
```swift
VStack(spacing: 4) {
    Text("Steps")
        .font(.stepCaption())
        .stepTextSecondary()
    
    Text("400")
        .font(.stepNumberLarge())
        .stepTextPrimary()
    
    Text("Target 8000")
        .font(.stepLabelSmall())
        .stepTextTertiary()
}
```

### Sleep Stats List
```swift
HStack {
    Image(systemName: "moon.fill")
        .foregroundColor(StepCompColors.purple)
    
    Text("Deep")
        .font(.stepBody())
        .stepTextSecondary()
    
    Spacer()
    
    Text("3h45m")
        .font(.stepNumberMedium())
        .stepTextPrimary()
}
```

### Small Metric Label
```swift
VStack(alignment: .leading, spacing: 2) {
    Text("TOTAL STEPS")
        .font(.stepCaptionBold())
        .stepTextTertiary()
        .tracking(1.0)  // Uppercase + letter-spacing
    
    Text("12,450")
        .font(.stepNumber())
        .stepTextPrimary()
}
```

---

## ✅ Best Practices

1. **Always use `.rounded` design** - matches reference UI
2. **Use monospaced digits** for numbers that update (`.monospacedDigit()`)
3. **Pair with correct text colors** - primary (white), secondary (muted), tertiary (very muted)
4. **Keep weight hierarchy** - bold for headers, semibold for subheaders, medium/regular for body
5. **Use uppercase + tracking** for small labels like "TOTAL STEPS"

---

## 🚀 Global Initialization

Fonts are automatically configured in `StepCompApp.swift`:

```swift
init() {
    #if os(iOS)
    AppFontConfiguration.setupGlobalFonts()
    #endif
}
```

This applies rounded fonts to:
- Navigation bar titles
- Tab bar items
- Bar button items
- System alerts

---

## 🎯 Result

Your app now has the exact same soft, rounded, modern typography as the Yendo reference UI! 🎉


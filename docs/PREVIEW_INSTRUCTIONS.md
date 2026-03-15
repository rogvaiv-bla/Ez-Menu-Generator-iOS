# 🎨 Xcode Canvas Preview - Quick Start Guide

## Viewing App in Real-Time with Xcode Previews

### **Step 1: Open Xcode**
```bash
open "Ez Menu Generator.xcodeproj"
```

### **Step 2: Select a File with Preview**

Choose any of these files to see live previews:

#### 📱 **Main Views**
1. **ContentView.swift** (Main App - 4 tabs + Settings)
   - Path: `Views/ContentView/ContentView.swift`
   - Preview shows: Main app interface with tab navigation
   - Shows once household is set

2. **HouseholdOnboardingView.swift** (Onboarding)
   - Path: `Views/Household/HouseholdOnboardingView.swift`
   - Preview 1: "Onboarding - Create Mode" - Create household form
   - Preview 2: "Household Success" - QR code display + invite key
   - Shows when app first launches (no household set)

### **Step 3: Enable Canvas Preview**

In Xcode, with the file open:

**Option A: Menu**
```
Xcode → Editor → Canvas
(or press Option + Cmd + Return)
```

**Option B: Keyboard Shortcut**
```
⌥ + ⌘ + ↩
```

**Option C: Right-Click File**
```
Right-click file in Navigator → Show Canvas Preview
```

### **Step 4: Watch Live Preview**

The Canvas should show:
- ✅ Interactive preview of the View
- ✅ Real-time updates as you edit code
- ✅ Multiple device previews (iPhone, iPad, etc.)
- ✅ Light/Dark mode toggles
- ✅ Interaction simulation (tap buttons, scroll, etc.)

---

## 📊 Preview Details

### **ContentView Preview**
Shows the main app after household setup:
- 4 tabs: Meniuri, Rețete, Cumpărături, Nutriție
- ⚙️ Settings button (top-right)
- Empty states for demo

### **HouseholdOnboardingView Previews**

**Preview 1: Create Mode**
- Shows onboarding screen
- Tab toggle: "Crează" / "Alătură-te"
- Input fields for household name and username
- Create button

**Preview 2: Success Screen**
- Displays QR code (200×200 px)
- Shows invite key: "A1B2C3D4"
- Copy button for key
- 3-step instructions

---

## 🔧 Troubleshooting

### **Preview Not Showing?**

1. **Clean Build**
   ```bash
   ⌘ + Shift + K
   ```

2. **Rebuild Canvas**
   - Close Canvas (⌥ + ⌘ + ↩ again)
   - Open Canvas again (⌥ + ⌘ + ↩)

3. **Check Deployment Target**
   - Should be iOS 18.0+ for Previews
   - Menu: Product → Scheme → Edit Scheme → Run tab

4. **Check Preview Code**
   - All #Preview macros must have valid content
   - ModelContainer must include all @Model types

### **Preview Freezes?**

- This is normal if code has compilation errors
- Fix errors in file → Preview auto-refreshes
- Check Xcode console for error details

### **Preview Slow on Real Device?**

- Previews work best on Simulator, not real device
- Use iOS Simulator with Preview Canvas

---

## 🚀 Real-Time Development

Once Canvas is open:

1. **Edit code** → Preview updates automatically
2. **Add Views** → Add #Preview macro and see instantly
3. **Test interactions** → Tap buttons in preview
4. **Try dark mode** → Use Canvas device settings
5. **Check responsive** → Resize preview or test different devices

---

## 📋 Files with Preview Support

| File | Location | Type |
|------|----------|------|
| ContentView | Views/ContentView/ContentView.swift | Main App (Post-onboarding) |
| HouseholdOnboardingView | Views/Household/HouseholdOnboardingView.swift | Onboarding (2 previews) |

---

## 💡 Tips

- **Save file** (⌘ + S) to trigger preview refresh
- **Canvas slow?** Try limiting to 1 preview at a time
- **Multi-preview** → Swipe between previews in Canvas
- **Device selector** → Top-left Canvas toolbar

---

**Happy previewing! 🎨**

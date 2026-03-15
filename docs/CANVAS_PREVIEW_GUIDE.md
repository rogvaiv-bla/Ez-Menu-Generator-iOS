# 🎨 Canvas Preview - Real-Time App Visualization

## ✨ What You'll See

### **Preview 1: Onboarding Screen**
```
┌─────────────────────────┐
│      Bine ai venit!     │
│    Configurează-ți      │
│  household-ul           │
├─────────────────────────┤
│ [Crează] [Alătură-te]   │
│ (Tabs toggle)           │
├─────────────────────────┤
│ Nume Household:         │
│ [____________________]  │
│                         │
│ Numele tău:             │
│ [____________________]  │
│                         │
│ [ Crează Household ]    │
└─────────────────────────┘
```

### **Preview 2: Success Screen (with QR)**
```
┌─────────────────────────┐
│ ✓ Household creat!      │
│ "Familie Popescu"       │
├─────────────────────────┤
│ Invite Others           │
│                         │
│ ┌─────────────────────┐ │
│ │                     │ │
│ │   [QR CODE 200px]   │ │
│ │                     │ │
│ └─────────────────────┘ │
│                         │
│ Invite Key:             │
│ ┌─────────────────────┐ │
│ │ A1B2C3D4     [Copy] │ │
│ └─────────────────────┘ │
│                         │
│ Steps:                  │
│ 1. Share QR code        │
│ 2. They join with key   │
│ 3. Sync in real-time    │
└─────────────────────────┘
```

### **Preview 3: Main App (4 Tabs)**
```
┌─────────────────────────┐
│  Meniuri │ ⚙️         │ ◄─ Settings gear icon
├─────────────────────────┤
│                         │
│  📅 Meniuri             │
│  - Săptămâna 1          │
│  - Săptămâna 2          │
│                         │
├─────────────────────────┤
│ [Meniuri][Rețete]       │
│ [Cumpărături][Nutriție] │
│  ▲                      │
│  └─ 4 tabs at bottom    │
└─────────────────────────┘
```

---

## 🚀 Quick Start (60 seconds)

### **Method 1: Using Script (EASIEST)**
```bash
cd "/Users/eduard/Downloads/Ez Menu Generator"
./open_preview.sh
```

Then:
1. Wait for Xcode to open (10-15 sec)
2. Click: **ContentView.swift** in file navigator
3. Press: **⌥ + ⌘ + ↩** (or Editor → Canvas)
4. 🎉 Canvas Preview appears!

### **Method 2: Manual in Xcode**

1. **Open Xcode**
   ```bash
   open -a Xcode "/Users/eduard/Downloads/Ez Menu Generator/Ez Menu Generator.xcodeproj"
   ```

2. **File Navigator** (left sidebar)
   - Expand: `Ez Menu Generator/Views/ContentView/`
   - Click: `ContentView.swift`

3. **Enable Canvas**
   - Menu: **Xcode** → **Editor** → **Canvas**
   - OR Keyboard: **⌥ + ⌘ + ↩**

4. **Click "Resume"** (if preview paused)
   - Canvas shows app live preview

### **Method 3: From Source Files**

- **HouseholdOnboardingView.swift** → See onboarding + QR
- **ContentView.swift** → See main app with tabs
- Press ⌥ + ⌘ + ↩ on any file → Instant preview

---

## 🎯 What to Test in Preview

### **Onboarding Flow**
- [ ] "Crează" mode - input household name
- [ ] QR code displays (200×200)
- [ ] Invite key shows
- [ ] Copy button works
- [ ] "Alătură-te" mode - join with key

### **Main App Flow**
- [ ] 4 tabs visible (Meniuri, Rețete, Cumpărături, Nutriție)
- [ ] ⚙️ Settings button (top-right)
- [ ] Tab selection works (tap to switch)
- [ ] Settings sheet opens/closes

### **UI/UX**
- [ ] Layout is responsive
- [ ] Text readable
- [ ] Buttons tappable
- [ ] Colors/fonts consistent
- [ ] Icons display correctly

---

## 💡 Tips & Tricks

### **Auto-Refresh**
- Save file (**⌘ + S**) → Preview updates instantly
- No need to rebuild

### **Multiple Previews**
- HouseholdOnboardingView has 2 previews
- Swipe between them in Canvas
- Great for comparing designs

### **Device Switching**
- Canvas toolbar (top-left)
- Change device: iPhone 16, iPad, etc.
- Test responsive design

### **Rotate Device**
- Click device in Canvas
- Press landscape/portrait button
- See layout adapt

### **Dark Mode**
- Canvas settings → Appearance
- Toggle Light/Dark
- Preview in both modes

### **Slow Preview?**
- Close & reopen Canvas (⌥ + ⌘ + ↩ twice)
- Make sure no syntax errors
- Check Xcode console

---

## 📊 Preview Files

| File | Location | Previews | Shows |
|------|----------|----------|-------|
| **ContentView.swift** | Views/ContentView/ | 1 | Main app (4 tabs + settings) |
| **HouseholdOnboardingView.swift** | Views/Household/ | 2 | Onboarding + Success screen |

---

## 🔧 Troubleshooting

### **"Canvas is not available"**
- Check iOS deployment target ≥ 18.0
- Menu: Project → Build Settings → iOS Deployment Target

### **"Preview failed to build"**
- Check console for Swift errors
- Fix compilation errors
- Rebuild: ⌘ + B

### **Preview shows blank/gray**
- Click "Resume" in Canvas
- Check if preview is paused
- Rebuild project: ⌘ + Shift + K → ⌘ + B

### **Preview crashes with error**
- Models might be missing in ModelContainer
- Check #Preview macro - all @Model types included
- Example fix in ContentView.swift:
  ```swift
  #Preview {
      ContentView()
          .modelContainer(for: [
              Menu.self, Recipe.self, Ingredient.self,
              Household.self, HouseholdUser.self, // Add all @Model types
              ShoppingListV2.self, ShoppingItemV2.self
          ], inMemory: true)
  }
  ```

---

## 📝 What's Implemented

✅ **Preview Macros** added to:
- ContentView.swift (main app preview)
- HouseholdOnboardingView.swift (2 previews: onboarding + success)

✅ **ModelContainer Configuration** for Preview:
- All @Model types included
- In-memory database (no side effects)
- Light color scheme by default

✅ **Preview Scripts**:
- `open_preview.sh` - Launch script
- `PREVIEW_INSTRUCTIONS.md` - Detailed guide
- `CANVAS_PREVIEW_GUIDE.md` - This file

---

## 🎬 Next Steps

1. **Run the script**
   ```bash
   ./open_preview.sh
   ```

2. **Open Canvas Preview** (⌥ + ⌘ + ↩)

3. **Start editing** → Preview updates in real-time

4. **Test all flows** → Interact with preview UI

5. **Share feedback** → What works, what needs fixing

---

**Your app is now ready to preview in real-time! 🎨✨**

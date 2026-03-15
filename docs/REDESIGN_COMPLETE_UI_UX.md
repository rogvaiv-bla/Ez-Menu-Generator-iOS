# 🎨 Redesign Complet UI/UX - Ez Menu Generator

**Status:** Propunere Arhitectură
**Data:** 24.02.2026
**Target:** Product comercial, 2+ utilizatori, dark mode first, minimalism modern

---

## 📋 CUPRINS

1. [Arhitectura Informațională](#-arhitectura-informatională)
2. [Sistem de Design](#-sistem-de-design)
3. [Structura Tab-urilor](#-structura-tab-urilor)
4. [UX Flows Cheie](#-ux-flows-cheie)
5. [Recomandări Structurale](#-recomandări-structurale)
6. [Wireframe-uri Textuale](#-wireframe-uri-textuale)

---

## 🏗️ ARHITECTURA INFORMAȚIONALĂ

### **Decizia 1: Reorganizarea Bottom Tabs**

#### **PROPUNERE: 4 Tabs Principali (DOWN din 4)**

```text
┌─────────────────────────────────┐
│  Home │ Recipes │ Shop │ Analyze │
└─────────────────────────────────┘

```text

**Rațiune:**

- Tab-ul actual "Meniu" devine "Home" (conținut mai larg, nu doar planning)

- "Rețete" rămâne dar cu rol diferit (biblioteca + favorite)

- "Cumpărături" rămâne (necessity core)

- "Nutriție" devine "Analyze" (scanare produse + tracking)

---

### **Decizia 2: Top Bar Restructurat**

#### **CURRENT → PROPOSED**

```text
CURRENT:
[Undo] [Redo] [Magic] [+Add] | ... [Settings]

PROPOSED:
[<] | Contextual Title | [🔍] [⚙️] [👥]

```text

**Migrări:**

| Feature | Din | În | Rațiune |
|---------|-----|--|---------
| Undo/Redo | Top Bar | Context menu long-press pe card | Economia de spațiu, acțiune rară |
| Magic Wand | Top Bar | Home tab, prominent CTA button | Discovery, feature principal |
| Add | Top Bar | Context-specific (+ icon în fiecare tab) | Intuitivitate contextbucă |
| Settings | Top Bar | Bottom sheet (⚙️ icon) | Raritate usage |
| Search | NEW | Top right (🔍) | Navigation rapid |
| Household | NEW | Top right (👥 avatar) | Multi-user aware |

**Layout Final Top Bar:**

```text
┌─────────────────────────────────────────────┐
│ < │ Weekly Menu │ 🔍 ⚙️ 👥
└─────────────────────────────────────────────┘

```text

---

### **Decizia 3: Informații Secundare**

#### **Ce nu intră în bottom tabs:**

- **Alergeni & Intoleranțe** → Settings > Health Profile

- **Dietary preferences** → Settings > Preferences (selectare globală)

- **Household members** → Settings > Household (management)

- **Impact mediu** → In-product tooltip pe product card

- **Istoric scanări** → Analyze tab, subnav "History"

#### **Ce devine subnav/segmented control:**

```text
Recipes Tab:
├─ All Recipes (default)
├─ Favorites ⭐
└─ Saved (future)

Analyze Tab:
├─ Scan (default)
├─ History
├─ Compare (when 2+ selected)
└─ Recommendations

```text

---

## 🎯 SISTEM DE DESIGN

### **1. Spacing System (8px base unit)**

```text
Micro:    4px   (icon padding, tight spacing)
Small:    8px   (component padding, badge spacing)
Medium:   16px  (section margins, card padding)
Large:    24px  (major sections)
XL:       32px  (inter-section gaps)

```text

**Exemplu aplicare:**

```text
Card:
├─ Padding: 16px (Medium)
├─ Icon-text gap: 8px (Small)
├─ Border radius: 12px
└─ Shadow: 0 2px 8px rgba(0,0,0,0.3)

```text

---

### **2. Typography Scale**

```text
Display:  24px, weight 700, line-height 32px  → Page titles
Headline: 18px, weight 600, line-height 24px  → Section headers
Title:    16px, weight 600, line-height 22px  → Card titles, tabs
Body:     14px, weight 400, line-height 20px  → Main content
Label:    12px, weight 500, line-height 16px  → Tags, captions
Helper:   11px, weight 400, line-height 16px  → Timestamps, hints

```text

**Font System:**

- Primary: Inter (open source, clean, neutral)

- Fallback: System SF Pro

---

### **3. Color System (Dark Mode First)**

#### **Base Palette:**

```text
Background:
├─ Primary:      #0A0E27 (main bg)
├─ Secondary:    #1A1F3A (cards, layers)
├─ Tertiary:     #2D3250 (subtle elevated)
└─ Surface:      #3D4563 (borders, dividers)

Text:
├─ Primary:      #FFFFFF (main text)
├─ Secondary:    #B4BAC4 (secondary, captions)
└─ Tertiary:     #7A8196 (hints, disabled)

Accent Colors:
├─ Primary:      #7C5CFF (actions, highlights)
├─ Secondary:    #00D476 (success, healthy)
├─ Warning:      #FFB84D (caution, warnings)
└─ Danger:       #FF6B6B (errors, negative)

Score-specific:
├─ Nutri Green:  #4ECB71 (scores 80+)
├─ Nutri Yellow: #FFD93D (scores 40-79)
├─ Nutri Red:    #FF6B6B (scores <40)
└─ Eco Score:    #00D476 (A), #FFD93D (B), #FF6B6B (C)

```text

#### **Dark Mode Specs:**

- No pure white (#FFF) - folosiți #F8F9FB pentru highlights

- Contrast minimum 4.5:1 pentru text

- Disabled state: 40% opacity pe secundar

---

### **4. Icon Logic**

```text
Navigation:
└─ Home, Recipes, Shop, Analyze (filled when active)

Actions:
└─ + (Add), 🔍 (Search), ⚙️ (Settings), 👥 (Household)

Product Status:
├─ ⭐ (Favorite)
├─ 🛒 (In cart)
├─ ✓ (Completed/Scanned)
└─ ⚠️ (Alert/Allergen)

Scoring:
├─ Numeric badges (Nutri: 85, Eco: A)
└─ Color-coded circles

Meals:
├─ 🍳 (Breakfast)
├─ 🥗 (Lunch)
├─ 🍽️ (Dinner)
└─ 🍰 (Dessert)

```text

---

### **5. Card System**

#### **Universal Card Specs:**

```text
├─ Borderless design (only subtle shadow)
├─ 12px border radius
├─ Padding: 16px
├─ Background: Secondary color
├─ Shadow: 0 2px 8px rgba(0,0,0,0.3)
├─ Hover: +2px shadow, background shift +1 stop
└─ Pressed: -1px shadow, background -1 stop

```text

#### **Card Types:**

**A. Recipe Card (Recipes tab, Meal planning)**

```text
┌──────────────────────────┐
│ [Image|12x12px] 20%     │  ← Thumbnail + calorie % of daily
├──────────────────────────┤
│ Pasta Carbonara          │  ← Title (14px, weight 600)
│ By @username             │  ← Author (12px, secondary)
│ 📊 Nutri: 75 | Kcal: 530 │  ← Metadata inline
│ 🕐 30 min | Serv: 2      │  ← Time + servings
│ 🥚 🧈 🍝 ... (4 icons)   │  ← Ingredient icons (visual clue)
├──────────────────────────┤
│ [⭐] [+] [...]            │  ← Actions row
└──────────────────────────┘

```text

**B. Product Card (Scan/Analyze tab)**

```text
┌──────────────────────────┐
│ [Product Image]          │  ← 1:1 image
├──────────────────────────┤
│ Coca-Cola - 330ml        │  ← Name + volume
│ Brand: The Coca-Cola Co. │  ← Brand (optional, hover)
├──────────────────────────┤
│ 💚 Nutri: 35 | Eco: B    │  ← Score badges
│ ⚠️ HIGH Sugar: 39g       │  ← Alert row (if relevant)
├──────────────────────────┤
│ [👁️ Details] [🛒 Add]    │  ← Quick actions
└──────────────────────────┘

```text

**C. Shopping Item Card (Shop tab)**

```text
┌──────────────────────────────┐
│ [✓] Carne de pui - 500g   │  ← Checkbox, auto-strikethrough
│     €2.50 | Store: Auchan   │  ← Price + store hint
│     [🏠] [Qty: 1] [...]     │  ← Household owner, qty, menu
└──────────────────────────────┘

```text

**D. Meal Slot Card (Home tab, weekly view)**

```text
┌──────────────────────────────┐
│ 🍳 Monday Breakfast       │
├──────────────────────────────┤
│ [Small recipe img] 08:00  │  ← Time hint
│ Scrambled Eggs & Toast    │
│ 🥚 2 | 🧈 1 | 🍞 2       │  ← Quick ingredients
│ Kcal: 320 (25% daily)     │  ← Calorie indicator
├──────────────────────────────┤
│ [Swap] [Remove] [+Notes]   │  ← In-card actions
└──────────────────────────────┘

```text

---

## 📱 STRUCTURA TAB-URILOR

### **TAB 1: HOME (Weekly Planning + Overview)**

#### **Purpose:**

- Central hub pentru planning săptămânal

- Quick view al ziuei curente

- Magic wand prominent

- Health score agregat

#### **Layout estructura:**

```text
┌─────────────────────────────────┐
│ < │ Weekly Menu 24-30 Feb │🔍 ⚙️ 👥│
├─────────────────────────────────┤
│ [TODAY CARD]                    │
├─────────────────────────────────┤
│ 📊 Weekly Overview              │
│ ├─ Avg Kcal: 2100              │
│ ├─ Diversity: 14 unique recipes │
│ └─ Eco Score: B (avg)          │
├─────────────────────────────────┤
│ 🌟 AI SUGGESTIONS               │
│ [·Magic Wand - Generate Menu] │  ← CTA prominent
│                                 │
│ Week View (swipeable):          │
│ ┌─────────────────────────────┐│
│ │ MON │ TUE │ WED │ THU │ ... ││
│ ├─────────────────────────────┤│
│ │🍳 Omelet    │🥗 Salad ...  ││
│ │🥗 Pasta    │🍽️ Fish     ││
│ │🍽️ Pork      │🍝 Risotto ... ││
│ │🍰 Pie       │🍰 Mousse ... ││
│ └─────────────────────────────┘│
│                                 │
│ [Generate] [Randomize] [Reset] │ ← Batch actions
│                                 │
│ 🛒 SMART SHOPPING               │
│ Generate shopping list from this week
│ [Generate Now]                  │
│                                 │
└─────────────────────────────────┘

```text

#### **Empty States:**

```text
FIRST TIME:
┌─────────────────────────────────┐
│ 🎯 Welcome to Meal Planning     │
│                                 │
│ [🌟 Generate First Menu]       │ ← CTA primary
│                                 │
│ or                              │
│                                 │
│ [📚 Browse Recipes] [+Create]  │ ← Secondary CTAs
└─────────────────────────────────┘

NO MENU SELECTED:
┌─────────────────────────────────┐
│ 📭 No menu planned              │
│                                 │
│ [🌟 Generate Menu] [+Create New]│
└─────────────────────────────────┘

```text

#### **Interactions:**

- **Week navigation:** Swipe left/right sau selectie data

- **Meal swap:** Long-press pe meal → sugestii alternative

- **Generate:** Modal wizard 3 steps
  - Step 1: Budget/time/dietary
  - Step 2: Preview generates
  - Step 3: Confirm or regenerate

---

### **TAB 2: RECIPES (Discovery + Library)**

#### **Purpose:**

- Browse public/personal recipes

- Quick favorites access

- Discovery recommendations

- Multi-selection compare

#### **Layout estructura:**

```text
┌─────────────────────────────────┐
│ < │ Recipes │ All/⭐/Saved | 🔍 │
├─────────────────────────────────┤
│ [SEGMENTED CONTROL]             │
│ All Recipes | ⭐ Favorites      │
├─────────────────────────────────┤
│                                 │
│ FILTERING (collapsible)         │
│ ├─ Dietary: All/Vegan/Keto... │
│ ├─ Time: <15 min / <30 min...  │
│ ├─ Kcal: 0-2000 (slider)       │
│ └─ [Reset]                     │
│                                 │
│ RESULTS (scrollable grid):      │
│ ┌──────────┐ ┌──────────┐     │
│ │ Recipe 1 │ │ Recipe 2 │     │
│ │ (card)   │ │ (card)   │     │
│ └──────────┘ └──────────┘     │
│                                 │
│ ┌──────────┐ ┌──────────┐     │
│ │ Recipe 3 │ │ Recipe 4 │     │
│ │ (card)   │ │ (card)   │     │
│ └──────────┘ └──────────┘     │
│                                 │
│ [Load More] sau infinite scroll │
│                                 │
└─────────────────────────────────┘

```text

#### **Grid Behavior:**

- **Handheld:** 2 columns

- **iPad:** 3 columns

- **Gesture:** Single tap → detail, long-press → menu (favorite, compare, share)

#### **Empty States:**

```text
NO RECIPES:
┌─────────────────────────────────┐
│ 📚 Recipe library empty         │
│                                 │
│ [+ Create First Recipe]        │
│ [Browse Public Recipes]        │
└─────────────────────────────────┘

NO FAVORITES:
┌─────────────────────────────────┐
│ ⭐ No favorites yet            │
│                                 │
│ Tap ⭐ on recipes to add here   │
└─────────────────────────────────┘

SEARCH NO RESULTS:
┌─────────────────────────────────┐
│ ❌ No recipes match filters     │
│                                 │
│ [Clear filters] [Browse all]   │
└─────────────────────────────────┘

```text

---

### **TAB 3: SHOP (Smart Shopping List)**

#### **Purpose:**

- Manage shared shopping list

- Track items across household

- Price/store hints

- Link to products (for re-scan)

#### **Layout estructura:**

```text
┌─────────────────────────────────┐
│ < │ Shopping List │ ✓ Pending | 🔍│
├─────────────────────────────────┤
│ [SEGMENTED CONTROL]             │
│ Pending | ✓ Completed          │
├─────────────────────────────────┤
│ 👤 Eduard (5 items pending)     │  ← Group by user/household
│ ┌─────────────────────────────┐ │
│ │ ☐ Carne de pui - 500g      │ │
│ │    €2.50 | Auchan           │ │
│ │    From: Pork Chops meal    │ │
│ ├─────────────────────────────┤ │
│ │ ☐ Unt - 250g              │ │
│ │    €1.20 | Lidl             │ │
│ │    From: Breakfast x2       │ │
│ └─────────────────────────────┘ │
│                                 │
│ 👤 Partner (2 items pending)    │
│ ┌─────────────────────────────┐ │
│ │ ☐ Brânză - 300g           │ │
│ │    €3.00 | Auchan           │ │
│ │    From: Salad             │ │
│ └─────────────────────────────┘ │
│                                 │
│ 📊 Statistics:                  │
│ Total items: 7 / Est. price: €18│
│ Stores: Auchan (5), Lidl (2)   │
│                                 │
│ [Clear completed] [Print list] │
│ [Export to note] [Share +]     │  ← Multi-action
│                                 │
└─────────────────────────────────┘

```text

#### **Item Interaction:**

```text
Single tap: Toggle checkbox (strikethrough)
Long press menu:
├─ Edit qty/unit
├─ Change store
├─ Scan product details (if available)
├─ View nutrition (if added from recipe)
└─ Delete

```text

#### **Empty States:**

```text
EMPTY PENDING:
┌─────────────────────────────────┐
│ ✓ You're all set!               │
│                                 │
│ No pending items. Generate from │
│ this week's menu?               │
│ [Generate from Menu]           │
└─────────────────────────────────┘

EMPTY COMPLETED:
┌─────────────────────────────────┐
│ 🛒 Start shopping!              │
│                                 │
│ Items will appear here          │
└─────────────────────────────────┘

```text

---

### **TAB 4: ANALYZE (Product Scanning + Tracking)**

#### **Purpose:**

- Quick scan products (barcode/image)

- View detailed nutrition + scoring

- Compare products

- Track intake (macros, kcal)

- Recommendations

#### **Layout estructura (Default: Scan State):**

```text
┌─────────────────────────────────┐
│ < │ Analyze │ Scan/History/Compare│
├─────────────────────────────────┤
│ [SEGMENTATION / TABS]           │
│ Scan | History | Compare       │
├─────────────────────────────────┤
│                                 │
│        [🔍 SCAN BUTTON]         │  ← Large, prominent
│    (with camera + barcode hint) │
│                                 │
│    or drag image here           │
│    or type product name         │
│                                 │
│ ─────────────────────────────── │
│ 🕐 RECENT SCANS                 │
│                                 │
│ 1. Coca-Cola - 5min ago        │
│    [Product Card: Nutri 35, ...] │
│                                 │
│ 2. Yogurt - 30min ago          │
│    [Product Card: Nutri 78, ...] │
│                                 │
│ [View more in History]         │
│                                 │
└─────────────────────────────────┘

```text

#### **Layout estructura (History State):**

```text
┌─────────────────────────────────┐
│ < │ Analyze │ Scan/History/✓    │
├─────────────────────────────────┤
│ [DATE FILTER]                   │
│ Today | This week | This month  │
├─────────────────────────────────┤
│                                 │
│ TODAY (3 scans)                 │
│ ├─ Coca-Cola → 08:20          │
│ ├─ Eggs → 12:15               │
│ └─ Bread → 18:45              │
│                                 │
│ YESTERDAY (1 scan)              │
│ ├─ Milk → 08:10               │
│                                 │
│ THIS WEEK (...)                 │
│ [Load more]                     │
│                                 │
│ 📊 Weekly Summary:              │
│ Avg Nutri Score: 68             │
│ Avg Eco Score: B                │
│ Most scanned: Soft drinks (6)  │
│                                 │
└─────────────────────────────────┘

```text

#### **Scan To Product Detail Flow:**

```text
SCAN COMPLETE → PRODUCT DETAIL MODAL:

┌──────────────────────────────────┐
│  X │ Coca-Cola - 330ml │ [•••]   │
├──────────────────────────────────┤
│  [Large Product Image]           │
├──────────────────────────────────┤
│  SCORES (horizontal scroll):     │
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │ 💚   │ │ 🌍   │ │ 🔔   │    │
│  │Nutri │ │ Eco  │ │Health│    │
│  │ 35   │ │ C    │ │Alert │    │
│  └──────┘ └──────┘ └──────┘    │
│                                  │
│  QUICK INFO:                     │
│  • Brand: The Coca-Cola Co.      │
│  • Volume: 330ml                 │
│  • Price: €1.20                  │
│  • Store: Randomly updated       │
│                                  │
│  NUTRITION PANEL (expandable):   │
│  ┌────────────────────────────┐ │
│  │ Serving: 100ml             │ │
│  │ Kcal: 42                   │ │
│  │ Fat: 0g                    │ │
│  │ Carbs: 10.6g ⚠️ HIGH SUGAR│ │
│  │ Protein: 0g                │ │
│  │ Fiber: 0g                  │ │
│  └────────────────────────────┘ │
│                                  │
│  ALERTS & TAGS:                  │
│  ⚠️ High Sugar (39g/100ml)       │
│  ⚠️ No fiber                     │
│  💡 Eco: Recyclable packaging    │ │
│                                  │
│  RECOMMENDATIONS:                │
│  💡 Similar products with        │
│     better Nutri score:          │
│  ├─ Sprite Zero Sugar            │
│  │  [Nutri: 85 vs 35]           │
│  └─ Fanta Orange Zero            │
│     [Nutri: 82 vs 35]           │
│                                  │
│  ACTIONS ROW:                    │
│  [🛒 Add to cart] [⭐ Save]     │
│  [🔗 Link to meal] [📸 Re-scan] │
│                                  │
│  [Full nutrition] [Share] [+]   │
│                                  │
└──────────────────────────────────┘

```text

#### **Compare State (when 2+ items selected):**

```text
COMPARE MODE ACTIVATED:

┌──────────────────────────────────┐
│ < │ Compare (2) │ ✓ Done        │
├──────────────────────────────────┤
│                                  │
│ SIDE-BY-SIDE COMPARISON:         │
│ ┌──────────────┬──────────────┐ │
│ │ Coca-Cola    │ Fanta Orange │ │
│ ├──────────────┼──────────────┤ │
│ │ [Image] 330ml│ [Image] 330ml│ │
│ ├──────────────┼──────────────┤ │
│ │ Nutri: 35 ◄──│ Nutri: 82   │ │ ← Visual indicator
│ │ Eco: C   ◄───│ Eco: B      │ │
│ │ Health: ⚠️   │ Health: ✓   │ │
│ ├──────────────┼──────────────┤ │
│ │ Kcal: 42     │ Kcal: 48    │ │
│ │ Sugar: 10.6g │ Sugar: 12g  │ │
│ │ Fiber: 0g    │ Fiber: 0g   │ │
│ ├──────────────┼──────────────┤ │
│ │ €1.20        │ €1.30       │ │
│ └──────────────┴──────────────┘ │
│                                  │
│ KEY DIFFERENCES:                 │
│ • Fanta has better Nutri score   │
│ • Coca has lower price           │
│ • Both high in sugar             │
│                                  │
│ RECOMMENDATION:                  │
│ 💡 For better nutrition, choose  │
│    Fanta Orange (higher score)   │
│                                  │
│ [Add both to cart] [Choose one] │
│                                  │
└──────────────────────────────────┘

```text

---

## 🎬 UX FLOWS CHEIE

### **FLOW 1: Generate Menu Automat (Magic Wand)**

```text
USER ACTIVATION:
Home Tab → [Magic Wand] button tapped

↓

STEP 1: PREFERENCES MODAL
┌───────────────────────────────────┐
│ Generate Smart Menu                │
├───────────────────────────────────┤
│ Budget per meal: €3-5              │
│ [Slider: €0 → €10]                │
│                                    │
│ Time availability:                 │
│ ◆ Quick (<15 min)                 │
│ ◆ Standard (15-45 min)            │
│ ◇ Flexible (any)                  │
│                                    │
│ Dietary restrictions:              │
│ ☐ Vegan                           │
│ ☐ Keto                            │
│ ☐ Gluten-free                     │
│ ☐ Lactose-free                   │
│ ☐ Custom allergies...             │
│                                    │
│ Diversity:                         │
│ ◆ Exclude repeats per week        │
│ ◆ Mix similar proteins            │
│ ◇ Allow repetition               │
│                                    │
│ [Cancel] [Next] ────────→ STEP 2
└───────────────────────────────────┘

↓

STEP 2: GENERATION + PREVIEW
┌───────────────────────────────────┐
│ Generating menu...        [50%]    │
│                                    │
│ 🔄 AI is analyzing recipes...     │
│                                    │
│ [Generating meals for Mon-Sun]    │
│                                    │
│ Preview generated meals:           │
│ ├─ Monday: Pasta (NEW), Salad...  │
│ ├─ Tuesday: Fish (SAVED), Rice... │
│ ├─ Wednesday: Chicken, Veggies... │
│ ... (list continues)               │
│                                    │
│ [< Regenerate] [Preview] [Next >] │
└───────────────────────────────────┘

↓

STEP 3: CONFIRM + APPLY
┌───────────────────────────────────┐
│ Menu Preview - Mon 24 - Sun 2 Mar  │
├───────────────────────────────────┤
│                                    │
│ 📊 Stats:                          │
│ • 7 days, 21 meals                │
│ • Avg Kcal: 2150/day              │
│ • Est. cost: €45                  │
│ • Unique recipes: 11              │
│ • Avg Nutri: 72                   │
│                                    │
│ MEAL PREVIEW (scrollable):         │
│ [Daily view grid shown above]      │
│                                    │
│ SHOPPING ESTIMATE:                │
│ Estimated items: 34               │
│ Est. total: €45 (€6.4/day)        │
│                                    │
│ Ready to use this menu?            │
│                                    │
│ [← Back] [Regenerate] [✓ Confirm]│
│          [Save as draft]           │
└───────────────────────────────────┘

↓

CONFIRMATION
Weekly menu generated ✓
Shopping list ready
[Open Menu] [Open Shopping List]

```text

**Decizie UX:**

- Wizard 3-step > 1 complex form (cognitive load)

- Visual preview @ each step

- Permite regenerate fără restart

---

### **FLOW 2: Scanare Produs (Focus Mode)**

```text
USER ACTIVATION:
Analyze Tab → [Scan] button

↓

CAMERA CAPTURE MODAL
┌───────────────────────────────────┐
│ X │ [Flashlight] Scan barcode   │
├───────────────────────────────────┤
│                                    │
│        [Camera viewfinder]        │
│        [┌──────────────────┐]     │
│        [│  🎯 SCAN HERE    │]     │
│        [│  Barcode/front   │]     │
│        [│                   │]     │
│        [└──────────────────┘]     │
│                                    │
│ 💡 Align barcode or product       │
│    front with square              │
│                                    │
│ [Cancel] [Upload image]           │
│                                    │
│ or type product name...           │
│ [Search by name...]               │
│                                    │
└───────────────────────────────────┘

↓ (Scan successful)

LOADING + MATCHING
┌───────────────────────────────────┐
│ Analyzing product...   [▓▓▓░░░░░░]│
│                                    │
│ 🔎 Matching barcode:               │
│    1234567890123                   │
│                                    │
│ 💾 Found in database               │
│ ✓ Coca-Cola 330ml                 │
│                                    │
│ 📊 Loading nutrition data...       │
│ 🌍 Fetching Eco score...           │
│                                    │
│ [Still scanning? ← Try again]     │
│                                    │
└───────────────────────────────────┘

↓ (Success)

PRODUCT DETAIL (shown above in ANALYZE tab)
[Detailed modal with scores, nutrition, etc.]

Next action options:

- [Add to cart] → Shopping list

- [Link to meal] → Select meal date

- [Compare] → Select another product

- [Save] → Favorites

- [← Scan another]

```text

**Decizie UX:**

- Fullscreen camera (immersive)

- Quick type fallback (no camera permission)

- Auto-forward la detail

- "Scan another" loop (batch scanning)

---

### **FLOW 3: Comparare 2 Produse**

```text
ENTRY POINTS:
1. From product detail: [Compare] → Select another
2. From history: Long-press product → "Compare" → select second
3. From shopping: Select 2 items → [Compare]

↓

SELECT PRODUCTS
Scan/Search first:        ┌──────────────┐
┌─────────────────────────┤ Coca-Cola    │
│ Product 1 selected ✓    │ 330ml        │
└─────────────────────────┴──────────────┘

Then scan/search second:
[Scan or search...]       ┌──────────────┐
                          │ Fanta Orange │
                          │ 330ml        │
                          └──────────────┘

↓

COMPARISON MODAL
[Shown above in ANALYZE > Compare section]

Features displayed:

- Side-by-side visuals

- All 3 scores (Nutri, Eco, Health)

- Full nutrition table

- Price comparison

- Smart recommendations

- Difference highlighting

↓

DECISION
User selects one to add/keep:
[Add both to cart] or [Choose one]
→ Returns to cart / history

```text

**Decizie UX:**

- Lightweight (no mode switch)

- Visual diff highlighting

- Recommendation engine included

- Direct action post-compare

---

### **FLOW 4: Adăugare la Favorite**

```text
ENTRY POINTS:
1. Recipe card → [⭐] button
2. Product card → [⭐] button
3. Product detail → [⭐ Save] button

↓

TAP STAR ICON
┌─────────────────────────────────┐
│ ⭐ Adding to favorites...       │
│                                  │
│ (1-2 second animation)           │
│                                  │
│ ✓ Added to Favorites!            │
│                                  │
│ Card: ⭐ (now filled, highlight) │
│ Toast: "Added to ⭐ New badge   │
│                                  │
└─────────────────────────────────┘

↓

LONG-TERM MANAGEMENT
Navigate to:

- Recipes Tab → ⭐ Favorites segment

- Analyze Tab → ⭐ (future) Favorites segment

Both show full list of saved items
with ability to:

- Un-favorite (tap ⭐ again)

- View details

- Add to meals/cart

- Delete

```text

**Decizie UX:**

- Instant feedback (1-tap, visual)

- No confirmation dialogs (UX friction)

- Aggregated favorite views per tab

- Toast notification (discoverable)

---

### **FLOW 5: Meniu Săptămânal - Schimbare Rețetă**

```text
HOME TAB WEEKLY VIEW

User sees meal slot:
┌────────────────────────┐
│ 🍽️ Monday Lunch       │
│ Pasta Carbonara        │
│ [Swap] [Remove] [+]    │
└────────────────────────┘

↓ (User taps [Swap])

RECIPE SELECTOR MODAL
┌───────────────────────────────────┐
│ < │ Select Recipe for Mon Lunch   │
├───────────────────────────────────┤
│                                    │
│ 💭 AI SUGGESTIONS (3):             │
│ ┌──────────────────────────────┐  │
│ │ 🤖 Similar proteins:         │  │
│ │ • Baked Salmon (Nutri: 85)   │  │
│ │ • Grilled Chicken (Nutri: 82)│  │
│ │ • Tofu Stir-fry (Nutri: 78)  │  │
│ └──────────────────────────────┘  │
│                                    │
│ FILTERS:                           │
│ • Time: <15 min                    │
│ • Dietary: All                     │
│ • Kcal: Any                        │
│                                    │
│ ALL RECIPES (grid):                │
│ [Recipe card] [Recipe card] ...    │
│                                    │
│ [Tap recipe to select]             │
│                                    │
│ [Random pick] [Generate new]      │
│                                    │
└───────────────────────────────────┘

↓ (User selects recipe)

CONFIRMATION + APPLY
┌───────────────────────────────────┐
│ ✓ Recipe changed!                 │
│                                    │
│ Monday Lunch: Baked Salmon        │
│ (Previously: Pasta Carbonara)     │
│                                    │
│ Updated nutrition:                │
│ Avg weekly Kcal: 2140 (vs 2150)  │
│                                    │
│ Shopping list updated (X changes) │
│                                    │
│ [Undo] [Done]                    │
│                                    │
└───────────────────────────────────┘

↓ (User views Home tab again)

Weekly view updated with new meal

```text

**Decizie UX:**

- AI suggestions prominent (discovery)

- One-tap swap (speed)

- Instant impact feedback

- Undo available (risk mitigation)

---

## 💡 RECOMANDĂRI STRUCTURALE

### **RECOMANDARE 1: Dashboard Central (Home Tab)**

**Verdict:** ✅ ESENȚIAL

**Rațiune:**

- Aplicația are 4 funcții distincte (planning, recipes, shopping, analysis)

- Utilizatori petrec mult timp în planning

- Home trebuie să fie "central nervous system" al aplicației

- Evită context switching costs

**Implementare:**

```text
Home ar trebui să includă:
├─ Primary: Weekly meal planning view
├─ Secondary: Quick actions (Magic Wand)
├─ Tertiary: Overview stats (Kcal, Nutri, Eco)
└─ Quaternary: Smart suggestions (next meals)

NU trebuie incluse:
├─ Recipe browsing (→ Recipes tab)
├─ Detailed product viewing (→ Analyze tab)
└─ Shopping management (→ Shop tab)

```text

---

### **RECOMANDARE 2: Household Mode (Mandatory)**

**Verdict:** ✅ ESENȚIAL DEL DIN START

**Rațiune:**

- Cerința dată: 2 utilizatori (cuplu)

- Sistem complex fără household = friction mare

- Shopping list must be collaborative

- Future scalability (family mode)

**Implementare:**

```text
HOUSEHOLD STRUCTURE:

┌─ Account (Eduard)
│  ├─ Owned recipes (30)
│  ├─ Household: "Home" (2 members)
│  │  ├─ Eduard (owner) - created meals
│  │  ├─ Partner - can shop, see meals
│  │  └─ Shared shopping list
│  └─ Token: household_access_token
│
└─ Account (Partner)
   ├─ Owned recipes (5)
   ├─ Household: "Home" (2 members)
   │  ├─ Partner - created meals
   │  ├─ Eduard - can shop, see meals
   │  └─ Shared shopping list
   └─ Token: household_access_token

```text

**Top Bar (👥 Avatar):**

```text
┌─────────────────────────────────┐
│ [Eduard] | Switch household     │
├─────────────────────────────────┤
│ 👥 Home (2 members)             │
│    ├─ You (Eduard) - owner      │
│    ├─ Partner                   │
│    └─ [Manage] [Leave]          │
│                                 │
│ 🏘️ Create new household        │
│ 🔗 Join household (code)       │
│                                 │
│ [My Recipes] [Household Recipes]│
└─────────────────────────────────┘

```text

**Impact pe UI:**

- Shopping list: Group by household member

- Meal planning: Show "created by" hint

- Recipes: Separate My vs Shared

- Settings: Household-specific preferences

---

### **RECOMANDARE 3: Focus Mode (Optional, Future)**

**Verdict:** 🟡 POST-MVP (v1.0+)

**Rațiune:**

- Scanning kan be tedious in retail environment

- Batch scanning useful

- But requires separate UX

- MVP launch without it is fine

**Concepte pentru viitorul:**

```text
FOCUS MODES PROPOSED:

1. RETAIL MODE
   - Fullscreen camera (immersive)
   - Auto-disable features
   - Minimal text
   - Voice feedback (optional)
   - Batch scan → Review later

2. NUTRITION TRACKING MODE
   - Quick scan + amount input
   - Real-time macro tracking
   - Daily totals visible
   - Auto-log to meals

3. RECIPE BUILDER MODE
   - Dedicated recipe creation
   - Ingredient scanning
   - Nutrition auto-calc
   - Notes & instructions

```text

**Timeline:** Post-launch optimization

---

## 📐 WIREFRAME-URI TEXTUALE

### **WIREFRAME 1: Home Tab - Weekly Menu**

```text
┌──────────────────────────────────────────────────────────┐
│  < │ Weekly Menu (Feb 24-2 Mar) │ 🔍  ⚙️  👥            │
├──────────────────────────────────────────────────────────┤
│                                                            │
│ ┌─ TODAY (Monday, Feb 24) ───────────────────────────┐  │
│ │                                                     │  │
│ │ 🍳 BREAKFAST                                      │  │
│ │ [img] Scrambled Eggs & Toast              08:00  │  │
│ │ 🥚 2 | 🧈 1 | 🍞 2                               │  │
│ │ Kcal: 320 (24% daily) | Nutri: 78              │  │
│ │ [Swap] [Remove] [+Notes]                        │  │
│ │                                                     │  │
│ │ 🥗 LUNCH                                          │  │
│ │ [img] Caesar Salad avec Poulet         12:00    │  │
│ │ 🥬 | 🍗 | 🧅 | 🏺                              │  │
│ │ Kcal: 450 (34% daily) | Nutri: 82              │  │
│ │ [Swap] [Remove] [+Notes]                        │  │
│ │                                                     │  │
│ │ 🍽️ DINNER                                        │  │
│ │ [img] Grilled Salmon & Roasted Veg  19:00      │  │
│ │ 🐟 | 🥔 | 🥦 | 🧈                              │  │
│ │ Kcal: 550 (42% daily) | Nutri: 88              │  │
│ │ [Swap] [Remove] [+Notes]                        │  │
│ │                                                     │  │
│ │ 🍰 DESSERT                                        │  │
│ │ [img] Dark Chocolate Mousse          20:30      │  │
│ │ 🍫 | 🥛 |                                        │  │
│ │ Kcal: 180 (14% daily) | Nutri: 65              │  │
│ │ [Swap] [Remove] [+Notes]                        │  │
│ │                                                     │  │
│ │ TODAY TOTAL: 1500 Kcal | Avg Nutri: 78.25      │  │
│ └─────────────────────────────────────────────────┘  │
│                                                        │
│ 📊 WEEKLY OVERVIEW                                    │
│ ├─ Avg daily Kcal: 2100 (optimal)                   │
│ ├─ Avg Nutri score: 75 (good)                       │
│ ├─ Avg Eco score: B (good)                          │
│ ├─ Unique recipes: 14                               │
│ └─ Est. shopping cost: €52                          │
│                                                        │
│ ┌───────────────────────────────────────────────┐   │
│ │ WEEK VIEW (swipeable)                         │   │
│ ├───────────────────────────────────────────────┤   │
│ │ MON │ TUE │ WED │ THU │ FRI │ SAT │ SUN      │   │
│ │  ✓  │  ✓  │  ◇  │  ◇  │  ◇  │  ◇  │  ◇    │   │
│ │                                               │   │
│ │ MON (today): 4/4 meals planned                │   │
│ │ TUE: 3/4 meals                                │   │
│ │ WED: 1/4 meals                                │   │
│ │ THU-SUN: 0/4 meals (need generation)         │   │
│ │                                               │   │
│ │ [Tap day to edit view]                      │   │
│ └───────────────────────────────────────────────┘   │
│                                                        │
│ 🌟 AI FEATURES                                       │
│ ┌───────────────────────────────────────────────┐   │
│ │ [🌟 Generate Missing Meals] ← CTA primary     │   │
│ │ Fill Thu-Sun with smart suggestions          │   │
│ │                                               │   │
│ │ [🔄 Randomize Week] [Re-balance Nutrition]   │   │
│ │                                               │   │
│ │ [✓ Lock] [⭐ Save as Template]               │   │
│ └───────────────────────────────────────────────┘   │
│                                                        │
│ 🛒 SHOPPING                                          │
│ ├─ Items needed: 32                                 │
│ ├─ Est. cost: €52                                   │
│ └─ [Generate Shopping List] [Open Shop tab]        │
│                                                        │
│ [⚙️ Settings] [📌 FAQs] [👥 Share menu]           │
│                                                        │
└──────────────────────────────────────────────────────┘

```text

**Spacing Notes:**

- Card padding: 16px

- Section margin: 24px

- Icon-text gap: 8px

---

### **WIREFRAME 2: Analyze Tab - Product Scan Detail**

```text
┌──────────────────────────────────────────────────────┐
│  < │ Coca-Cola 330ml │ [⋮]                         │
├──────────────────────────────────────────────────────┤
│                                                        │
│         ┌──────────────────────────────┐             │
│         │                              │             │
│         │    [PRODUCT IMAGE]           │             │
│         │    (1:1, high res)           │             │
│         │                              │             │
│         │ Coca-Cola                    │             │
│         │ 330ml PET bottle             │             │
│         │ Made in: Netherlands         │             │
│         │ Barcode: 1234567890123       │             │
│         │                              │             │
│         └──────────────────────────────┘             │
│                                                        │
│ ┌──────────────────────────────────────────────────┐ │
│ │ HEALTH SCORES (horizontal scroll)               │ │
│ ├──────────────────────────────────────────────────┤ │
│ │ 💚 Nutri     🌍 Eco       ⚠️ Health Alert       │ │
│ │   Score        Score                           │ │
│ │ ┌────────┐  ┌────────┐  ┌────────────────────┐│ │
│ │ │   35   │  │   C    │  │ ⚠️ High Sugar Cont│ │
│ │ │ POOR   │  │ GOOD   │  │ 39g/100ml          │ │
│ │ │ ◄─────►│  │ ◄─────►│  │ Recommended: <25g │ │
│ │ │ 0  100 │  │ A  D   │  │                     │ │
│ │ └────────┘  └────────┘  └────────────────────┘│ │
│ └──────────────────────────────────────────────────┘ │
│                                                        │
│ QUICK INFO GRID                                     │
│ ┌──────────────────────────────────────────────────┐ │
│ │ Price: €1.20          │ Volume: 330ml            │ │
│ │ Store: Partially seen  │ Servings/pack: 1       │ │
│ │ Manufacturer:          │ Exp date: 15.04.2026   │ │
│ │ The Coca-Cola Company  │                        │ │
│ └──────────────────────────────────────────────────┘ │
│                                                        │
│ NUTRITION FACTS (expandable section)                │
│ ┌──────────────────────────────────────────────────┐ │
│ │ Serving size: 100ml                              │ │
│ │ Servings per container: 3.3                      │ │
│ ├──────────────────────────────────────────────────┤ │
│ │ Per 100ml          Per serving (100ml)           │ │
│ │ Energy: 42 kcal    Energy: 42 kcal              │ │
│ │ Fat: 0g            Fat: 0g                       │ │
│ │ Sat. Fat: 0g       Sat. Fat: 0g                 │ │
│ │ Trans Fat: 0g      Trans Fat: 0g                │ │
│ │ Cholesterol: 0mg   Cholesterol: 0mg            │ │
│ │ Sodium: 10mg       Sodium: 10mg                │ │
│ │ Carbs: 10.6g ⚠️    Carbs: 10.6g ⚠️             │ │
│ │ Sugars: 10.6g ⚠️   Sugars: 10.6g ⚠️            │ │
│ │ +Added sugars: 10g │ +Added sugars: 10g        │ │
│ │ Fiber: 0g          Fiber: 0g                    │ │
│ │ Protein: 0g        Protein: 0g                  │ │
│ │ Vitamin C: 0%      Vitamin C: 0%               │ │
│ │ Calcium: 0%        Calcium: 0%                 │ │
│ │ Iron: 0%           Iron: 0%                    │ │
│ │ Potassium: 0%      Potassium: 0%               │ │
│ └──────────────────────────────────────────────────┘ │
│                                                        │
│ ALLERGENS & ADDITIVES (if applicable)               │
│ ┌──────────────────────────────────────────────────┐ │
│ │ ⚠️ Caramel color (E150a)                         │ │
│ │ ⚠️ Phosphoric acid - citric acid                 │ │
│ │ ⚠️ Natural flavors                               │ │
│ │ ℹ️ Contains caffeine: 32mg per 330ml            │ │
│ │                                                   │ │
│ │ Allergens detected: NONE                         │ │
│ │ Safe for: Vegan ✓ | Keto ✗ | Gluten-free ✓   │ │
│ └──────────────────────────────────────────────────┘ │
│                                                        │
│ 💡 SMART RECOMMENDATIONS                            │
│ ┌──────────────────────────────────────────────────┐ │
│ │ Similar products with better Nutri score:       │ │
│ │                                                   │ │
│ │ [Card] Sprite Zero Sugar                         │ │
│ │        Nutri: 85 | Est. same price              │ │
│ │        Recommendation: Better for kcal tracking  │ │
│ │ [Open] [Compare]                                 │ │
│ │                                                   │ │
│ │ [Card] Fanta Orange Zero                         │ │
│ │        Nutri: 82 | €0.10 more expensive         │ │
│ │        Recommendation: Slightly better alt      │ │
│ │ [Open] [Compare]                                 │ │
│ │                                                   │ │
│ │ [View more alternatives...]                     │ │
│ └──────────────────────────────────────────────────┘ │
│                                                        │
│ ACTION ROW (sticky at bottom)                       │
│ ┌──────────────────────────────────────────────────┐ │
│ │ [🛒 Add to cart]  [⭐ Save favorite]            │ │
│ │ [🔗 Link to meal] [📸 Re-scan]  [... more]     │ │
│ └──────────────────────────────────────────────────┘ │
│                                                        │
└──────────────────────────────────────────────────────┘

```text

**Interaction details:**

- Scores have animated progress bars (0-100 scale)

- Nutrition table is collapsible (default: collapsed)

- Recommendations swipeable (carousel)

- Action row sticky (always visible when scrolling)

---

### **WIREFRAME 3: Recipes Tab - Grid + Filters**

```text
┌──────────────────────────────────────────────────────┐
│  < │ Recipes │ All/⭐/Saved    │ 🔍                 │
├──────────────────────────────────────────────────────┤
│                                                        │
│ [SEGMENTED CONTROL - sticky]                        │
│ ┌─────────────────────────────────────────────────┐ │
│ │ All Recipes   ⭐ Favorites   Saved             │ │
│ └─────────────────────────────────────────────────┘ │
│                                                        │
│ [FILTER SECTION - collapsible]                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 🔽 FILTERS (tap to expand)                     │ │
│ │    All recipes · 12 results                     │ │
│ │                                                  │ │
│ │    [Show filters] > (or < when open)            │ │
│ │                                                  │ │
│ │    When expanded:                               │ │
│ │    ├─ Dietary: [All] [Vegan] [Keto] [G-F]    │ │
│ │    ├─ Time: [Any] [<15min] [15-45] [>45]    │ │
│ │    ├─ Kcal: [0 ────●─── 2000] kcal          │ │
│ │    ├─ Nutri: [All] [80+] [60-80] [<60]      │ │
│ │    └─ [Reset] [Apply filters]                  │ │
│ └─────────────────────────────────────────────────┘ │
│                                                        │
│ [GRID - 2 columns on mobile, 3 on tablet]          │
│ ┌────────────────────────────────────────────────┐  │
│ │                                                 │  │
│ │ ┌──────────────┐ ┌──────────────┐            │  │
│ │ │              │ │              │            │  │
│ │ │  [RECIPE 1]  │ │  [RECIPE 2]  │            │  │
│ │ │              │ │              │            │  │
│ │ │ Kitchen      │ │ Caesar Salad │            │  │
│ │ │ Pasta (img)  │ │ (img)        │            │  │
│ │ │ 🕐 30min     │ │ 🕐 15min     │            │  │
│ │ │ Kcal: 630    │ │ Kcal: 380    │            │  │
│ │ │ Nutri: 72 ⭐ │ │ Nutri: 85 ⭐ │            │  │
│ │ │ [⭐] [+] [...] │ │ [⭐] [+] [...] │            │  │
│ │ └──────────────┘ └──────────────┘            │  │
│ │                                                 │  │
│ │ ┌──────────────┐ ┌──────────────┐            │  │
│ │ │              │ │              │            │  │
│ │ │  [RECIPE 3]  │ │  [RECIPE 4]  │            │  │
│ │ │              │ │              │            │  │
│ │ │ Baked        │ │ Thai Green   │            │  │
│ │ │ Salmon (img) │ │ Curry (img)  │            │  │
│ │ │ 🕐 25min     │ │ 🕐 40min     │            │  │
│ │ │ Kcal: 520    │ │ Kcal: 380    │            │  │
│ │ │ Nutri: 88 ⭐ │ │ Nutri: 75 ⭐ │            │  │
│ │ │ [⭐] [+] [...] │ │ [⭐] [+] [...] │            │  │
│ │ └──────────────┘ └──────────────┘            │  │
│ │                                                 │  │
│ │ [Load more] or infinite scroll                │  │
│ │                                                 │  │
│ └────────────────────────────────────────────────┘  │
│                                                        │
│ BOTTOM CTAs (sticky)                              │
│ ┌────────────────────────────────────────────────┐  │
│ │ [+ Add Recipe] [🌟 Generate] [Browse curated] │  │
│ └────────────────────────────────────────────────┘  │
│                                                        │
└──────────────────────────────────────────────────────┘

```text

**Interaction details:**

- Grid responsive (test breakpoints)

- Filters collapsible (save space)

- Star icon toggles favorite instantly

- Long-press card → context menu

- Swipe right → quick "add to meal"

---

### **WIREFRAME 4: Shopping Tab - Collaborative List**

```text
┌──────────────────────────────────────────────────────┐
│  < │ Shopping List │ Pending/✓    │ 🔍             │
├──────────────────────────────────────────────────────┤
│                                                        │
│ [SEGMENTED CONTROL]                                  │
│ ┌─────────────────────────────────────────────────┐ │
│ │ Pending (7 items)    ✓ Completed (3 items)     │ │
│ └─────────────────────────────────────────────────┘ │
│                                                        │
│ 👤 Eduard (Household owner) - 5 pending items       │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ☐ Carne de pui - 500g                        │ │
│ │    €2.50 | Auchan (verified 3h ago)             │ │
│ │    From: Pork chops meal (Mon dinner)            │ │
│ │                                                   │ │
│ │    [Qty: 1] [Store: Auchan ▼] [...]           │ │
│ │    Long-press for: Edit, Delete, Allergen flag │ │
│ │                                                   │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ ☐ Brânză - 250g                              │ │
│ │    €3.00 | Price varies (Auchan, Lidl)         │ │
│ │    From: Salad (Tue lunch), Pasta (Wed dinner)  │ │
│ │                                                   │ │
│ │    [Qty: 1] [Store: ?] [...]                   │ │
│ │                                                   │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ ☐ Broccoli - 1 head                           │ │
│ │    €1.20 | Fresh section, Auchan               │ │
│ │    From: Salmon with veggies (Mon lunch)        │ │
│ │                                                   │ │
│ │    [Qty: 1] [Store: Auchan] [...]             │ │
│ │                                                   │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ ☐ Olive oil - 750ml                           │ │
│ │    €5.50 | Oils section                         │ │
│ │    From: Multiple meals (cooking)                │ │
│ │                                                   │ │
│ │    [Qty: 1] [Store: ?] [...]                   │ │
│ │                                                   │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ ☐ Lemons - 4 pcs                              │ │
│ │    €0.80 | Fresh section                        │ │
│ │    From: Salmon seasoning + dressings           │ │
│ │                                                   │ │
│ │    [Qty: 4] [Store: Any] [...]                 │ │
│ │                                                   │ │
│ └─────────────────────────────────────────────────┘ │
│                                                        │
│ 👤 Partner - 2 pending items                        │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ☐ Eggs (free range) - 12 pc                    │ │
│ │    €2.80 | Auchan (verified 2h ago)             │ │
│ │    From: Breakfast eggs (Mon-Thu)                │ │
│ │                                                   │ │
│ │    [Qty: 1] [Store: Auchan] [📸 Scanned]      │ │
│ │                                                   │ │
│ ├─────────────────────────────────────────────────┤ │
│ │ ☐ Bread (whole grain) - 2 loaves               │ │
│ │    €1.50 | Bakery section                       │ │
│ │    From: Breakfast toast (daily)                 │ │
│ │                                                   │ │
│ │    [Qty: 2] [Store: ?] [...]                   │ │
│ │                                                   │ │
│ └─────────────────────────────────────────────────┘ │
│                                                        │
│ 📊 SMART SUMMARY                                    │
│ ├─ Total pending items: 7                           │
│ ├─ Est. total cost: €17.30                          │
│ ├─ Stores involved: Auchan (5), Lidl (1), Any (1)  │
│ ├─ Items by member: Eduard (5), Partner (2)        │
│ └─ Meal coverage: 7 days x 4 meals covered         │
│                                                        │
│ ACTIONS (sticky bottom)                            │
│ ┌─────────────────────────────────────────────────┐ │
│ │ [📱 Share with Eduard] [📸 Scan items]         │ │
│ │ [🗑️ Clear completed] [💾 Export/Print]        │ │
│ │ [📍 Auchan] [📍 Lidl] [Navigate to stores]     │ │
│ │ [+Add item manually] [🤖 Smart suggestions]    │ │
│ └─────────────────────────────────────────────────┘ │
│                                                        │
└──────────────────────────────────────────────────────┘

```text

**Interaction details:**

- Checkbox toggle = strikethrough + fade (visual feedback)

- Long-press on item = edit quantity, store, delete

- Store buttons auto-suggest based on location

- Share uses native iOS share sheet

- Scan button → camera mode for batch scanning

---

## 🎨 DESIGN SYSTEM - EXEMPLU COMPLET

### **Color Usage Examples**

```text
NUTRI SCORE MAPPING:
90+ → Primary Green (#00D476)
70-89 → Secondary Green (#4ECB71)
50-69 → Yellow (#FFD93D)
30-49 → Orange (#FFB84D)
<30 → Red (#FF6B6B)

ECO SCORE MAPPING:
A → Green (#00D476)
B → Green lighter (#4ECB71)
C → Yellow (#FFD93D)
D → Orange (#FFB84D)
E → Red (#FF6B6B)

ALERTS:
High sugar → Danger (#FF6B6B)
Low nutrition → Warning (#FFB84D)
Allergen → Danger (#FF6B6B)
Success actions → Secondary (#00D476)

```text

### **Spacing Rules - Kitchen Sink**

```text
COMPONENT SPACING:
Icon (24x24) + Text (14px) gap: 8px
Multiple fields vertical gap: 16px
Section gaps: 24px
Major layout: 32px

CARD SPACING:
External padding: 16px
Internal gaps: 8px (tight), 12px (medium)
Image aspect: 1:1 or 16:9 depending on context

BOTTOM SHEET / MODAL:
Top padding (from safe area): 24px
Horizontal padding: 16px
Bottom padding (with buttons): 24px
Button height: 48px with 8px gap

GRID SPACING (Recipes):
Item gap: 16px
Row gap: 16px
Edge margin: 16px

```text

---

## ✅ CHECKLIST IMPLEMENTARE

### **Faza 0: Architecture (Week 1)**

- [ ] Define household data model

- [ ] Plan database migrations

- [ ] Create design tokens file (colors, spacing, typography)

- [ ] Set up component library structure

### **Faza 1: Core Tab Restructure (Weeks 2-3)**

- [ ] Refactor bottom tab navigation

- [ ] Remove features from top bar (migrate to context menus)

- [ ] Implement new top bar (back, search, household selector)

- [ ] Test navigation flows

### **Faza 2: Home Tab Redesign (Weeks 4-5)**

- [ ] Weekly planning view (SwiftUI Grid)

- [ ] Meal slot cards with quick actions

- [ ] Weekly overview stats

- [ ] Magic wand wizard (3-step)

- [ ] Shopping list generation

### **Faza 3: Recipes Tab Redesign (Weeks 6-7)**

- [ ] Recipe grid layout (2/3 columns)

- [ ] Advanced filtering (dietary, time, kcal, nutri)

- [ ] Favorites segment

- [ ] Save as draft functionality

- [ ] Long-press context menus

### **Faza 4: Analyze Tab Redesign (Weeks 8-9)**

- [ ] Product detail modal redesign

- [ ] Score visualization (animated progress bars)

- [ ] Nutrition table (expandable)

- [ ] Allergen warnings

- [ ] Recommendation engine

### **Faza 5: Shop Tab Redesign (Weeks 10-11)**

- [ ] Household-grouped lists

- [ ] Checkbox + strikethrough UX

- [ ] Smart cost estimation

- [ ] Store integration (hints)

- [ ] Export/share functionality

### **Faza 6: Household System (Weeks 12-13)**

- [ ] Household model & database

- [ ] Invitation/sharing flows

- [ ] Permission system

- [ ] Role-based UI (owner vs member)

- [ ] Real-time sync

### **Faza 7: Polish & Testing (Weeks 14-15)**

- [ ] Responsive design (iPad)

- [ ] Dark mode verification

- [ ] Accessibility (WCAG A)

- [ ] Performance optimization

- [ ] User testing with real household

---

## 🎯 CONCLUZII ȘI DECIZII FINALE

### **What Changes Most:**
1. **Tab restructure:** Nutriție → Analyze, Simplificare top bar
2. **Home becomes planning hub:** Nu just a view, central nervous system
3. **Household built-in:** Nu optional, core from day 1
4. **Shopping collaborative:** Member grouping, shared views
5. **Design system:** Consistent, scalable, dark-first

### **What Stays Same:**

- Core meal planning logic

- Recipe database

- Scanning capabilities

- Undo/redo system

### **Why These Decisions:**

- **Clarity:** Each tab has single, clear purpose

- **Scalability:** Household pattern works for family (future)

- **Commercial potential:** Professional feature set

- **Minimalism:** Remove friction, add clarity

- **Accessibility:** Dark mode + proper contrast + spacing

### **Success Metrics (Post-launch):**

- ✅ <3 taps to accomplish core tasks

- ✅ No feature visible that isn't used within 2 weeks

- ✅ Household setup <2 minutes

- ✅ Planning weekly menu <5 minutes

- ✅ Scanning + analyzing product <30 seconds

---

**Document Status:** ✅ READY FOR IMPLEMENTATION
**Last Updated:** 24.02.2026
**Reviewed by:** Architecture team

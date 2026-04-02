# Design System: Nocturnal Noir Specification

## 1. Overview & Creative North Star
**Creative North Star: The Midnight Ledger**

This design system moves away from the "app-like" interface and toward a high-end, digital-first financial journal. The aesthetic is one of quiet authority, inspired by luxury print media and nocturnal productivity. We achieve this not through complexity, but through **intentional restraint**. 

By leveraging "Nocturnal Noir," we focus on the interplay of deep shadows and soft luminescence. The design breaks the traditional "box-and-line" template by using **asymmetric whitespace** and **tonal layering**. Elements should feel like they are floating in a dark, infinite space or embossed into heavy, dark-milled paper.

---

## 2. Colors & Surface Philosophy
The palette is rooted in deep charcols and rich blacks to reduce eye strain and evoke a sense of premium exclusivity.

### The Palette (Material Design Convention)
*   **Surface (Base):** `#131313` (The primary canvas)
*   **Surface Container Lowest:** `#0e0e0e` (Deepest wells, used for background recessed areas)
*   **Surface Container High:** `#2a2a2a` (Elevated layers, cards, or navigation headers)
*   **Primary (Accent):** `#bcc2ff` (The "Midnight Blue" pop—used sparingly for high-impact CTAs)
*   **On-Surface:** `#e5e2e1` (Off-white; provides high legibility without the "vibration" of pure white)

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to define sections. Traditional dividers create visual noise that breaks the editorial flow. 
*   **The Alternative:** Define boundaries solely through background color shifts. For example, a `surface-container-low` section sitting against a `surface` background. Let the change in value be the boundary.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. 
*   **Level 0:** `surface-container-lowest` (#0e0e0e) for the global background.
*   **Level 1:** `surface` (#131313) for main content areas.
*   **Level 2:** `surface-container-high` (#2a2a2a) for interactive elements like cards.
*   **Level 3:** `surface-bright` (#393939) for hover states or active selections.

### The "Glass & Tone" Rule
For floating menus or modals, use **Glassmorphism**:
*   **Color:** `surface-container` at 70% opacity.
*   **Effect:** `backdrop-filter: blur(20px)`.
*   **Soul:** Use a subtle linear gradient on primary CTAs (from `primary` to `primary-container`) to give a soft, pearlescent sheen rather than a flat neon glow.

---

## 3. Typography
The system relies on a "High-Contrast Scale," where large, elegant serifs meet utilitarian, modern sans-serifs.

*   **Display & Headlines (Newsreader):** Use the `newsreader` serif for all storytelling and high-level data points. It conveys the "Financial Journal" authority. Use `display-lg` (3.5rem) with tighter letter spacing (-0.02em) for hero moments.
*   **UI & Metadata (Work Sans):** Use `workSans` for all functional elements (labels, buttons, inputs). It provides a clean, technical counter-balance to the serif headlines.
*   **Hierarchy Note:** Always lead with a `newsreader` headline. Use `body-md` in `workSans` for supporting text. Never mix the two within a single sentence or functional group.

---

## 4. Elevation & Depth
In a dark mode, traditional drop shadows often feel "dirty." We use **Tonal Layering** to convey height.

*   **The Layering Principle:** To lift a card, move it up one step in the Surface Scale (e.g., from `surface` to `surface-container-high`).
*   **Ambient Shadows:** If a floating element (like a modal) requires a shadow, use a large blur (30px-60px) at a very low opacity (6%). The shadow color should be `surface-container-lowest` (#0e0e0e) to mimic a natural light occlusion.
*   **The Ghost Border Fallback:** If a component requires a border for accessibility, use `outline-variant` at **15% opacity**. It should be felt, not seen.

---

## 5. Components

### Buttons
*   **Primary:** Filled with `primary` (#bcc2ff), text in `on-primary` (#152383). Use `md` (0.375rem) roundedness.
*   **Secondary:** No fill. `ghost-border` (15% opacity `outline`). Newsreader text.
*   **Tertiary:** Text only in `primary`. No container.

### Input Fields
*   **Style:** Background `surface-container-lowest`. No bottom line. Use a `ghost-border` only on focus.
*   **Labeling:** `label-sm` in `on-surface-variant` placed above the field, never inside.

### Cards & Lists
*   **The Divider Ban:** Strictly forbid `<hr>` or border-bottom lines. 
*   **Separation:** Use `spacing-8` (2.75rem) of vertical whitespace to separate list items, or alternate background shades between `surface` and `surface-container-low`.

### Signature Component: The "Editorial Tile"
A combination of a `display-sm` Newsreader headline and a `label-md` Work Sans subtext, set against a `surface-container-high` background with `xl` (0.75rem) roundedness. Used for high-level financial insights.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use extreme whitespace (Spacing 16 or 20) to separate major editorial sections.
*   **Do** use `Newsreader` for large numbers (balances, totals) to make them feel like "data-as-art."
*   **Do** ensure all icons are "Light" or "Thin" weight to match the delicate typography.

### Don't
*   **Don’t** use pure #FFFFFF for text. It causes "halation" (glowing effect) against the dark background. Always use `on-surface` (#e5e2e1).
*   **Don’t** use vibrant green/red for success/error. Use the muted `error` (#ffb4ab) and soft-tinted success colors to maintain the "Noir" mood.
*   **Don’t** use 100% opaque borders. They are the "crutch" of an unrefined layout. Use tonal shifts instead.
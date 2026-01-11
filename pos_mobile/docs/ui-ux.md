# UI/UX Design Overview (pos_mobile)

This document describes **how the app looks and behaves** from a UI/UX and design-system perspective, based on the current implementation.

## Design system

- **Framework**: Flutter
- **UI style**: **Material 3** (`ThemeData(useMaterial3: true)`)
- **Navigation**: adaptive Material navigation (bottom bar on compact, side rail on larger screens)
- **State & data** (UX impact): offline-first + local database, so most flows are designed to work without network connectivity.

## Theme and visual styling

### Brand color (seed)

The app uses a **single brand color** as the source of truth.

- Brand color is loaded from persisted settings (`brandColorValueProvider`) and applied at app startup.
- The ColorScheme is generated using **Material seed color** (`ColorScheme.fromSeed`).
- Both **Light** and **Dark** themes are generated from the same brand seed.

This keeps the app consistent across screens and makes rebranding straightforward.

### Secondary accents (derived)

In addition to the brand seed, the UI uses two **seed-derived accent tones** to keep the app modern and energetic without introducing arbitrary colors:

- **Cyan/teal accent**: used for premium highlights, supportive emphasis, and subtle flair around primary UI.
- **Indigo/purple accent**: used as a secondary highlight to add depth (especially in headers and hero surfaces).

Both accents are **computed from the brand seed** (hue-rotated + tuned for light/dark) and exposed via a ThemeExtension (`AppAccents`).

Important: **semantic meaning still comes from `AppSemanticColors`** (Cash/Success, Credit/Warning, Danger). Accents are decorative and should not replace meaning.

### Light / dark surfaces

The app uses custom-tuned surfaces for a “soft POS” feel:

- Light background: slightly tinted near-white
- Dark background: near-black true dark
- Cards and inputs use `surfaceContainerHigh` for visual grouping

### Semantic (meaning-based) colors

The app defines an `AppSemanticColors` ThemeExtension and uses meaning-based colors throughout:

- **Success**: typically used for Cash flows and positive confirmations
- **Warning**: typically used for Credit/Utang flows and balance-related emphasis
- **Danger**: destructive actions (deactivate, restore, etc.)
- **Info**: informative stats and secondary emphasis
- **Disabled**: consistent disabled states

POS-specific aliases are used:

- `cash` → success
- `credit` → warning
- `error` → danger

This avoids “random” per-screen colors and keeps the UX consistent.

### Gradients (subtle + limited)

Gradients are allowed, but only in specific hero surfaces to keep the UI premium without becoming noisy.

Allowed gradient surfaces:

- **Dashboard header**
- **Checkout total container**
- **Cash & Credit payment buttons**

All gradients are **subtle** and derived from theme tokens (no per-screen custom colors). The app centralizes these in `AppGradients`.

### Shape, elevation, and spacing

The UI uses a consistent “rounded card” look:

- Cards: rounded corners (large radius) and low elevation
- Buttons: rounded corners (medium radius)
- Inputs/dialogs/snackbars: consistent rounding and filled surfaces

This produces a touch-friendly design suited for quick cashier interactions.

## Responsive layout rules

The app adapts by width-based breakpoints:

- **Compact**: < 600dp
- **Medium**: 600–1024dp
- **Expanded**: > 1024dp

Common rules:

- Screen padding increases with size (roughly 16 → 24 → 32dp horizontal)
- Compact layouts are more vertical/stacked
- Medium/Expanded layouts use columns (side-by-side panes) to reduce scrolling and speed up workflows

## Navigation UX

Top-level destinations (tabs):

- Dashboard
- Checkout
- Reports
- Settings

Adaptive navigation behavior:

- **Compact**: bottom `NavigationBar`
- **Medium/Expanded**: side `NavigationRail` (expanded rail on very large widths)

Security behavior:

- Entering **Settings** can be **PIN-protected** (when a PIN is configured).

## Screen patterns (UI conventions)

### Cards as primary containers
Most screens use cards for:

- Summary/stat blocks (Dashboard, Reports)
- Rows that act like items (Products, Customers)
- Highlighted sections (Credit customer selection, low stock warnings)

This creates strong visual grouping without heavy borders.

### Forms
Form screens follow a consistent pattern:

- Inputs are **filled** and use outlined borders
- Validation happens on submit (required fields, numeric constraints)
- Main action is a prominent **FilledButton** at the bottom of the form

Examples of validation UX:

- Price must be > 0
- Stock cannot be negative
- Payment amount cannot exceed customer balance

### Confirmation dialogs for high-impact actions
Actions that change data in irreversible ways typically require confirmation:

- Completing a sale shows a **Review Sale** dialog before final confirmation
- Undo last sale requires confirmation
- Restore backup confirms that local data will be replaced
- Deactivating customers/products prompts a confirmation dialog

### Feedback
The app uses lightweight, fast feedback:

- **Snackbars** for success/failure confirmations (e.g., “Sale completed”, “Backup exported”, “Failed: …”)
- Inline empty states (e.g., “No products yet.”, “Cart is empty. Tap products to add.”)
- Loading indicators for async data sources

## Checkout UX (key workflow)

Checkout is optimized for speed:

- Tap products to add them to the cart
- In-cart controls are single-tap (+ / − / remove)
- Stock rules are enforced immediately (snackbars: “Out of stock”, “Not enough stock”)

Payment type UX:

- Cash and Credit are presented as two large buttons
- Cash is styled with success tone; Credit uses warning tone

Premium polish:

- The Cash/Credit buttons use a subtle gradient background to improve hierarchy while keeping semantic meaning clear.

Credit (Utang) UX:

- Credit shows a highlighted warning container
- Requires selecting a customer via a bottom sheet picker
- Shows “balance before / after” to reduce mistakes
- Requires confirmation in the sale review dialog

## Reports UX

Reports focuses on today’s operations:

- Summary cards for key metrics (revenue, profit, cash/credit split, payments collected)
- Transaction list optimized for scanning
- Expanded layouts show a table-like row format

Safety feature:

- **Undo last sale** is PIN-protected and limited to the most recent sale within a short window (shown to the user in the dialog text).

## Settings UX

Settings is organized into sections:

- **Security**: App PIN
- **Backup**: Export / Restore database backups
- **Data**: Products / Customers

Many actions are PIN-gated when a PIN is configured (unlock prompt is modal and not dismissible without action).

## Branding hooks

- The app supports a configurable **brand color** that drives the entire theme.
- Branding assets live under `assets/branding/` (see [docs/branding/branding.md](branding/branding.md)).

## UX principles (implicit in the implementation)

- **Fast, touch-first** interactions (large controls, minimal typing at checkout)
- **Error prevention** (stock limits, credit requires customer, overpayment blocked)
- **High confidence actions** (review/confirm for sales, confirmations for destructive actions)
- **Offline-first reliability** (no network dependency for core workflows)

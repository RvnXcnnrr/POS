# MVP Specification (pos_mobile)

This document describes the current MVP scope of the **pos_mobile** Flutter POS app, based on the implemented routes, screens, and local database schema.

## 1) Product goal

A simple, offline-first mobile POS for a small store that can:

- Sell products as **Cash** transactions.
- Sell products as **Credit (Utang)** transactions tied to a customer.
- Track product **stock** and prevent overselling.
- Track customer **outstanding balances** and allow recording **payments**.
- Show **today’s** sales totals and transaction list.

## 2) Target users

- **Store owner / cashier** using a single Android device.

## 3) Navigation map (routes)

Bottom navigation (top-level):

- `/dashboard`
- `/checkout` (initial route)
- `/reports`
- `/settings`

Settings sub-routes:

- Products
  - `/settings/products`
  - `/settings/products/new`
  - `/settings/products/:id/edit`
- Customers (Utang)
  - `/settings/customers`
  - `/settings/customers/new`
  - `/settings/customers/:id`
  - `/settings/customers/:id/edit`
  - `/settings/customers/:id/payment`

## 4) Core entities (local SQLite)

The app persists all data locally in SQLite (`pos.db`).

### Products

Table: `products`

- `id` (int)
- `name` (text, required)
- `price_cents` (int, required)
- `stock` (int, required)
- `image_path` (text, optional)
- `created_at` (ms epoch)

### Customers (Utang)

Table: `customers`

- `id` (int)
- `name` (text, required)
- `phone` (text, optional)
- `balance_cents` (int, required)
- `created_at` (ms epoch)

### Sales

Table: `sales`

- `id`
- `total_amount_cents`
- `payment_type` (enum-like string: `cash` | `credit`)
- `customer_id` (nullable; required for credit sales)
- `created_at` (ms epoch)

### Sale items

Table: `sale_items`

- `sale_id`
- `product_id`
- `quantity`
- `price_cents` (unit price snapshot at sale time)

### Payments

Table: `payments`

- `customer_id`
- `amount_cents`
- `created_at` (ms epoch)

### App settings

Table: `app_settings`

- `store_name` (required)
- `pin_code` (optional)

Note: this table exists in schema but is not currently exposed in the UI routes.

## 5) MVP screens & behaviors

### Checkout

Goal: build a cart and complete a sale.

Behavior:

- If there are no products, shows a message: add products in Settings → Products.
- Shows **TOTAL** and a **payment type switch**: Cash vs Credit (Utang).
- Product grid:
  - Tapping a product adds it to cart.
  - Prevents adding items if product stock is 0 ("Out of stock").
  - Prevents cart quantity from exceeding stock ("Not enough stock").
- Cart section:
  - Shows lines and supports increment/decrement/removal (in `CartNotifier`).

Completing a sale:

- Cash sale: allowed with cart total > 0.
- Credit sale:
  - Requires selecting a customer.
  - Shows a confirmation dialog including current balance and balance after sale.
- On completion, the app:
  - Writes `sales` + `sale_items`.
  - Deducts `products.stock`.
  - If credit: increases `customers.balance_cents` by sale total.
  - Clears the cart and refreshes Products/Customers/Reports/Dashboard state.

### Products (Settings → Products)

Goal: CRUD products used by checkout.

- List products sorted by name.
- Each product shows name, price, stock, and optional image.
- Add product:
  - Fields: name (required), price (required, > 0), stock (>= 0), image optional.
  - Image can be picked from Camera or Gallery and is copied into app documents storage.
- Edit product: same fields.
- Delete product:
  - Only allowed if the product has **never appeared in `sale_items`**.
  - If present in past sales, deletion is blocked.

### Customers (Settings → Customers)

Goal: manage credit customers and their balances.

- List customers sorted by highest balance, then name.
- Customer shows name, phone (optional), and balance.
- Add/Edit customer:
  - Fields: name (required), phone (optional).

Customer details:

- Shows customer name, phone, outstanding balance.
- Add payment button enabled only if balance > 0.
- Payment history list from `payments` table.

Add payment:

- Enter payment amount (must be > 0).
- Cannot pay more than current balance.
- Requires confirmation dialog.
- On success:
  - Inserts a row in `payments`.
  - Decrements `customers.balance_cents`.
  - Never allows balance to go below 0.

### Dashboard

Goal: quick overview.

- Today sales total.
- Today transaction count.
- Outstanding credit total (sum of all customer balances).
- Low stock alerts:
  - Threshold is `<= 5` stock.

### Reports

Goal: review today’s totals and transaction list.

- Today summary:
  - Total sales
  - Cash sales
  - Credit sales
  - Transactions count
  - Payments collected (sum of payments today)
  - Outstanding credit total
- Transaction list:
  - Shows amount, timestamp, payment type, and customer name for credit sales.

## 6) Key rules (MVP invariants)

- Stock cannot be oversold; sale completion validates stock inside a DB transaction.
- Credit sales require a customer and increase that customer’s balance.
- Payments reduce balance; overpayment is blocked; balance never goes negative.
- Past sales are immutable (no edit flow).
- Products cannot be deleted if they exist in past sales.
- Reports/Dashboard are computed for the local device’s current day.

## 7) MVP acceptance criteria

The MVP is considered “done” when all of the following work end-to-end on a fresh install:

- Can create at least one product and see it in Checkout.
- Can complete a Cash sale and see:
  - stock deducted,
  - a transaction in Reports,
  - today totals updated in Dashboard/Reports.
- Can create a customer and complete a Credit sale for them and see:
  - customer balance increased,
  - outstanding credit updated in Dashboard/Reports.
- Can add a payment for a customer and see:
  - balance decreased,
  - payment recorded in history,
  - payments collected reflected in Reports (today).
- Data persists across app restarts (SQLite local persistence).

## 8) Explicitly out of scope (not in MVP)

These are not present in the current routes/features and should be treated as future work:

- Multi-device sync / cloud backend
- User accounts, roles, or multi-cashier support
- Barcode scanning
- Receipt printing
- Discounts, promos, tax/VAT logic
- Returns/refunds/exchanges
- Product categories/variants
- Detailed historical reports beyond “today”
- Export to CSV/PDF

## 9) “Ask GPT” prompt template (copy/paste)

Paste the following into GPT along with this file content:

"""
You are helping improve an offline-first Flutter POS MVP.

MVP scope summary:
- Checkout: cash + credit (utang) sales; stock validation; credit requires customer and increases balance.
- Products: CRUD, optional image, stock count; cannot delete if used in past sales.
- Customers: CRUD; balances; payment recording with overpayment prevented.
- Dashboard/Reports: today totals, outstanding credit, low-stock alerts.
- Local SQLite only.

Task:
1) Identify the biggest UX/product gaps for a small store.
2) Propose a prioritized improvement plan in phases (P0/P1/P2).
3) For each item: why it matters, expected impact, and implementation notes (Flutter + Riverpod + sqflite).
4) Call out any risky edge cases in the current rules (stock, credit, payments).

Constraints:
- Keep the core flows simple.
- Prefer changes that don’t require a backend.
"""

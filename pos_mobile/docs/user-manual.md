# User Manual (pos_mobile)

This app is an **offline-first** POS (point-of-sale) for a small store. It runs on phones and tablets and stores all data locally on the device.

## Navigation

The main tabs are:

- **Dashboard**: today’s overview + low stock alerts
- **Checkout**: make sales (Cash or Credit/Utang)
- **Reports**: today’s totals + transaction list (and “Undo last sale”)
- **Settings**: security (PIN), backup/restore, products, customers

On small screens you’ll see a bottom navigation bar. On tablets/large screens it becomes a side navigation rail.

## First-time setup (recommended)

1) **Set an App PIN (optional but recommended)**
- Go to **Settings → App PIN**
- If you want a PIN: enter a **New PIN** (at least **4 digits**) and confirm
- To remove a PIN later: set “New PIN” to **empty** and save

2) **Add products**
- Go to **Settings → Products**
- Tap **+** (Add)
- Fill in:
  - **Product name** (required)
  - **Price** (required, must be > 0)
  - **Cost price** (optional, can be 0)
  - **Stock** (0 or more)
  - **Image** (optional) via **Camera** or **Gallery**
- Tap **Add Product**

If there are no products yet, Checkout will show: “Add products in Settings → Products.”

## Checkout (making a sale)

### Add items to the cart
1) Go to **Checkout**
2) Under **Products**, tap a product to add it to the cart
- If stock is 0, the app shows **“Out of stock”**
- If you try to exceed available stock, the app shows **“Not enough stock”**

### Adjust quantities / remove items
In the **Cart** section:
- Tap **Decrease** (minus) to reduce quantity
- Tap **Increase** (plus) to add quantity (up to available stock)
- Tap **Remove** (trash) to remove the product from the cart

### Choose payment type
In Checkout, choose one:
- **Cash**
- **Credit (Utang)**

### Complete a Cash sale
1) Select **Cash**
2) Tap **COMPLETE SALE (CASH)**
3) Review the sale details in **Review Sale**
4) Tap **Confirm Sale**

After a successful sale you’ll see **“Sale completed”**.

### Complete a Credit (Utang) sale
Credit sales require selecting a customer.

1) Select **Credit (Utang)**
2) In the credit section, tap **Select**
- If there are no customers yet, choose **Add customer** to create one
3) Tap **COMPLETE SALE (CREDIT)**
4) In **Review Sale**, confirm the customer and balance change
5) Tap **Confirm Sale**

What happens:
- Product stock is reduced
- The customer’s outstanding balance increases by the sale total

## Customers (Utang)

### Add a customer
1) Go to **Settings → Customers (Utang)**
2) Tap the **Add** button
3) Enter:
- **Customer name** (required)
- **Phone (optional)**
4) Tap **Add Customer**

### View customer details
- Go to **Settings → Customers (Utang)** and tap a customer

The **Customer** screen shows:
- Name and phone
- **Outstanding balance**
- **Payment history**

### Record a payment
1) Open a customer
2) Tap **Add Payment** (enabled only if balance > 0)
3) Enter:
- **Payment amount** (must be > 0 and cannot be more than the current balance)
- **Method**: Cash / GCash / Maya / Other
- **Note (optional)**
4) Tap **CONFIRM PAYMENT** and confirm

### Edit or deactivate a customer
- In customer details:
  - Tap **Edit** to change name/phone
  - Open the menu and select **Deactivate customer**

Deactivated customers are hidden from lists and credit selection, but **past sales/payments remain**.

## Products

### View products
- Go to **Settings → Products**

Each product shows:
- Name
- Price
- Stock
- Optional image

### Edit a product
- Go to **Settings → Products**
- Tap the **Edit** icon

### Deactivate a product
- Go to **Settings → Products**
- Tap **Deactivate** (trash icon)
- If a PIN is configured, you must unlock first

Deactivated products are hidden from Checkout and lists.

## Dashboard

Go to **Dashboard** for a quick overview, including:

- **Today sales**
- **Today profit**
- **Transactions**
- **Outstanding credit**
- **Inventory value** and **Total assets (est.)**
- **Low stock alerts** (items with low remaining stock)

Use the **Refresh** button in the top bar to reload.

## Reports

Go to **Reports** to see today’s summary and transactions.

### Today summary
Includes:
- Total revenue
- COGS
- Gross profit
- Cash vs Credit totals
- Transactions count
- Payments collected
- Outstanding credit total

### Transactions list
Shows each transaction (with its ID) and whether it was Cash or Credit.

### Undo last sale (PIN-protected)
In **Reports**, tap **Undo last sale** (undo icon).

Notes:
- Requires the App PIN (if configured)
- Can only undo the **most recent sale**
- Only available within **5 minutes** of that sale

## Backup & restore (PIN-protected)

### Export backup
1) Go to **Settings → Export backup**
2) Choose where to save the `.db` file

### Restore backup
1) Go to **Settings → Restore backup**
2) Select a `.db` file
3) Confirm the warning (this replaces all local data)

After restoring, the app reloads Products, Customers, Dashboard, and Reports.

## Common messages and what they mean

- **“Add products in Settings → Products.”**: no products exist yet
- **“Out of stock”**: stock is 0 for that product
- **“Not enough stock”**: you tried to exceed available stock
- **“Select a customer for credit sale.”**: Credit (Utang) requires choosing a customer

## Important notes

- This app is **offline-first**: all sales/customers/products are stored on the device.
- To move data between devices, use **Settings → Export backup** and restore it on the other device.

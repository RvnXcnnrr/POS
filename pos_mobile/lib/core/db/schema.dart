class Schema {
  static const int currentVersion = 5;

  /// Latest schema used for fresh installs.
  static const createStatements = <String>[
    // Products
    '''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price_cents INTEGER NOT NULL,
  stock INTEGER NOT NULL,
  image_path TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL
);
''',

    // Customers (Utang)
    '''
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  balance_cents INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL
);
''',

    // Sales
    '''
CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  total_amount_cents INTEGER NOT NULL,
  payment_type TEXT NOT NULL CHECK(payment_type IN ('cash','credit')),
  customer_id INTEGER,
  business_date TEXT NOT NULL,
  is_voided INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
);
''',

    // Sale items (snapshot unit price)
    '''
CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price_cents INTEGER NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);
''',

    // Payments (IMPORTANT)
    '''
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  amount_cents INTEGER NOT NULL,
  method TEXT NOT NULL DEFAULT 'cash' CHECK(method IN ('cash','gcash','maya','other')),
  note TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
);
''',

    // App settings (single row)
    '''
CREATE TABLE app_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  store_name TEXT NOT NULL,
  pin_code TEXT,
  brand_color INTEGER
);
''',

    // Performance indexes
    'CREATE INDEX idx_sales_created_at ON sales(created_at);',
    'CREATE INDEX idx_sales_business_date ON sales(business_date);',
    'CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);',
    'CREATE INDEX idx_payments_created_at ON payments(created_at);',
    'CREATE INDEX idx_customers_balance ON customers(balance_cents);',
  ];

  // Intentionally no seed data (except app_settings row is inserted in AppDatabase).
}

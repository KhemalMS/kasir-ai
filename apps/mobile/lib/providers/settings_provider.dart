import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _language = 'Indonesia';
  String _theme = 'Gelap';

  // ── Info Toko (dari API) ──
  String storeName = 'Kasir-AI';
  String storeAddress = '';
  String storePhone = '';

  // ── Pengaturan Printer ──
  String printerName = '';
  String printerAddress = ''; // MAC address BT printer
  String paperSize = '80mm';
  bool autoPrint = false;
  bool autoCashDrawer = false;

  // ── Kustomisasi Struk Pembeli ──
  bool showLogo = false;
  String logoPath = '';
  String headerText = 'KASIR-AI POS';
  String footerText = 'Terima kasih atas kunjungan Anda!';
  bool showReceiptNo = true;
  bool showOrderNo = true;
  bool showTableNo = true;
  bool showUser = true;
  bool showItemCount = true;
  bool showTotal = true;
  bool showTax = true;
  bool showChange = true;
  String fontFamily = 'Monospace';
  String fontSize = '12';
  String marginTop = '2';
  String marginBottom = '2';
  String marginLeft = '2';
  String marginRight = '2';

  // ── Pengaturan Struk Dapur ──
  bool kitchenShowTable = true;
  bool kitchenShowTime = true;
  bool kitchenShowNotes = true;
  String kitchenFontSize = '16';

  String get language => _language;
  String get theme => _theme;
  bool get isDark => _theme == 'Gelap';

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('app_language') ?? 'Indonesia';
    _theme = prefs.getString('app_theme') ?? 'Gelap';

    // Printer
    printerName = prefs.getString('printer_name') ?? '';
    printerAddress = prefs.getString('printer_address') ?? '';
    paperSize = prefs.getString('paper_size') ?? '80mm';
    autoPrint = prefs.getBool('auto_print') ?? false;
    autoCashDrawer = prefs.getBool('auto_cash_drawer') ?? false;

    // Kustomisasi struk pembeli
    showLogo = prefs.getBool('show_logo') ?? false;
    logoPath = prefs.getString('logo_path') ?? '';
    headerText = prefs.getString('header_text') ?? 'KASIR-AI POS';
    footerText = prefs.getString('footer_text') ?? 'Terima kasih atas kunjungan Anda!';
    showReceiptNo = prefs.getBool('show_receipt_no') ?? true;
    showOrderNo = prefs.getBool('show_order_no') ?? true;
    showTableNo = prefs.getBool('show_table_no') ?? true;
    showUser = prefs.getBool('show_user') ?? true;
    showItemCount = prefs.getBool('show_item_count') ?? true;
    showTotal = prefs.getBool('show_total') ?? true;
    showTax = prefs.getBool('show_tax') ?? true;
    showChange = prefs.getBool('show_change') ?? true;
    fontFamily = prefs.getString('font_family') ?? 'Monospace';
    fontSize = prefs.getString('font_size') ?? '12';
    marginTop = prefs.getString('margin_top') ?? '2';
    marginBottom = prefs.getString('margin_bottom') ?? '2';
    marginLeft = prefs.getString('margin_left') ?? '2';
    marginRight = prefs.getString('margin_right') ?? '2';

    // Struk dapur
    kitchenShowTable = prefs.getBool('kitchen_show_table') ?? true;
    kitchenShowTime = prefs.getBool('kitchen_show_time') ?? true;
    kitchenShowNotes = prefs.getBool('kitchen_show_notes') ?? true;
    kitchenFontSize = prefs.getString('kitchen_font_size') ?? '16';

    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    notifyListeners();
  }

  Future<void> setTheme(String themeVal) async {
    _theme = themeVal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', themeVal);
    notifyListeners();
  }

  /// Simpan SEMUA pengaturan printer ke SharedPreferences
  Future<void> savePrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_name', printerName);
    await prefs.setString('printer_address', printerAddress);
    await prefs.setString('paper_size', paperSize);
    await prefs.setBool('auto_print', autoPrint);
    await prefs.setBool('auto_cash_drawer', autoCashDrawer);
    await prefs.setBool('show_logo', showLogo);
    await prefs.setString('logo_path', logoPath);
    await prefs.setString('header_text', headerText);
    await prefs.setString('footer_text', footerText);
    await prefs.setBool('show_receipt_no', showReceiptNo);
    await prefs.setBool('show_order_no', showOrderNo);
    await prefs.setBool('show_table_no', showTableNo);
    await prefs.setBool('show_user', showUser);
    await prefs.setBool('show_item_count', showItemCount);
    await prefs.setBool('show_total', showTotal);
    await prefs.setBool('show_tax', showTax);
    await prefs.setBool('show_change', showChange);
    await prefs.setString('font_family', fontFamily);
    await prefs.setString('font_size', fontSize);
    await prefs.setString('margin_top', marginTop);
    await prefs.setString('margin_bottom', marginBottom);
    await prefs.setString('margin_left', marginLeft);
    await prefs.setString('margin_right', marginRight);
    await prefs.setBool('kitchen_show_table', kitchenShowTable);
    await prefs.setBool('kitchen_show_time', kitchenShowTime);
    await prefs.setBool('kitchen_show_notes', kitchenShowNotes);
    await prefs.setString('kitchen_font_size', kitchenFontSize);
    notifyListeners();
  }

  /// Update info toko dari API (dipanggil saat app start)
  void updateStoreInfo(Map<String, dynamic> data) {
    storeName = data['store_name'] ?? storeName;
    storeAddress = data['store_address'] ?? storeAddress;
    storePhone = data['store_phone'] ?? storePhone;
    notifyListeners();
  }

  // ─── Localization ───────────────────
  String t(String key) {
    return (_language == 'English' ? _en[key] : _id[key]) ?? key;
  }

  static const Map<String, String> _id = {
    // Nav
    'dashboard': 'Dashboard',
    'products': 'Produk',
    'staff': 'Staff',
    'reports': 'Laporan',
    'settings': 'Pengaturan',

    // Dashboard
    'summary_today': 'Ringkasan hari ini',
    'total_revenue': 'Total Pendapatan',
    'transactions': 'Transaksi',
    'hourly_revenue': 'Pendapatan Per Jam (Hari Ini)',
    'no_data': 'Belum ada data',
    'weekly_revenue': 'Pendapatan 7 Hari Terakhir',
    'monthly_revenue': 'Pendapatan Bulanan',
    'top_products': 'Top 5 Produk Terlaris',

    // Settings
    'general': 'Umum',
    'product': 'Produk',
    'print': 'Print',
    'database': 'Database',
    'language': 'Bahasa',
    'select_language': 'Pilih bahasa',
    'color_theme': 'Tema Warna',
    'display_theme': 'Tema tampilan',
    'dark': 'Gelap',
    'light': 'Terang',
    'appearance_settings': 'Pengaturan tampilan dan bahasa',
    'tax_settings': 'Pengaturan perpajakan produk',
    'tax_list': 'Daftar Pajak',
    'add_tax': 'Tambah Pajak',
    'edit_tax': 'Edit Pajak',
    'tax_name': 'Nama Pajak',
    'percentage': 'Persentase (%)',
    'active': 'Aktif',
    'inactive': 'Nonaktif',
    'save': 'Simpan',
    'no_tax': 'Belum ada pajak',
    'printer_settings': 'Pengaturan Printer',
    'printer_name': 'Nama Printer',
    'paper_size': 'Ukuran Kertas',
    'auto_print': 'Auto Print Setelah Checkout',
    'receipt_customization': 'Kustomisasi Struk',
    'receipt_header': 'Header Struk',
    'receipt_footer': 'Footer Struk',
    'show_logo': 'Tampilkan Logo',
    'printer_receipt_settings': 'Pengaturan printer dan kustomisasi struk',
    'auto_cash_drawer': 'Buka Cash Drawer Otomatis',
    'business_logo': 'Logo Usaha',
    'upload_logo': 'Upload Logo',
    'receipt_fields': 'Field Struk',
    'receipt_no': 'Nomor Struk',
    'order_no': 'Nomor Order',
    'table_no': 'Nomor Meja',
    'cashier_user': 'Pengguna / Kasir',
    'item_count': 'Jumlah Item',
    'total_amount': 'Total',
    'tax_info': 'Pajak',
    'change_amount': 'Kembalian',
    'font_layout': 'Font & Tata Letak',
    'font_type': 'Jenis Font',
    'font_size_label': 'Ukuran Font',
    'margins': 'Margins',
    'margin_top': 'Margin Atas (mm)',
    'margin_bottom': 'Margin Bawah (mm)',
    'margin_left': 'Margin Kiri (mm)',
    'margin_right': 'Margin Kanan (mm)',
    'print_test_page': 'Print Halaman Test',
    'backup_database': 'Backup Database',
    'restore_database': 'Restore Database',
    'backup_desc': 'Buat salinan cadangan database untuk keamanan data. File backup akan diunduh ke perangkat Anda.',
    'restore_desc': 'Mengembalikan database dari file backup. Data saat ini akan ditimpa oleh data backup.',
    'download_backup': 'Download Backup',
    'upload_backup': 'Upload Backup File',
    'backup_started': 'Memulai backup database...',
    'restore_coming': 'Fitur restore akan segera tersedia',
    'manage_backup': 'Kelola backup dan restore database',

    // Reports
    'daily_sales': 'Penjualan Harian',
    'hourly_sales': 'Penjualan Per Jam',
    'hourly_product_sales': 'Penjualan Per Jam/Produk',
    'shift_report': 'Laporan Shift',
    'expenses': 'Pengeluaran',
    'profit_loss': 'Laba / Rugi',
    'raw_material': 'Stok Bahan Baku',
    'export_csv': 'Export CSV',
    'export_pdf': 'Export PDF',
    'show': 'Tampilkan',
    'date': 'Tanggal',
    'hour': 'Jam',
    'qty': 'Qty',
    'revenue': 'Pendapatan',
    'cashier': 'Kasir',
    'starting_cash': 'Uang Awal',
    'ending_cash': 'Uang Akhir',
    'difference': 'Selisih',
    'status': 'Status',
    'category': 'Kategori',
    'amount': 'Jumlah',
    'description': 'Deskripsi',
    'name': 'Nama',
    'stock': 'Stok',
    'unit': 'Unit',
    'threshold': 'Threshold',
    'critical': 'Kritis',
    'safe': 'Aman',
    'total_revenue_label': 'Total Pendapatan',
    'total_expenses_label': 'Total Pengeluaran',
    'net_profit': 'LABA BERSIH',
    'net_loss': 'RUGI BERSIH',
    'period': 'Periode',
    'total_rows': 'Total',
    'rows': 'baris',
    'no_sales_data': 'Tidak ada data penjualan',
    'no_data_available': 'Tidak ada data',
    'no_shift_data': 'Tidak ada data shift',
    'no_expense': 'Tidak ada pengeluaran',
    'no_stock_data': 'Tidak ada data stok',

    // Raw Materials
    'raw_materials': 'Bahan Baku',
    'Daftar Bahan': 'Daftar Bahan',
    'Racikan': 'Racikan',
    'Penyesuaian Stok': 'Penyesuaian Stok',
    'Peringatan': 'Peringatan',
    'manage_raw_desc': 'Kelola daftar bahan baku dan stok',
    'recipe_desc': 'Atur racikan bahan baku per produk',
    'adjust_desc': 'Penyesuaian stok manual dan riwayat',
    'alert_desc': 'Bahan baku yang stoknya menipis',
    'add_item': 'Tambah Bahan',
    'edit_item': 'Edit Bahan',
    'add_recipe': 'Tambah Racikan',
    'edit_recipe': 'Edit Racikan',
    'adjust_stock': 'Sesuaikan Stok',
    'select_item': 'Pilih bahan baku',
    'select_product': 'Pilih produk',
    'ingredient': 'Bahan',
    'ingredients': 'bahan',
    'add_ingredient': 'Tambah Bahan',
    'no_recipe': 'Belum ada racikan',
    'all_stock_safe': 'Semua stok bahan baku aman',
    'type': 'Tipe',
    'reason': 'Alasan',
    'cancel': 'Batal',

    // Products
    'add_product': 'Tambah Produk',
    'edit_product': 'Edit Produk',
    'product_name': 'Nama Produk',
    'price': 'Harga',
    'upload_product_image': 'Klik untuk upload foto produk',
    'search_product': 'Cari produk...',

    // Kitchen Ticket
    'customer_receipt': 'Struk Pembeli',
    'kitchen_ticket': 'Struk Dapur',
    'kitchen_ticket_info': 'Struk dapur hanya menampilkan item pesanan tanpa harga. Dirancang agar mudah dibaca oleh staf dapur.',
    'kitchen_display': 'Tampilan Dapur',
    'show_table_number': 'Tampilkan Nomor Meja',
    'show_order_time': 'Tampilkan Waktu Pesanan',
    'show_special_notes': 'Tampilkan Catatan Khusus',
    'show_order_status': 'Tampilkan Status Pesanan',
    'kitchen_font': 'Ukuran Font Dapur',
    'kitchen_font_hint': 'Gunakan font lebih besar agar mudah dibaca di dapur',
    'kitchen_preview': 'Preview & Test Print',
    'print_kitchen_test': 'Cetak Test Struk Dapur',

    // Misc
    'logout': 'Logout',
    'loading': 'Memuat...',
  };

  static const Map<String, String> _en = {
    // Nav
    'dashboard': 'Dashboard',
    'products': 'Products',
    'staff': 'Staff',
    'reports': 'Reports',
    'settings': 'Settings',

    // Dashboard
    'summary_today': 'Today\'s summary',
    'total_revenue': 'Total Revenue',
    'transactions': 'Transactions',
    'hourly_revenue': 'Hourly Revenue (Today)',
    'no_data': 'No data yet',
    'weekly_revenue': 'Last 7 Days Revenue',
    'monthly_revenue': 'Monthly Revenue',
    'top_products': 'Top 5 Best Sellers',

    // Settings
    'general': 'General',
    'product': 'Product',
    'print': 'Print',
    'database': 'Database',
    'language': 'Language',
    'select_language': 'Select language',
    'color_theme': 'Color Theme',
    'display_theme': 'Display theme',
    'dark': 'Dark',
    'light': 'Light',
    'appearance_settings': 'Display and language settings',
    'tax_settings': 'Product tax settings',
    'tax_list': 'Tax List',
    'add_tax': 'Add Tax',
    'edit_tax': 'Edit Tax',
    'tax_name': 'Tax Name',
    'percentage': 'Percentage (%)',
    'active': 'Active',
    'inactive': 'Inactive',
    'save': 'Save',
    'no_tax': 'No taxes yet',
    'printer_settings': 'Printer Settings',
    'printer_name': 'Printer Name',
    'paper_size': 'Paper Size',
    'auto_print': 'Auto Print After Checkout',
    'receipt_customization': 'Receipt Customization',
    'receipt_header': 'Receipt Header',
    'receipt_footer': 'Receipt Footer',
    'show_logo': 'Show Logo',
    'printer_receipt_settings': 'Printer and receipt customization settings',
    'auto_cash_drawer': 'Auto Open Cash Drawer',
    'business_logo': 'Business Logo',
    'upload_logo': 'Upload Logo',
    'receipt_fields': 'Receipt Fields',
    'receipt_no': 'Receipt Number',
    'order_no': 'Order Number',
    'table_no': 'Table Number',
    'cashier_user': 'User / Cashier',
    'item_count': 'Item Count',
    'total_amount': 'Total',
    'tax_info': 'Tax',
    'change_amount': 'Change',
    'font_layout': 'Font & Layout',
    'font_type': 'Font Type',
    'font_size_label': 'Font Size',
    'margins': 'Margins',
    'margin_top': 'Top Margin (mm)',
    'margin_bottom': 'Bottom Margin (mm)',
    'margin_left': 'Left Margin (mm)',
    'margin_right': 'Right Margin (mm)',
    'print_test_page': 'Print Test Page',
    'backup_database': 'Backup Database',
    'restore_database': 'Restore Database',
    'backup_desc': 'Create a backup copy of the database for data safety. The backup file will be downloaded to your device.',
    'restore_desc': 'Restore database from a backup file. Current data will be overwritten by backup data.',
    'download_backup': 'Download Backup',
    'upload_backup': 'Upload Backup File',
    'backup_started': 'Starting database backup...',
    'restore_coming': 'Restore feature coming soon',
    'manage_backup': 'Manage database backup and restore',

    // Reports
    'daily_sales': 'Daily Sales',
    'hourly_sales': 'Hourly Sales',
    'hourly_product_sales': 'Hourly Sales/Product',
    'shift_report': 'Shift Report',
    'expenses': 'Expenses',
    'profit_loss': 'Profit / Loss',
    'raw_material': 'Raw Material Stock',
    'export_csv': 'Export CSV',
    'export_pdf': 'Export PDF',
    'show': 'Show',
    'date': 'Date',
    'hour': 'Hour',
    'qty': 'Qty',
    'revenue': 'Revenue',
    'cashier': 'Cashier',
    'starting_cash': 'Starting Cash',
    'ending_cash': 'Ending Cash',
    'difference': 'Difference',
    'status': 'Status',
    'category': 'Category',
    'amount': 'Amount',
    'description': 'Description',
    'name': 'Name',
    'stock': 'Stock',
    'unit': 'Unit',
    'threshold': 'Threshold',
    'critical': 'Critical',
    'safe': 'Safe',
    'total_revenue_label': 'Total Revenue',
    'total_expenses_label': 'Total Expenses',
    'net_profit': 'NET PROFIT',
    'net_loss': 'NET LOSS',
    'period': 'Period',
    'total_rows': 'Total',
    'rows': 'rows',
    'no_sales_data': 'No sales data',
    'no_data_available': 'No data available',
    'no_shift_data': 'No shift data',
    'no_expense': 'No expenses',
    'no_stock_data': 'No stock data',

    // Raw Materials
    'raw_materials': 'Raw Materials',
    'Daftar Bahan': 'Inventory List',
    'Racikan': 'Recipes',
    'Penyesuaian Stok': 'Stock Adjustment',
    'Peringatan': 'Alerts',
    'manage_raw_desc': 'Manage raw materials and stock inventory',
    'recipe_desc': 'Set up ingredient recipes per product',
    'adjust_desc': 'Manual stock adjustment and history',
    'alert_desc': 'Raw materials running low on stock',
    'add_item': 'Add Item',
    'edit_item': 'Edit Item',
    'add_recipe': 'Add Recipe',
    'edit_recipe': 'Edit Recipe',
    'adjust_stock': 'Adjust Stock',
    'select_item': 'Select raw material',
    'select_product': 'Select product',
    'ingredient': 'Ingredient',
    'ingredients': 'ingredients',
    'add_ingredient': 'Add Ingredient',
    'no_recipe': 'No recipes yet',
    'all_stock_safe': 'All raw material stock is safe',
    'type': 'Type',
    'reason': 'Reason',
    'cancel': 'Cancel',

    // Products
    'add_product': 'Add Product',
    'edit_product': 'Edit Product',
    'product_name': 'Product Name',
    'price': 'Price',
    'upload_product_image': 'Click to upload product image',
    'search_product': 'Search product...',

    // Kitchen Ticket
    'customer_receipt': 'Customer Receipt',
    'kitchen_ticket': 'Kitchen Ticket',
    'kitchen_ticket_info': 'Kitchen ticket only shows order items without prices. Designed to be easy to read by kitchen staff.',
    'kitchen_display': 'Kitchen Display',
    'show_table_number': 'Show Table Number',
    'show_order_time': 'Show Order Time',
    'show_special_notes': 'Show Special Notes',
    'show_order_status': 'Show Order Status',
    'kitchen_font': 'Kitchen Font Size',
    'kitchen_font_hint': 'Use larger font for easy reading in the kitchen',
    'kitchen_preview': 'Preview & Test Print',
    'print_kitchen_test': 'Print Kitchen Test',

    // Misc
    'logout': 'Logout',
    'loading': 'Loading...',
  };
}

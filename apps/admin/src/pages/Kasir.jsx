import React, { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useProducts } from '../hooks/useProducts';
import { useCreateOrder } from '../hooks/useOrders';
import { useCreateExpense } from '../hooks/useExpenses';
import { SkeletonCard, EmptyState } from '../components/LoadingStates';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:3001';

export default function Kasir() {
    const navigate = useNavigate();
    const { data: products = [], isLoading: productsLoading } = useProducts();
    const createOrder = useCreateOrder();
    const createExpense = useCreateExpense();
    const [showPaymentModal, setShowPaymentModal] = useState(false);
    const [showReceiptModal, setShowReceiptModal] = useState(false);
    const [showExpenseModal, setShowExpenseModal] = useState(false);
    const [focusedInputId, setFocusedInputId] = useState(1);
    const firstNominalRef = useRef(null);

    // Auto-focus the first nominal input when payment modal opens
    useEffect(() => {
        if (showPaymentModal && firstNominalRef.current) {
            setTimeout(() => firstNominalRef.current?.focus(), 100);
        }
    }, [showPaymentModal]);
    const [lastOrder, setLastOrder] = useState(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [selectedCategory, setSelectedCategory] = useState('Semua');
    const [searchQuery, setSearchQuery] = useState('');

    // Cart & Order State
    const [cart, setCart] = useState([]);
    const [orderType, setOrderType] = useState('Makan di Tempat');
    const [tableNumber, setTableNumber] = useState('');
    const [savedOrders, setSavedOrders] = useState([]);
    const [showSavedOrdersModal, setShowSavedOrdersModal] = useState(false);

    // Filtered products by category and search
    const categories = ['Semua', ...new Set(products.map(p => p.category).filter(Boolean))];
    const filteredProducts = products.filter(p => {
        const matchesCategory = selectedCategory === 'Semua' || p.category === selectedCategory;
        const matchesSearch = !searchQuery || p.name.toLowerCase().includes(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
    });

    const addToCart = (product) => {
        setCart(prev => {
            const existing = prev.find(item => item.id === product.id);
            if (existing) {
                return prev.map(item => item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item);
            }
            return [...prev, { ...product, quantity: 1 }];
        });
    };

    const updateQuantity = (id, delta) => {
        setCart(prev => {
            return prev.map(item => {
                if (item.id === id) {
                    return { ...item, quantity: item.quantity + delta };
                }
                return item;
            }).filter(item => item.quantity > 0);
        });
    };

    const clearCart = () => {
        setCart([]);
        setTableNumber('');
        setOrderType('Makan di Tempat');
    };
    const removeCartItem = (id) => setCart(prev => prev.filter(item => item.id !== id));

    // Save current cart into drafted orders
    const saveOrder = () => {
        if (cart.length === 0) return;
        const newOrder = {
            id: `ORD-${Math.floor(Math.random() * 10000)}`,
            cart: [...cart],
            total: cartTotal,
            type: orderType,
            table: tableNumber || '-',
            time: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
        };
        setSavedOrders(prev => [newOrder, ...prev]);
        alert(`Pesanan berhasil disimpan sebagai ${newOrder.id}`);
        clearCart();
    };

    const restoreOrder = (orderId) => {
        const orderToRestore = savedOrders.find(o => o.id === orderId);
        if (orderToRestore) {
            setCart(orderToRestore.cart);
            setOrderType(orderToRestore.type);
            setTableNumber(orderToRestore.table === '-' ? '' : orderToRestore.table);
            setSavedOrders(prev => prev.filter(o => o.id !== orderId));
            setShowSavedOrdersModal(false);
        }
    };

    const cartSubtotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const cartTax = cartSubtotal * 0.1;
    const cartTotal = cartSubtotal + cartTax;

    // Payment State
    const [paymentMethods, setPaymentMethods] = useState([
        { id: 1, type: 'Tunai', amount: 0, icon: 'payments', color: 'emerald' },
    ]);

    const totalTerbayar = paymentMethods.reduce((sum, method) => sum + method.amount, 0);
    const sisa = cartTotal - totalTerbayar;
    const isLunas = cartTotal > 0 && sisa <= 0;

    const formatCurrency = (value) => {
        return new Intl.NumberFormat('id-ID').format(value);
    };

    const handleAmountChange = (id, value) => {
        const stripped = value.replace(/\D/g, '');
        const numericValue = stripped === '' ? 0 : Number(stripped);
        setPaymentMethods(methods => methods.map(m => m.id === id ? { ...m, amount: numericValue } : m));
    };

    const handleTypeChange = (id, newType) => {
        const typeConfig = {
            'Tunai': { icon: 'payments', color: 'emerald' },
            'Kartu Debit': { icon: 'credit_card', color: 'blue' },
            'Kartu Kredit': { icon: 'credit_card', color: 'indigo' },
            'QRIS': { icon: 'qr_code_scanner', color: 'purple' },
            'Transfer Bank': { icon: 'account_balance', color: 'orange' }
        };
        const config = typeConfig[newType] || typeConfig['Tunai'];
        setPaymentMethods(methods => methods.map(m => m.id === id ? { ...m, type: newType, ...config } : m));
    };

    const handleNumpadClick = (value) => {
        setPaymentMethods(methods => methods.map(m => {
            if (m.id === focusedInputId) {
                if (value === 'CLEAR') return { ...m, amount: 0 };
                if (value === 'BACKSPACE') {
                    const str = m.amount.toString();
                    const newVal = str.length > 1 ? parseInt(str.slice(0, -1), 10) : 0;
                    return { ...m, amount: newVal };
                }

                // Append digit
                const currentStr = m.amount.toString();
                const newStr = currentStr === '0' ? value : currentStr + value;
                if (newStr.length > 9) return m; // Max 999M

                return { ...m, amount: Number(newStr) };
            }
            return m;
        }));
    };

    const addPaymentMethod = () => {
        const newId = Math.max(0, ...paymentMethods.map(m => m.id)) + 1;
        setPaymentMethods([...paymentMethods, {
            id: newId,
            type: 'QRIS',
            amount: Math.max(0, sisa),
            icon: 'qr_code_scanner',
            color: 'purple'
        }]);
    };

    const removePaymentMethod = (id) => {
        setPaymentMethods(methods => methods.filter(m => m.id !== id));
    };

    return (
        <div className="bg-background-dark text-slate-100 font-display min-h-screen w-full flex flex-col overflow-hidden">
            {/* Header */}
            <header className="h-16 border-b border-white/5 bg-[#161b22] px-6 flex items-center justify-between shrink-0 relative z-10">
                <div className="flex items-center gap-4 flex-1 overflow-x-auto hide-scrollbar">
                    <div className="flex items-center gap-3 shrink-0">
                        <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-blue-600 shadow-lg shadow-blue-900/20">
                            <span className="material-symbols-outlined text-white">point_of_sale</span>
                        </div>
                        <div className="flex flex-col">
                            <h1 className="text-sm font-bold text-white leading-tight">Kasir-AI</h1>
                            <p className="text-[10px] text-slate-400">Cabang Jakarta • #POS-8821</p>
                        </div>
                    </div>

                    <div className="h-6 w-px bg-white/10 shrink-0 hidden md:block"></div>

                    <div className="relative group hidden md:flex shrink-0">
                        <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-[18px] group-focus-within:text-primary transition-colors">search</span>
                        <input
                            type="text"
                            placeholder="Cari menu..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="bg-white/5 border border-white/10 rounded-full py-1.5 pl-10 pr-4 w-48 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-primary/50 focus:bg-white/10 transition-colors"
                        />
                    </div>

                    <div className="h-6 w-px bg-white/10 shrink-0 hidden lg:block"></div>

                    {/* Category Filters */}
                    <div className="hidden lg:flex items-center gap-2 shrink-0">
                        {categories.map(cat => {
                            const icons = { 'Semua': 'grid_view', 'Kopi': 'local_cafe', 'Non-Kopi': 'blender', 'Makanan': 'restaurant', 'Kue': 'cake' };
                            const isActive = selectedCategory === cat;
                            return (
                                <button
                                    key={cat}
                                    onClick={() => setSelectedCategory(cat)}
                                    className={`flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-colors ${isActive
                                        ? 'bg-primary text-white shadow-lg shadow-primary/20'
                                        : 'glass-panel text-slate-300 hover:bg-white/5 hover:text-white border border-white/5'
                                        }`}
                                >
                                    <span className="material-symbols-outlined text-[16px]">{icons[cat] || 'category'}</span>
                                    {cat}
                                </button>
                            );
                        })}
                    </div>
                </div>

                <div className="flex items-center gap-4 shrink-0 ml-4">
                    <button
                        className="flex items-center gap-2 px-3 py-1.5 rounded-lg hover:bg-white/5 text-slate-400 hover:text-white transition-colors"
                        onClick={() => setShowSavedOrdersModal(true)}
                        title="Pesanan Tersimpan"
                    >
                        <span className="material-symbols-outlined text-[20px]">receipt_long</span>
                        <span className="text-sm font-medium hidden sm:inline">Tersimpan</span>
                        {savedOrders.length > 0 && (
                            <span className="flex h-5 w-5 items-center justify-center rounded-full bg-rose-500 text-[10px] font-bold text-white shadow-sm shadow-rose-500/30">
                                {savedOrders.length}
                            </span>
                        )}
                    </button>

                    <div className="h-6 w-px bg-white/10 hidden sm:block"></div>

                    <div className="flex items-center gap-3">
                        <div className="h-9 w-9 overflow-hidden rounded-full border border-white/10 shrink-0">
                            <img src="https://ui-avatars.com/api/?name=Alex+S&background=random&color=fff" alt="User Avatar" className="h-full w-full object-cover" />
                        </div>
                        <div className="hidden sm:flex flex-col">
                            <span className="text-sm font-semibold text-white leading-tight">Alex S.</span>
                            <span className="text-[10px] text-slate-400">Kasir</span>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <div className="flex flex-1 overflow-hidden relative">

                {/* Left Side: Menu Grid */}
                <main className="flex-1 flex flex-col bg-[#0f1115] relative">


                    {/* Glowing Orbs Background */}
                    <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl pointer-events-none"></div>

                    {/* Products Grid */}
                    <div className="flex-1 overflow-y-auto p-6 scroll-smooth">
                        <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-6 pb-20">

                            {productsLoading ? <SkeletonCard count={8} /> : filteredProducts.length === 0 ? (
                                <div className="col-span-full">
                                    <EmptyState icon="restaurant_menu" title="Belum ada produk" description="Produk akan muncul di sini setelah ditambahkan." />
                                </div>
                            ) : filteredProducts.map(product => (
                                <div key={product.id} onClick={() => addToCart(product)} className="glass-card rounded-2xl p-3 flex flex-col gap-3 group cursor-pointer border border-white/5 hover:border-primary/30 transition-all duration-300 relative overflow-hidden">
                                    <div className="absolute top-4 right-4 bg-black/60 backdrop-blur-md text-white text-[10px] font-bold px-2 py-1 rounded-full z-10 border border-white/10 shadow-sm">
                                        {formatCurrency(product.price).replace('Rp ', '')}
                                    </div>
                                    <div className="aspect-[4/3] rounded-xl overflow-hidden bg-slate-800 relative">
                                        <div className="absolute inset-0 bg-gradient-to-t from-[#161b22] to-transparent opacity-60 z-0 group-hover:opacity-40 transition-opacity"></div>
                                        {product.imageUrl ? (
                                            <img src={`${API_BASE}${product.imageUrl}`} alt={product.name} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center">
                                                <span className="material-symbols-outlined text-4xl text-slate-600">fastfood</span>
                                            </div>
                                        )}
                                        <div className="absolute inset-0 bg-primary/0 group-hover:bg-primary/20 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100 z-20">
                                            <div className="bg-white text-primary rounded-full p-2 shadow-xl transform translate-y-4 group-hover:translate-y-0 transition-all duration-300">
                                                <span className="material-symbols-outlined font-bold">add_shopping_cart</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="flex flex-col px-1 pb-1">
                                        <h3 className="text-sm font-bold text-white group-hover:text-primary transition-colors">{product.name}</h3>
                                        <p className="text-[11px] text-slate-400 truncate mt-0.5">{product.description || product.category || ''}</p>
                                    </div>
                                </div>
                            ))}

                        </div>
                    </div>
                </main>

                {/* Right Side: Order Panel */}
                <aside className="w-[380px] bg-[#161b22] border-l border-white/5 flex flex-col shrink-0 relative z-10 shadow-2xl">

                    {/* Panel Header */}
                    <div className="p-6 border-b border-white/5 flex flex-col gap-3 shrink-0">
                        <div className="flex justify-between items-center">
                            <div>
                                <h2 className="text-lg font-bold text-white tracking-tight">PESANAN SAAT INI</h2>
                                <p className="text-xs text-slate-400 mt-1 cursor-pointer hover:text-primary transition-colors inline-block" onClick={() => setOrderType(orderType === 'Makan di Tempat' ? 'Bawa Pulang' : 'Makan di Tempat')}>
                                    {orderType} <span className="material-symbols-outlined text-[12px] align-middle">sync_alt</span>
                                </p>
                            </div>
                            <button onClick={clearCart} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-rose-400 hover:bg-rose-500/10 hover:text-rose-300 transition-colors">
                                <span className="material-symbols-outlined text-[16px]">delete</span>
                                <span className="text-xs font-semibold">Hapus</span>
                            </button>
                        </div>

                        {/* Table Number Input Block */}
                        {orderType === 'Makan di Tempat' && (
                            <div className="flex items-center gap-3">
                                <div className="flex items-center gap-2 bg-black/20 border border-white/10 rounded-lg px-3 py-1.5 flex-1">
                                    <span className="material-symbols-outlined text-slate-400 text-[18px]">table_restaurant</span>
                                    <input
                                        type="text"
                                        placeholder="Nomor Meja"
                                        value={tableNumber}
                                        onChange={(e) => setTableNumber(e.target.value)}
                                        className="bg-transparent border-none text-white text-sm font-semibold focus:outline-none w-full placeholder:text-slate-500"
                                    />
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Order Items */}
                    <div className="flex-1 overflow-y-auto p-4 space-y-3 hide-scrollbar">

                        {cart.map((item) => (
                            <div key={item.id} className="glass-panel p-3 rounded-xl flex flex-col gap-3 border border-white/5 relative group">
                                <button onClick={() => removeCartItem(item.id)} className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-rose-500 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-lg scale-90 hover:scale-100">
                                    <span className="material-symbols-outlined text-[14px]">close</span>
                                </button>
                                <div className="flex gap-3">
                                    <div className="w-14 h-14 rounded-lg overflow-hidden shrink-0">
                                        <img src={item.img} alt={item.name} className="w-full h-full object-cover" />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-start justify-between gap-2">
                                            <h4 className="text-sm font-bold text-white leading-tight truncate">{item.name}</h4>
                                            <span className="text-sm font-bold text-white shrink-0">Rp {formatCurrency(item.price * item.quantity)}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="flex items-center justify-between pt-2 border-t border-white/5">
                                    <button className="text-[11px] font-medium text-slate-400 flex items-center gap-1 hover:text-white transition-colors">
                                        <span className="material-symbols-outlined text-[14px]">add_circle</span>
                                        Catatan
                                    </button>
                                    <div className="flex items-center bg-black/20 rounded-lg p-0.5 text-white">
                                        <button onClick={() => updateQuantity(item.id, -1)} className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-white/10 transition-colors">
                                            <span className="material-symbols-outlined text-[16px]">remove</span>
                                        </button>
                                        <span className="w-6 text-center text-sm font-bold">{item.quantity}</span>
                                        <button onClick={() => updateQuantity(item.id, 1)} className="w-7 h-7 flex items-center justify-center rounded-md bg-primary hover:bg-blue-500 transition-colors text-white shadow-sm shadow-primary/30">
                                            <span className="material-symbols-outlined text-[16px]">add</span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}

                        {cart.length === 0 && (
                            <div className="border-2 border-dashed border-white/5 rounded-2xl p-8 flex flex-col items-center justify-center text-center mt-4">
                                <span className="material-symbols-outlined text-slate-600 text-4xl mb-2">touch_app</span>
                                <p className="text-slate-500 text-sm font-medium">Pilih menu untuk menambahkan<br />ke pesanan.</p>
                            </div>
                        )}
                    </div>

                    {/* Panel Footer / Checkout */}
                    <div className="p-6 border-t border-white/5 bg-[#161b22] shrink-0 space-y-4">
                        <div className="space-y-2">
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-400">Subtotal</span>
                                <span className="text-slate-300 font-medium">Rp {formatCurrency(cartSubtotal)}</span>
                            </div>
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-400">Pajak (10%)</span>
                                <span className="text-slate-300 font-medium">Rp {formatCurrency(cartTax)}</span>
                            </div>
                            <div className="pt-3 mt-1 border-t border-white/5 border-dashed flex justify-between items-end">
                                <span className="text-base font-bold text-white">Total</span>
                                <span className="text-2xl font-black text-primary tracking-tight">Rp {formatCurrency(cartTotal)}</span>
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-3 pt-2">
                            <button
                                className="w-full h-14 bg-slate-800 hover:bg-slate-700 active:scale-[0.98] text-white rounded-xl font-bold text-sm border border-white/5 transition-all flex items-center justify-center gap-2"
                                onClick={saveOrder}
                            >
                                <span className="material-symbols-outlined text-[20px]">bookmark</span>
                                Simpan
                            </button>
                            <button
                                className="w-full h-14 bg-primary hover:bg-blue-600 disabled:opacity-50 disabled:hover:scale-100 disabled:cursor-not-allowed active:scale-[0.98] text-white rounded-xl font-bold text-sm shadow-lg shadow-primary/25 transition-all flex items-center justify-center gap-2 group"
                                onClick={() => setShowPaymentModal(true)}
                                disabled={cart.length === 0}
                            >
                                <span>BAYAR</span>
                                <span className="material-symbols-outlined font-bold group-hover:translate-x-1 transition-transform">arrow_forward</span>
                            </button>
                        </div>

                        <div className="grid grid-cols-2 gap-3 pt-2">
                            <button
                                className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border border-white/10 text-slate-300 text-sm font-medium hover:bg-white/5 transition-colors"
                                onClick={() => setShowExpenseModal(true)}
                            >
                                <span className="material-symbols-outlined text-[18px]">receipt_long</span>
                                Pengeluaran
                            </button>
                            <button className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border border-rose-500/20 text-rose-400 text-sm font-medium hover:bg-rose-500/10 transition-colors" onClick={() => navigate('/tutup-shift')}>
                                <span className="material-symbols-outlined text-[18px]">logout</span>
                                Akhiri Shift
                            </button>
                        </div>
                    </div>
                </aside>
            </div >

            {/* Payment Modal */}
            {
                showPaymentModal && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm antialiased font-display">
                        <div className="w-full max-w-4xl bg-[#0f1115] border border-white/10 rounded-2xl shadow-2xl overflow-hidden flex flex-col">

                            {/* Modal Header */}
                            <div className="p-6 pb-4 border-b border-white/5 flex items-start justify-between bg-[#161b22]">
                                <div>
                                    <h2 className="text-xl font-bold text-white tracking-tight">Pembayaran Terpisah</h2>
                                    <p className="text-sm text-slate-400 mt-1">Order #1023-A • Table 4</p>
                                </div>
                                <button
                                    className="text-slate-400 hover:text-white transition-colors"
                                    onClick={() => setShowPaymentModal(false)}
                                >
                                    <span className="material-symbols-outlined text-[24px]">close</span>
                                </button>
                            </div>

                            {/* Total Tagihan */}
                            <div className="py-6 bg-[#161b22] flex flex-col items-center justify-center">
                                <span className="text-xs font-bold text-blue-400 tracking-widest uppercase mb-1">Total Tagihan</span>
                                <span className="text-5xl font-black text-white tracking-tight">Rp {formatCurrency(cartTotal)}</span>
                            </div>

                            {/* Middle Content: Split Layout */}
                            <div className="flex border-t border-b border-white/5 bg-[#0f1115]">

                                {/* Left Side: Methods List */}
                                <div className="flex-1 p-6 border-r border-white/5 space-y-4 max-h-[400px] overflow-y-auto hide-scrollbar">

                                    {paymentMethods.map((method) => (
                                        <div key={method.id} className="flex items-center gap-4">
                                            <div className={`w-10 h-10 rounded-full bg-${method.color}-500/10 border border-${method.color}-500/20 flex items-center justify-center text-${method.color}-400 shrink-0`}>
                                                <span className="material-symbols-outlined text-[20px]">{method.icon}</span>
                                            </div>
                                            <div className="flex-1 grid grid-cols-2 gap-3">

                                                {/* Native Select Dropdown */}
                                                <div className="bg-[#161b22] border border-white/5 rounded-xl px-4 py-2 flex flex-col relative group focus-within:border-white/20 transition-colors">
                                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-0.5">Metode</span>
                                                    <select
                                                        className="w-full bg-transparent text-sm font-semibold text-white focus:outline-none appearance-none cursor-pointer"
                                                        value={method.type}
                                                        onChange={(e) => handleTypeChange(method.id, e.target.value)}
                                                    >
                                                        <option className="bg-[#161b22] text-white" value="Tunai">Tunai</option>
                                                        <option className="bg-[#161b22] text-white" value="Kartu Debit">Kartu Debit</option>
                                                        <option className="bg-[#161b22] text-white" value="Kartu Kredit">Kartu Kredit</option>
                                                        <option className="bg-[#161b22] text-white" value="QRIS">QRIS</option>
                                                        <option className="bg-[#161b22] text-white" value="Transfer Bank">Transfer Bank</option>
                                                    </select>
                                                    <span className="material-symbols-outlined text-slate-500 absolute right-3 bottom-2 pointer-events-none group-hover:text-white transition-colors">expand_more</span>
                                                </div>

                                                {/* Nominal Input */}
                                                <div
                                                    className={`bg-[#161b22] border rounded-xl px-4 py-2 flex flex-col justify-center relative transition-colors ${focusedInputId === method.id ? 'border-primary shadow-[0_0_15px_rgba(59,130,246,0.15)]' : 'border-white/5 hover:border-white/20'}`}
                                                    onClick={() => setFocusedInputId(method.id)}
                                                >
                                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Nominal</span>
                                                    <div className="flex items-center gap-1 mt-0.5">
                                                        <span className="text-sm font-semibold text-slate-400">Rp</span>
                                                        <input
                                                            type="text"
                                                            value={method.amount === 0 ? '' : formatCurrency(method.amount)}
                                                            onChange={(e) => {
                                                                setFocusedInputId(method.id);
                                                                handleAmountChange(method.id, e.target.value);
                                                            }}
                                                            ref={method.id === paymentMethods[0]?.id ? firstNominalRef : undefined}
                                                            onFocus={() => setFocusedInputId(method.id)}
                                                            placeholder="0"
                                                            className="w-full bg-transparent text-sm font-semibold text-white focus:outline-none placeholder:text-slate-600"
                                                        />
                                                    </div>
                                                </div>

                                            </div>
                                            <button
                                                className="w-10 h-10 rounded-xl flex items-center justify-center text-slate-500 hover:bg-rose-500/10 hover:text-rose-400 transition-colors shrink-0"
                                                onClick={() => removePaymentMethod(method.id)}
                                            >
                                                <span className="material-symbols-outlined text-[20px]">delete</span>
                                            </button>
                                        </div>
                                    ))}

                                    {/* Add Method Button */}
                                    <button
                                        className="w-full py-4 mt-2 flex items-center justify-center gap-2 text-sm font-semibold text-primary hover:text-blue-400 transition-colors"
                                        onClick={addPaymentMethod}
                                    >
                                        <span className="material-symbols-outlined text-[18px]">add_circle</span>
                                        Tambah Metode Lain
                                    </button>
                                </div>

                                {/* Right Side: Numpad */}
                                <div className="w-[320px] p-6 bg-[#161b22] shrink-0 flex flex-col">
                                    <div className="grid grid-cols-3 gap-3 flex-1 mb-4">
                                        {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => (
                                            <button
                                                key={num}
                                                onClick={() => handleNumpadClick(num.toString())}
                                                className="bg-white/5 hover:bg-white/10 active:scale-95 text-white text-xl font-bold rounded-xl transition-all h-full min-h-[56px] flex items-center justify-center"
                                            >
                                                {num}
                                            </button>
                                        ))}
                                        <button
                                            onClick={() => handleNumpadClick('CLEAR')}
                                            className="bg-rose-500/10 hover:bg-rose-500/20 active:scale-95 text-rose-400 text-xs font-bold rounded-xl transition-all h-full min-h-[56px] flex items-center justify-center tracking-wider"
                                        >
                                            CLEAR
                                        </button>
                                        <button
                                            onClick={() => handleNumpadClick('0')}
                                            className="bg-white/5 hover:bg-white/10 active:scale-95 text-white text-xl font-bold rounded-xl transition-all h-full min-h-[56px] flex items-center justify-center"
                                        >
                                            0
                                        </button>
                                        <button
                                            onClick={() => handleNumpadClick('BACKSPACE')}
                                            className="bg-white/5 hover:bg-white/10 active:scale-95 text-slate-400 hover:text-white rounded-xl transition-all h-full min-h-[56px] flex items-center justify-center"
                                        >
                                            <span className="material-symbols-outlined">backspace</span>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            {/* Summary & Confirm */}
                            <div className="p-6 border-t border-white/5 bg-[#161b22]">
                                <div className="flex items-center justify-between gap-4">
                                    <div className="flex items-center gap-6">
                                        <div className="flex flex-col">
                                            <span className="text-xs font-medium text-slate-400">Total Terbayar</span>
                                            <span className="text-lg font-bold text-white mt-0.5">Rp {formatCurrency(totalTerbayar)}</span>
                                        </div>
                                        <div className="w-px h-10 bg-white/10"></div>
                                        <div className="flex flex-col">
                                            <span className="text-xs font-medium text-slate-400">{isLunas ? 'Kembalian' : 'Sisa'}</span>
                                            <span className={`text-lg font-bold mt-0.5 ${isLunas && Math.abs(sisa) > 0 ? 'text-emerald-400' : 'text-slate-500'}`}>
                                                Rp {formatCurrency(Math.abs(sisa))}
                                            </span>
                                        </div>
                                        {isLunas && (
                                            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 shrink-0">
                                                <span className="material-symbols-outlined text-[14px]">check_circle</span>
                                                <span className="text-[11px] font-bold tracking-wider">LUNAS</span>
                                            </div>
                                        )}
                                    </div>

                                    <button
                                        className="h-12 px-8 rounded-xl bg-primary hover:bg-blue-600 active:scale-[0.98] text-white font-bold shadow-lg shadow-primary/25 transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed shrink-0"
                                        disabled={!isLunas || isSubmitting}
                                        onClick={async () => {
                                            setIsSubmitting(true);
                                            try {
                                                const orderData = {
                                                    orderType: orderType === 'Makan di Tempat' ? 'dine_in' : 'takeaway',
                                                    tableNumber: tableNumber || null,
                                                    items: cart.map(item => ({
                                                        productId: item.id,
                                                        quantity: item.quantity,
                                                        price: item.price,
                                                        name: item.name,
                                                    })),
                                                    subtotal: cartSubtotal,
                                                    tax: cartTax,
                                                    total: cartTotal,
                                                    payments: paymentMethods.map(m => ({
                                                        method: m.type,
                                                        amount: m.amount,
                                                    })),
                                                };
                                                const result = await createOrder.mutateAsync(orderData);
                                                setLastOrder({
                                                    ...orderData,
                                                    id: result?.id || `KAI-${Date.now().toString().slice(-6)}`,
                                                    createdAt: new Date(),
                                                    cart: [...cart],
                                                });
                                                setShowPaymentModal(false);
                                                setShowReceiptModal(true);
                                                clearCart();
                                                setPaymentMethods([{ id: 1, type: 'Tunai', amount: 0, icon: 'payments', color: 'emerald' }]);
                                            } catch (err) {
                                                console.error('Order failed:', err);
                                                setLastOrder({
                                                    id: `KAI-${Date.now().toString().slice(-6)}`,
                                                    createdAt: new Date(),
                                                    cart: [...cart],
                                                    subtotal: cartSubtotal,
                                                    tax: cartTax,
                                                    total: cartTotal,
                                                    payments: paymentMethods.map(m => ({ method: m.type, amount: m.amount })),
                                                    orderType,
                                                    tableNumber,
                                                });
                                                setShowPaymentModal(false);
                                                setShowReceiptModal(true);
                                                clearCart();
                                            } finally {
                                                setIsSubmitting(false);
                                            }
                                        }}
                                    >
                                        {isSubmitting ? (
                                            <><div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div> Memproses...</>
                                        ) : (
                                            <><span className="material-symbols-outlined text-[20px]">check</span> Konfirmasi</>
                                        )}
                                    </button>
                                </div>
                            </div>

                        </div>
                    </div>
                )
            }
            {/* Receipt Modal */}
            {
                showReceiptModal && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm antialiased font-display">

                        <div className="relative z-10 w-full max-w-sm flex flex-col max-h-[90vh]">
                            <div id="printable-receipt" className="relative flex flex-col bg-[#1e293b] dark:bg-[#1e293b]/95 backdrop-blur-xl border border-white/10 rounded-t-xl rounded-b-md shadow-2xl overflow-hidden">

                                {/* Receipt Header */}
                                <div className="flex flex-col items-center pt-8 pb-4 px-6 border-b border-white/5 border-dashed relative">
                                    <div className="mb-3 p-3 rounded-full bg-primary/20 text-primary">
                                        <span className="material-symbols-outlined text-3xl">storefront</span>
                                    </div>
                                    <h2 className="text-xl font-bold tracking-tight text-white mb-1">Kasir-AI</h2>
                                    <p className="text-slate-400 text-sm font-medium">Cabang Jakarta Selatan</p>
                                    {lastOrder?.tableNumber && (
                                        <div className="mt-1 text-primary text-[10px] font-bold tracking-widest uppercase">MEJA #{lastOrder.tableNumber}</div>
                                    )}
                                    <div className="mt-4 flex flex-col items-center gap-1 text-xs text-slate-500 font-mono">
                                        <span>{lastOrder?.createdAt ? new Date(lastOrder.createdAt).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).toUpperCase() + ' • ' + new Date(lastOrder.createdAt).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-'}</span>
                                        <span>PESANAN #{lastOrder?.id || '-'}</span>
                                    </div>
                                    <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-b from-black/20 to-transparent"></div>
                                </div>

                                {/* Receipt Content */}
                                <div className="flex-1 overflow-y-auto custom-scrollbar px-6 py-4">

                                    {/* Item List */}
                                    <div className="flex flex-col gap-4">
                                        {(lastOrder?.cart || []).map((item, i) => (
                                            <div key={i} className="flex justify-between items-start group">
                                                <div className="flex gap-3">
                                                    <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded bg-slate-700/50 text-xs font-bold text-slate-300 border border-slate-600">
                                                        {item.quantity}x
                                                    </div>
                                                    <div>
                                                        <p className="text-sm font-medium text-slate-200">{item.name}</p>
                                                    </div>
                                                </div>
                                                <p className="text-sm font-semibold text-slate-200">{formatCurrency(item.price * item.quantity)}</p>
                                            </div>
                                        ))}
                                    </div>

                                    {/* Receipt Divider */}
                                    <div className="my-6 border-b-2 border-dashed border-slate-700/50 relative">
                                        <div className="absolute -left-8 -top-2.5 w-5 h-5 rounded-full bg-[#0f1115]"></div>
                                        <div className="absolute -right-8 -top-2.5 w-5 h-5 rounded-full bg-[#0f1115]"></div>
                                    </div>

                                    {/* Calculations */}
                                    <div className="flex flex-col gap-2 text-sm">
                                        <div className="flex justify-between text-slate-400">
                                            <span>Subtotal</span>
                                            <span>{formatCurrency(lastOrder?.subtotal || 0)}</span>
                                        </div>
                                        <div className="flex justify-between text-slate-400">
                                            <span>Pajak (10%)</span>
                                            <span>{formatCurrency(lastOrder?.tax || 0)}</span>
                                        </div>
                                        {(lastOrder?.payments || []).map((p, i) => (
                                            <div key={i} className="flex justify-between text-slate-400 pt-1">
                                                <span>Pembayaran ({p.method})</span>
                                                <span className="font-medium text-slate-300">Rp {formatCurrency(p.amount)}</span>
                                            </div>
                                        ))}
                                        <div className="flex justify-between items-center mt-3 pt-3 border-t border-slate-700/50">
                                            <span className="text-base font-bold text-white">Total</span>
                                            <span className="text-xl font-bold text-primary">Rp {formatCurrency(lastOrder?.total || 0)}</span>
                                        </div>
                                    </div>

                                    {/* Payment Method Status */}
                                    <div className="mt-6 flex items-center justify-between rounded-lg bg-emerald-500/10 border border-emerald-500/20 p-3">
                                        <div className="flex items-center gap-2">
                                            <span className="material-symbols-outlined text-emerald-500 text-lg">check_circle</span>
                                            <span className="text-xs font-semibold text-emerald-400 uppercase tracking-wide">LUNAS</span>
                                        </div>
                                        <span className="text-xs text-emerald-500/80 font-mono">ID: {lastOrder?.id || '-'}</span>
                                    </div>

                                    {/* QR Code */}
                                    <div className="mt-6 flex flex-col items-center gap-3 pb-8">
                                        <div className="bg-white p-2 rounded-lg">
                                            <div className="w-24 h-24 bg-white relative flex items-center justify-center overflow-hidden">
                                                <img alt="QR Code" className="w-full h-full object-contain" src={`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${lastOrder?.id || 'ORDER'}`} />
                                            </div>
                                        </div>
                                        <p className="text-[10px] text-slate-500 text-center uppercase tracking-widest">PINDAI UNTUK POIN LOYALITAS</p>
                                    </div>

                                </div>

                                {/* Receipt Footer Actions */}
                                <div className="p-4 bg-[#16202e] border-t border-white/5 flex flex-col gap-3 relative z-10 no-print">
                                    <button
                                        className="flex w-full items-center justify-center gap-2 rounded-xl bg-primary hover:bg-blue-600 transition-colors h-11 text-sm font-bold text-white shadow-lg shadow-primary/20"
                                        onClick={() => window.print()}
                                    >
                                        <span className="material-symbols-outlined text-[20px]">print</span>
                                        Cetak Struk
                                    </button>
                                    <button
                                        className="flex w-full items-center justify-center gap-2 rounded-xl bg-transparent hover:bg-white/5 transition-colors h-11 text-sm font-bold text-white border border-white/5"
                                        onClick={() => setShowReceiptModal(false)}
                                    >
                                        <span className="material-symbols-outlined text-[18px]">close</span>
                                        Tutup
                                    </button>
                                </div>

                                {/* Jagged Edge bottom effect (from index.css base styles) */}
                                <div className="receipt-jagged-edge z-20 pointer-events-none"></div>

                            </div>

                            <button
                                className="absolute -top-12 right-0 md:-right-12 p-2 text-white/50 hover:text-white transition-colors rounded-full hover:bg-white/10"
                                onClick={() => setShowReceiptModal(false)}
                            >
                                <span className="material-symbols-outlined text-3xl">close</span>
                            </button>
                        </div>
                    </div>
                )
            }

            {/* Expense Modal */}
            {
                showExpenseModal && (
                    <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
                        {/* Modal Card: Glassmorphism */}
                        <div className="w-full max-w-[520px] bg-[#1e293b]/70 backdrop-blur-xl border border-white/10 rounded-xl shadow-2xl animate-in fade-in zoom-in duration-300">
                            {/* Modal Header */}
                            <div className="flex items-center justify-between p-6 border-b border-white/10">
                                <div>
                                    <h2 className="text-xl font-bold text-white tracking-tight">Input Pengeluaran</h2>
                                    <p className="text-xs text-slate-400 mt-1">Catat biaya operasional shift ini</p>
                                </div>
                                <button
                                    className="flex items-center justify-center w-8 h-8 rounded-full bg-white/5 hover:bg-white/10 text-slate-400 hover:text-white transition-colors"
                                    onClick={() => setShowExpenseModal(false)}
                                >
                                    <span className="material-symbols-outlined text-[20px]">close</span>
                                </button>
                            </div>

                            {/* Modal Body */}
                            <div className="p-6 space-y-6">
                                {/* Amount Input */}
                                <div className="space-y-2">
                                    <label className="block text-sm font-medium text-slate-300">Jumlah Pengeluaran</label>
                                    <div className="relative group">
                                        <div className="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
                                            <span className="text-slate-400 font-bold text-lg">Rp</span>
                                        </div>
                                        <input className="block w-full rounded-lg bg-[#111418]/80 border-slate-600/50 text-white pl-12 pr-4 py-3 text-2xl font-bold placeholder-slate-600 focus:border-primary focus:ring-1 focus:ring-primary transition-all focus:outline-none" placeholder="0" type="text" defaultValue="50.000" />
                                        {/* Action indicator */}
                                        <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                                            <span className="material-symbols-outlined text-emerald-500 animate-pulse">check_circle</span>
                                        </div>
                                    </div>
                                </div>

                                {/* Description & Category Row */}
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    {/* Category Dropdown */}
                                    <div className="space-y-2">
                                        <label className="block text-sm font-medium text-slate-300">Kategori</label>
                                        <div className="relative">
                                            <select className="block w-full rounded-lg bg-[#111418]/80 border-slate-600/50 text-white pl-4 pr-10 py-2.5 focus:border-primary focus:ring-1 focus:ring-primary appearance-none cursor-pointer focus:outline-none">
                                                <option>Perlengkapan</option>
                                                <option>Bahan Baku Darurat</option>
                                                <option>Maintenance</option>
                                                <option>Lainnya</option>
                                            </select>
                                            <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none text-slate-400">
                                                <span className="material-symbols-outlined">expand_more</span>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Source Toggle */}
                                    <div className="space-y-2">
                                        <label className="block text-sm font-medium text-slate-300">Sumber Dana</label>
                                        <div className="flex p-1 bg-[#111418]/80 rounded-lg border border-slate-600/30">
                                            <label className="flex-1 cursor-pointer group">
                                                <input defaultChecked className="sr-only peer" name="source" type="radio" />
                                                <div className="flex items-center justify-center py-1.5 px-3 rounded text-sm font-medium text-slate-400 peer-checked:bg-primary peer-checked:text-white transition-all group-hover:bg-white/5">
                                                    Kasir
                                                </div>
                                            </label>
                                            <label className="flex-1 cursor-pointer group">
                                                <input className="sr-only peer" name="source" type="radio" />
                                                <div className="flex items-center justify-center py-1.5 px-3 rounded text-sm font-medium text-slate-400 peer-checked:bg-primary peer-checked:text-white transition-all group-hover:bg-white/5">
                                                    Kas Pusat
                                                </div>
                                            </label>
                                        </div>
                                    </div>
                                </div>

                                {/* Description Textarea */}
                                <div className="space-y-2">
                                    <label className="block text-sm font-medium text-slate-300">Keterangan</label>
                                    <textarea className="block w-full rounded-lg bg-[#111418]/80 border-slate-600/50 text-white p-3 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none min-h-[80px] resize-none placeholder-slate-500 text-sm" placeholder="Contoh: Beli es batu kristal 2 pack, Isi ulang gas elpiji 3kg"></textarea>
                                </div>

                                {/* Proof of Transaction (Optional) */}
                                <div className="space-y-2">
                                    <label className="block text-sm font-medium text-slate-300">Bukti Struk (Opsional)</label>
                                    <div className="flex items-center justify-center w-full">
                                        <label className="flex flex-col items-center justify-center w-full h-24 border-2 border-slate-600/30 border-dashed rounded-lg cursor-pointer bg-[#111418]/40 hover:bg-[#111418]/60 hover:border-slate-500 transition-all group" htmlFor="dropzone-file">
                                            <div className="flex flex-col items-center justify-center pt-5 pb-6">
                                                <span className="material-symbols-outlined text-slate-500 group-hover:text-primary mb-1 transition-colors">cloud_upload</span>
                                                <p className="text-xs text-slate-400"><span className="font-semibold text-slate-300">Klik upload</span> atau drag &amp; drop</p>
                                            </div>
                                            <input className="hidden" id="dropzone-file" type="file" />
                                        </label>
                                    </div>
                                </div>
                            </div>

                            {/* Modal Footer */}
                            <div className="p-6 pt-0">
                                <button
                                    className="w-full flex items-center justify-center gap-2 bg-primary hover:bg-blue-600 active:scale-[0.98] text-white font-bold py-3.5 px-4 rounded-xl shadow-lg shadow-primary/25 transition-all text-sm"
                                    onClick={() => setShowExpenseModal(false)}
                                >
                                    <span className="material-symbols-outlined text-[20px]">save</span>
                                    <span>SIMPAN PENGELUARAN</span>
                                </button>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* Saved Orders Modal */}
            {
                showSavedOrdersModal && (
                    <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                        <div className="w-full max-w-2xl bg-[#0f1115] border border-white/10 rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
                            {/* Modal Header */}
                            <div className="p-6 pb-4 border-b border-white/5 flex items-start justify-between bg-[#161b22]">
                                <div>
                                    <h2 className="text-xl font-bold text-white tracking-tight">Pesanan Tersimpan</h2>
                                    <p className="text-sm text-slate-400 mt-1">Lanjutkan pesanan yang belum diselesaikan</p>
                                </div>
                                <button
                                    className="text-slate-400 hover:text-white transition-colors"
                                    onClick={() => setShowSavedOrdersModal(false)}
                                >
                                    <span className="material-symbols-outlined text-[24px]">close</span>
                                </button>
                            </div>

                            {/* Modal Body */}
                            <div className="p-6 overflow-y-auto space-y-4">
                                {savedOrders.length === 0 ? (
                                    <div className="text-center py-10">
                                        <span className="material-symbols-outlined text-slate-600 text-6xl mb-4">inbox</span>
                                        <p className="text-slate-400 font-medium pb-4">Tidak ada pesanan yang tersimpan.</p>
                                    </div>
                                ) : (
                                    savedOrders.map((order) => (
                                        <div key={order.id} className="glass-panel p-4 rounded-xl border border-white/5 flex items-center justify-between hover:border-primary/30 transition-colors">
                                            <div className="flex gap-4">
                                                <div className="h-12 w-12 rounded-lg bg-primary/20 text-blue-400 flex items-center justify-center border border-primary/20">
                                                    <span className="material-symbols-outlined text-[24px]">receipt_long</span>
                                                </div>
                                                <div className="flex flex-col flex-1 pl-1">
                                                    <div className="flex items-center gap-2">
                                                        <h3 className="font-bold text-white tracking-wider">{order.id}</h3>
                                                        <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-white/10 text-slate-300 tracking-widest">{order.type}</span>
                                                        {order.table !== '-' && (
                                                            <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-500 tracking-widest border border-amber-500/20">MEJA {order.table}</span>
                                                        )}
                                                    </div>
                                                    <div className="flex items-center gap-3 mt-1.5 text-sm text-slate-400">
                                                        <span className="flex items-center gap-1"><span className="material-symbols-outlined text-[14px]">schedule</span> {order.time}</span>
                                                        <span className="flex items-center gap-1"><span className="material-symbols-outlined text-[14px]">shopping_bag</span> {order.cart.reduce((s, i) => s + i.quantity, 0)} item</span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="flex flex-col items-end gap-2 pr-2">
                                                <span className="font-bold text-white">Rp {formatCurrency(order.total)}</span>
                                                <button
                                                    onClick={() => restoreOrder(order.id)}
                                                    className="px-4 py-1.5 rounded-lg bg-primary hover:bg-blue-600 text-white text-xs font-bold transition-all shadow-md shadow-primary/20"
                                                >
                                                    Lanjutkan Bukanya
                                                </button>
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>
                        </div>
                    </div>
                )
            }
        </div >
    );
}

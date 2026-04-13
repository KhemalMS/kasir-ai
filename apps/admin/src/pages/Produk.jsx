import React, { useState, useRef } from 'react';
import { useProducts, useCreateProduct, useUpdateProduct, useDeleteProduct } from '../hooks/useProducts';
import { useCategories } from '../hooks/useCategories';
import { SkeletonCard, EmptyState } from '../components/LoadingStates';
import { productsService } from '../services/products.service';

export default function Produk() {
    const [showProductModal, setShowProductModal] = useState(false);
    const [modalMode, setModalMode] = useState('add'); // 'add' or 'edit'
    const [selectedProduct, setSelectedProduct] = useState(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [categoryFilter, setCategoryFilter] = useState(null);
    const [formName, setFormName] = useState('');
    const [formPrice, setFormPrice] = useState('');
    const [formCategory, setFormCategory] = useState('');
    const [formDescription, setFormDescription] = useState('');
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
    const [isSaving, setIsSaving] = useState(false);
    const fileInputRef = useRef(null);

    const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:3001';

    const { data: products = [], isLoading } = useProducts({ search: searchQuery || undefined, categoryId: categoryFilter || undefined });
    const { data: categories = [] } = useCategories();
    const createProduct = useCreateProduct();
    const updateProduct = useUpdateProduct();
    const deleteProduct = useDeleteProduct();

    return (
        <>
            <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none z-0">
                <div className="absolute top-[-20%] left-[10%] w-[500px] h-[500px] bg-primary/20 rounded-full blur-[120px] opacity-30"></div>
                <div className="absolute bottom-[-10%] right-[5%] w-[400px] h-[400px] bg-purple-500/10 rounded-full blur-[100px] opacity-20"></div>
            </div>

            <header className="z-10 flex flex-wrap items-center justify-between gap-4 border-b border-white/10 bg-[#101922]/80 px-6 py-5 backdrop-blur-md">
                <div className="flex flex-col gap-1">
                    <h2 className="text-2xl font-black tracking-tight text-white">Manajemen Produk</h2>
                    <p className="text-sm text-slate-400">Kelola inventaris Anda di 3 cabang</p>
                </div>
                <button
                    className="flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-bold text-white shadow-lg shadow-primary/25 transition-all hover:bg-blue-600 active:scale-95 cursor-pointer"
                    onClick={() => {
                        setModalMode('add');
                        setSelectedProduct(null);
                        setFormName(''); setFormPrice(''); setFormCategory(''); setFormDescription('');
                        setImageFile(null); setImagePreview(null);
                        setShowProductModal(true);
                    }}
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    <span className="hidden sm:inline">Tambah Produk</span>
                </button>
            </header>

            <div className="z-10 flex-1 overflow-y-auto p-6 scroll-smooth">
                <div className="mx-auto flex max-w-[1400px] flex-col gap-6">
                    <div className="glass-panel flex flex-col gap-4 rounded-xl p-4 md:flex-row md:items-center md:justify-between">
                        <div className="relative w-full md:w-96">
                            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">search</span>
                            <input className="w-full rounded-lg border-0 bg-white/5 py-2.5 pl-10 pr-4 text-sm text-white placeholder-slate-400 ring-1 ring-transparent transition-all focus:bg-white/10 focus:ring-primary" placeholder="Cari produk (mis. Kopi Susu, Croissant)..." type="text" />
                        </div>
                        <div className="flex w-full items-center gap-2 overflow-x-auto pb-2 md:w-auto md:pb-0 hide-scrollbar">
                            <button className="whitespace-nowrap rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white shadow-md shadow-primary/20">Semua</button>
                            <button className="whitespace-nowrap rounded-lg bg-white/5 px-4 py-2 text-sm font-medium text-slate-300 hover:bg-white/10 hover:text-white transition-colors">Kopi</button>
                            <button className="whitespace-nowrap rounded-lg bg-white/5 px-4 py-2 text-sm font-medium text-slate-300 hover:bg-white/10 hover:text-white transition-colors">Non-Kopi</button>
                            <button className="whitespace-nowrap rounded-lg bg-white/5 px-4 py-2 text-sm font-medium text-slate-300 hover:bg-white/10 hover:text-white transition-colors">Pastry</button>
                            <button className="whitespace-nowrap rounded-lg bg-white/5 px-4 py-2 text-sm font-medium text-slate-300 hover:bg-white/10 hover:text-white transition-colors">Snack</button>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                        {isLoading ? <SkeletonCard count={6} /> : products.length === 0 ? (
                            <div className="col-span-full">
                                <EmptyState icon="restaurant_menu" title="Belum ada produk" description="Tambahkan produk pertama untuk memulai." />
                            </div>
                        ) : products.map(product => (
                            <div key={product.id} className="glass-card glass-panel group relative flex flex-col overflow-hidden rounded-2xl transition-all duration-300">
                                <div className="relative aspect-[4/3] w-full overflow-hidden bg-slate-800">
                                    <img alt={product.name} className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110" src={product.imageUrl ? `${API_BASE}${product.imageUrl}` : `https://ui-avatars.com/api/?name=${encodeURIComponent(product.name)}&background=1e293b&color=94a3b8&size=300`} />
                                    <div className="absolute right-2 top-2 rounded-md bg-black/60 px-2 py-1 text-xs font-semibold text-white backdrop-blur-sm">{product.category}</div>
                                    {product.isAI && (
                                        <div className="absolute left-2 top-2 flex items-center gap-1 rounded-md bg-purple-500/80 px-2 py-1 text-[10px] font-bold text-white backdrop-blur-sm shadow-lg shadow-purple-500/20">
                                            <span className="material-symbols-outlined text-[12px]">auto_awesome</span> Pilihan AI
                                        </div>
                                    )}
                                </div>
                                <div className="flex flex-1 flex-col p-4">
                                    <div className="flex justify-between items-start mb-2">
                                        <h3 className="text-lg font-bold text-white line-clamp-1" title={product.name}>{product.name}</h3>
                                        <button className="text-slate-400 hover:text-white opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer">
                                            <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                        </button>
                                    </div>
                                    <div className="flex items-center gap-2 mb-4">
                                        <span className="text-xl font-bold text-primary">Rp {product.price.toLocaleString('id-ID')}</span>
                                        {product.originalPrice && (
                                            <span className="text-xs text-slate-400 line-through">Rp {product.originalPrice.toLocaleString('id-ID')}</span>
                                        )}
                                    </div>
                                    <div className="mt-auto flex items-center justify-between border-t border-white/10 pt-3">
                                        <div className="flex items-center gap-1.5">
                                            {product.stockStatus === 'low' ? (
                                                <div className="h-2 w-2 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.5)]"></div>
                                            ) : product.stockStatus === 'out' ? (
                                                <div className="h-2 w-2 rounded-full bg-slate-500"></div>
                                            ) : (
                                                <div className="h-2 w-2 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"></div>
                                            )}
                                            <span className={`text-xs font-medium ${product.stockStatus === 'low' ? 'text-red-400' : product.stockStatus === 'out' ? 'text-slate-400' : 'text-slate-300'}`}>
                                                {product.stockStatus === 'low' ? `Stok Rendah: ${product.stock}` : product.stockStatus === 'out' ? 'Stok Habis' : `Stok: ${product.stock}`}
                                            </span>
                                        </div>
                                        <button
                                            className="rounded-lg bg-white/5 p-1.5 text-slate-400 hover:bg-white/10 hover:text-white transition-colors cursor-pointer"
                                            onClick={() => {
                                                setModalMode('edit');
                                                setSelectedProduct(product);
                                                setFormName(product.name || '');
                                                setFormPrice(product.price?.toString() || '');
                                                setFormCategory(product.category || '');
                                                setFormDescription(product.description || '');
                                                setImageFile(null);
                                                setImagePreview(product.imageUrl ? `${API_BASE}${product.imageUrl}` : null);
                                                setShowProductModal(true);
                                            }}
                                        >
                                            <span className="material-symbols-outlined text-[18px]">edit</span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* Modal */}
            {showProductModal && (
                <div key={modalMode === 'edit' && selectedProduct ? selectedProduct.id : 'add'} className="fixed inset-0 z-[60] flex items-center justify-center p-4 sm:p-6 bg-black/60 backdrop-blur-sm">
                    <div className="w-full max-w-[1000px] h-[90vh] flex flex-col glass-panel rounded-xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-300 bg-[#161c24]/95 border border-white/10">
                        <div className="flex items-center justify-between border-b border-white/10 px-6 py-4 bg-[#1c2127]/50">
                            <div className="flex flex-col gap-1">
                                <h2 className="text-xl font-bold text-white tracking-tight">{modalMode === 'edit' ? 'Ubah Produk' : 'Tambah Produk'}</h2>
                                <p className="text-sm text-slate-400">{modalMode === 'edit' ? 'Perbarui detail produk, harga, dan varian di seluruh cabang.' : 'Tambahkan produk baru ke dalam sistem dan atur ketersediaan.'}</p>
                            </div>
                            <button
                                className="rounded-full p-2 text-slate-400 hover:bg-white/10 hover:text-white transition-colors cursor-pointer"
                                onClick={() => setShowProductModal(false)}
                            >
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-6 lg:p-8 hide-scrollbar">
                            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                                <div className="lg:col-span-5 flex flex-col gap-6">
                                    <div className="flex flex-col gap-3">
                                        <label className="text-sm font-medium text-slate-300">Gambar Produk</label>
                                        <div className="group relative flex aspect-square w-full items-center justify-center overflow-hidden rounded-xl bg-[#1c2127] border border-dashed border-slate-600 hover:border-primary transition-colors cursor-pointer"
                                            onClick={() => fileInputRef.current?.click()}
                                        >
                                            <input
                                                ref={fileInputRef}
                                                type="file"
                                                accept="image/jpeg,image/png,image/gif,image/webp"
                                                className="hidden"
                                                onChange={(e) => {
                                                    const file = e.target.files?.[0];
                                                    if (file) {
                                                        setImageFile(file);
                                                        setImagePreview(URL.createObjectURL(file));
                                                    }
                                                }}
                                            />
                                            {(imagePreview || (modalMode === 'edit' && selectedProduct?.imageUrl)) ? (
                                                <div className="absolute inset-0 bg-center bg-cover opacity-60 group-hover:opacity-40 transition-opacity" style={{ backgroundImage: `url('${imagePreview || `${API_BASE}${selectedProduct?.imageUrl}`}')` }}></div>
                                            ) : null}
                                            <div className="relative z-10 flex flex-col items-center gap-2 text-slate-300 group-hover:text-white">
                                                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-black/50 backdrop-blur-md">
                                                    <span className="material-symbols-outlined text-2xl">photo_camera</span>
                                                </div>
                                                <span className="text-xs font-medium">{modalMode === 'edit' ? 'Ubah Gambar' : 'Tambah Gambar'}</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-4">
                                        <label className="flex flex-col gap-2">
                                            <span className="text-sm font-medium text-slate-300">Nama Produk</span>
                                            <input className="h-11 w-full rounded-lg border border-slate-700 bg-[#1c2127] px-4 text-sm text-white placeholder-slate-500 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none" type="text" value={formName} onChange={(e) => setFormName(e.target.value)} placeholder="Masukkan nama produk" />
                                        </label>
                                        <div className="grid grid-cols-2 gap-4">
                                            <label className="flex flex-col gap-2">
                                                <span className="text-sm font-medium text-slate-300">Harga Dasar (Rp)</span>
                                                <input className="h-11 w-full rounded-lg border border-slate-700 bg-[#1c2127] px-4 text-sm text-white placeholder-slate-500 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none" type="number" value={formPrice} onChange={(e) => setFormPrice(e.target.value)} placeholder="0" />
                                            </label>
                                            <label className="flex flex-col gap-2">
                                                <span className="text-sm font-medium text-slate-300">Kategori</span>
                                                <select className="h-11 w-full rounded-lg border border-slate-700 bg-[#1c2127] px-4 text-sm text-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none appearance-none cursor-pointer" value={formCategory} onChange={(e) => setFormCategory(e.target.value)}>
                                                    <option>Kopi</option>
                                                    <option>Non-Kopi</option>
                                                    <option>Teh</option>
                                                    <option>Dessert</option>
                                                    <option>Pastry</option>
                                                    <option>Snack</option>
                                                    <option>Merchandise</option>
                                                </select>
                                            </label>
                                        </div>
                                        <label className="flex flex-col gap-2">
                                            <div className="flex items-center justify-between">
                                                <span className="text-sm font-medium text-slate-300">Deskripsi</span>
                                                <button className="flex items-center gap-1 text-xs text-primary hover:text-blue-400 cursor-pointer">
                                                    <span className="material-symbols-outlined text-[14px]">auto_awesome</span>
                                                    Optimalkan dengan AI
                                                </button>
                                            </div>
                                            <textarea className="h-24 w-full resize-none rounded-lg border border-slate-700 bg-[#1c2127] p-3 text-sm text-white placeholder-slate-500 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none" value={formDescription} onChange={(e) => setFormDescription(e.target.value)} placeholder="Tulis deskripsi produk..."></textarea>
                                        </label>
                                    </div>
                                </div>
                                <div className="lg:col-span-7 flex flex-col gap-8">
                                    <div className="rounded-xl border border-white/5 bg-white/[0.02] p-5">
                                        <div className="flex items-center justify-between mb-4">
                                            <h3 className="text-base font-semibold text-white flex items-center gap-2">
                                                <span className="material-symbols-outlined text-primary text-xl">tune</span>
                                                Varian &amp; Modifikasi
                                            </h3>
                                            <button className="text-xs font-medium text-primary hover:text-blue-400 flex items-center gap-1 cursor-pointer">
                                                <span className="material-symbols-outlined text-sm">add</span>
                                                Tambah Opsi
                                            </button>
                                        </div>
                                        <div className="flex flex-col gap-3">
                                            {modalMode === 'edit' ? (
                                                <>
                                                    <div className="flex items-center gap-3 rounded-lg bg-[#1c2127] p-3 border border-transparent hover:border-slate-700 group transition-colors">
                                                        <span className="material-symbols-outlined text-slate-500 cursor-move">drag_indicator</span>
                                                        <div className="flex-1">
                                                            <p className="text-sm font-medium text-white">Ukuran: Besar</p>
                                                            <p className="text-xs text-slate-400">+ Rp 10.000</p>
                                                        </div>
                                                        <div className="flex items-center gap-2">
                                                            <span className="px-2 py-1 rounded bg-green-500/20 text-green-400 text-xs font-medium">Aktif</span>
                                                            <button className="p-1 text-slate-500 hover:text-white opacity-0 group-hover:opacity-100 transition-opacity">
                                                                <span className="material-symbols-outlined text-lg">edit</span>
                                                            </button>
                                                        </div>
                                                    </div>
                                                    <div className="flex items-center gap-3 rounded-lg bg-[#1c2127] p-3 border border-transparent hover:border-slate-700 group transition-colors">
                                                        <span className="material-symbols-outlined text-slate-500 cursor-move">drag_indicator</span>
                                                        <div className="flex-1">
                                                            <p className="text-sm font-medium text-white">Susu: Susu Oat</p>
                                                            <p className="text-xs text-slate-400">+ Rp 8.000</p>
                                                        </div>
                                                        <div className="flex items-center gap-2">
                                                            <span className="px-2 py-1 rounded bg-green-500/20 text-green-400 text-xs font-medium">Aktif</span>
                                                            <button className="p-1 text-slate-500 hover:text-white opacity-0 group-hover:opacity-100 transition-opacity">
                                                                <span className="material-symbols-outlined text-lg">edit</span>
                                                            </button>
                                                        </div>
                                                    </div>
                                                </>
                                            ) : (
                                                <div className="text-center p-6 border border-dashed border-slate-700 rounded-lg text-slate-500 text-sm bg-white/[0.01]">Belum ada varian ditambahkan</div>
                                            )}
                                        </div>
                                    </div>
                                    <div className="rounded-xl border border-white/5 bg-white/[0.02] p-5">
                                        <div className="flex items-center justify-between mb-4">
                                            <h3 className="text-base font-semibold text-white flex items-center gap-2">
                                                <span className="material-symbols-outlined text-primary text-xl">inventory_2</span>
                                                Pemetaan Inventaris
                                            </h3>
                                        </div>
                                        <div className="space-y-3">
                                            <p className="text-xs text-slate-400">Potong stok otomatis saat produk ini terjual.</p>
                                            <div className="flex gap-3">
                                                <div className="relative flex-1">
                                                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 material-symbols-outlined text-lg">search</span>
                                                    <input className="h-10 w-full rounded-lg border border-slate-700 bg-[#1c2127] pl-10 pr-4 text-sm text-white placeholder-slate-500 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none" placeholder="Cari bahan baku (misal: Biji Kopi)" type="text" />
                                                </div>
                                                <input className="h-10 w-20 rounded-lg border border-slate-700 bg-[#1c2127] px-3 text-sm text-white placeholder-slate-500 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none" placeholder="Jml" type="number" />
                                                <button className="h-10 px-4 rounded-lg bg-slate-700 hover:bg-slate-600 text-white text-sm font-medium transition-colors cursor-pointer">Hubungkan</button>
                                            </div>
                                            <div className="mt-2 flex flex-wrap gap-2 text-slate-300">
                                                {modalMode === 'edit' ? (
                                                    <>
                                                        <div className="inline-flex items-center gap-2 rounded-full border border-slate-700 bg-slate-800/50 px-3 py-1 text-xs text-slate-300 hover:border-slate-500 transition-colors">
                                                            <span>Biji Kopi Dark Roast (25g)</span>
                                                            <button className="hover:text-red-400"><span className="material-symbols-outlined text-[14px]">close</span></button>
                                                        </div>
                                                        <div className="inline-flex items-center gap-2 rounded-full border border-slate-700 bg-slate-800/50 px-3 py-1 text-xs text-slate-300 hover:border-slate-500 transition-colors">
                                                            <span>Gelas Kertas 12oz (1pc)</span>
                                                            <button className="hover:text-red-400"><span className="material-symbols-outlined text-[14px]">close</span></button>
                                                        </div>
                                                    </>
                                                ) : null}
                                            </div>
                                        </div>
                                    </div>
                                    <div className="rounded-xl border border-white/5 bg-white/[0.02] p-5">
                                        <div className="flex items-center justify-between mb-4">
                                            <h3 className="text-base font-semibold text-white flex items-center gap-2">
                                                <span className="material-symbols-outlined text-primary text-xl">store</span>
                                                Ketersediaan Cabang
                                            </h3>
                                            <div className="flex items-center gap-2">
                                                <label className="flex items-center gap-2 text-xs text-slate-400 cursor-pointer hover:text-white transition-colors">
                                                    <input defaultChecked className="rounded border-slate-700 bg-[#1c2127] text-primary focus:ring-offset-0 focus:ring-primary" type="checkbox" />
                                                    Pilih Semua
                                                </label>
                                            </div>
                                        </div>
                                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                            <label className="flex items-center gap-3 rounded-lg border border-slate-700/50 bg-[#1c2127]/50 p-3 cursor-pointer hover:bg-[#1c2127] transition-colors">
                                                <input defaultChecked className="h-4 w-4 rounded border-slate-600 bg-slate-800 text-primary focus:ring-offset-0 focus:ring-primary cursor-pointer" type="checkbox" />
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-medium text-white">Pusat Kota</span>
                                                    <span className="text-[10px] text-slate-400">Stok: {modalMode === 'edit' ? '45 unit' : '0 unit'}</span>
                                                </div>
                                            </label>
                                            <label className="flex items-center gap-3 rounded-lg border border-slate-700/50 bg-[#1c2127]/50 p-3 cursor-pointer hover:bg-[#1c2127] transition-colors">
                                                <input defaultChecked className="h-4 w-4 rounded border-slate-600 bg-slate-800 text-primary focus:ring-offset-0 focus:ring-primary cursor-pointer" type="checkbox" />
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-medium text-white">Kios Mall Barat</span>
                                                    <span className="text-[10px] text-slate-400">Stok: {modalMode === 'edit' ? '12 unit' : '0 unit'}</span>
                                                </div>
                                            </label>
                                            <label className="flex items-center gap-3 rounded-lg border border-slate-700/50 bg-[#1c2127]/50 p-3 cursor-pointer hover:bg-[#1c2127] transition-colors">
                                                <input className="h-4 w-4 rounded border-slate-600 bg-slate-800 text-primary focus:ring-offset-0 focus:ring-primary cursor-pointer" type="checkbox" />
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-medium text-slate-300">Terminal Bandara 2</span>
                                                    <span className="text-[10px] text-slate-500">Stok: {modalMode === 'edit' ? 'Stok Habis' : '0 unit'}</span>
                                                </div>
                                            </label>
                                            <label className="flex items-center gap-3 rounded-lg border border-slate-700/50 bg-[#1c2127]/50 p-3 cursor-pointer hover:bg-[#1c2127] transition-colors">
                                                <input defaultChecked className="h-4 w-4 rounded border-slate-600 bg-slate-800 text-primary focus:ring-offset-0 focus:ring-primary cursor-pointer" type="checkbox" />
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-medium text-white">Stasiun Utara</span>
                                                    <span className="text-[10px] text-slate-400">Stok: {modalMode === 'edit' ? '28 unit' : '0 unit'}</span>
                                                </div>
                                            </label>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="flex items-center justify-end gap-3 border-t border-white/10 bg-[#1c2127]/80 px-6 py-4 backdrop-blur-md">
                            <button
                                className="px-5 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:text-white hover:bg-white/5 transition-colors cursor-pointer"
                                onClick={() => setShowProductModal(false)}
                            >
                                Batal
                            </button>
                            <button
                                className="flex items-center justify-center gap-2 px-6 py-2.5 rounded-lg bg-primary text-white text-sm font-bold hover:bg-blue-600 shadow-lg shadow-blue-500/20 transition-all cursor-pointer disabled:opacity-50"
                                disabled={isSaving || !formName || !formPrice}
                                onClick={async () => {
                                    setIsSaving(true);
                                    try {
                                        let imageUrl = selectedProduct?.imageUrl || null;
                                        // Upload image if a new one was selected
                                        if (imageFile) {
                                            const uploadResult = await productsService.uploadImage(imageFile);
                                            imageUrl = uploadResult.imageUrl;
                                        }
                                        const productData = {
                                            name: formName,
                                            price: parseInt(formPrice),
                                            description: formDescription || null,
                                            imageUrl,
                                        };
                                        if (modalMode === 'edit' && selectedProduct) {
                                            await updateProduct.mutateAsync({ id: selectedProduct.id, data: productData });
                                        } else {
                                            await createProduct.mutateAsync(productData);
                                        }
                                        setShowProductModal(false);
                                    } catch (err) {
                                        console.error('Save failed:', err);
                                        alert('Gagal menyimpan produk: ' + err.message);
                                    } finally {
                                        setIsSaving(false);
                                    }
                                }}
                            >
                                <span className="material-symbols-outlined text-[18px]">save</span>
                                {isSaving ? 'Menyimpan...' : 'Simpan Produk'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}

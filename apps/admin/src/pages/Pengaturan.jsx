import React, { useState } from 'react';
import { usePaymentMethods, useTaxes, useCreatePaymentMethod, useUpdatePaymentMethod, useDeletePaymentMethod, useCreateTax, useUpdateTax, useDeleteTax, useSettings, useUpdateSettings } from '../hooks/useSettings';

export default function Pengaturan() {
    const [activeTab, setActiveTab] = useState('kustomisasi-struk');

    const { data: paymentMethods = [] } = usePaymentMethods();
    const createPaymentMethod = useCreatePaymentMethod();
    const updatePaymentMethod = useUpdatePaymentMethod();
    const deletePaymentMethod = useDeletePaymentMethod();
    const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
    const [currentPayment, setCurrentPayment] = useState(null);

    const { data: customTaxes = [] } = useTaxes();
    const createTax = useCreateTax();
    const updateTax = useUpdateTax();
    const deleteTax = useDeleteTax();
    const [isTaxModalOpen, setIsTaxModalOpen] = useState(false);
    const [currentTax, setCurrentTax] = useState(null);

    const [receiptConfig, setReceiptConfig] = useState({
        storeName: 'Kasir-AI Store',
        address: 'Jl. Teknologi No. 88, Jakarta Selatan, 12345',
        phone: '+62 812-3456-7890',
        showLogo: true,
        headerText: 'Selamat Datang',
        footerText: 'Terima kasih atas kunjungan Anda. Barang yang sudah dibeli tidak dapat ditukar.',
        taxRate: 11,
        serviceRate: 5
    });

    const handleReceiptChange = (e) => {
        const { name, value, type, checked } = e.target;
        setReceiptConfig({
            ...receiptConfig,
            [name]: type === 'checkbox' ? checked : value
        });
    };

    const handleTogglePayment = async (id) => {
        const pm = paymentMethods.find(p => p.id === id);
        if (pm) {
            try {
                await updatePaymentMethod.mutateAsync({ id, data: { ...pm, active: !pm.active } });
            } catch (err) {
                alert('Gagal: ' + err.message);
            }
        }
    };

    const handleDeletePayment = async (id) => {
        try {
            await deletePaymentMethod.mutateAsync(id);
            setIsPaymentModalOpen(false);
        } catch (err) {
            alert('Gagal menghapus: ' + err.message);
        }
    };

    const handleSavePayment = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const data = {
            name: formData.get('name'),
            description: formData.get('desc'),
            isActive: formData.get('active') === 'true',
        };

        try {
            if (currentPayment) {
                await updatePaymentMethod.mutateAsync({ id: currentPayment.id, data });
            } else {
                await createPaymentMethod.mutateAsync(data);
            }
            setIsPaymentModalOpen(false);
        } catch (err) {
            alert('Gagal menyimpan: ' + err.message);
        }
    };

    const handleSaveTax = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const data = {
            name: formData.get('name'),
            description: formData.get('desc'),
            rate: parseFloat(formData.get('rate')),
            isActive: formData.get('active') === 'true',
        };

        try {
            if (currentTax) {
                await updateTax.mutateAsync({ id: currentTax.id, data });
            } else {
                await createTax.mutateAsync(data);
            }
            setIsTaxModalOpen(false);
        } catch (err) {
            alert('Gagal menyimpan: ' + err.message);
        }
    };

    const handleDeleteTax = async (id) => {
        try {
            await deleteTax.mutateAsync(id);
            setIsTaxModalOpen(false);
        } catch (err) {
            alert('Gagal menghapus: ' + err.message);
        }
    };

    const openTaxModal = (tax = null) => {
        setCurrentTax(tax);
        setIsTaxModalOpen(true);
    };

    const openPaymentModal = (method = null) => {
        setCurrentPayment(method);
        setIsPaymentModalOpen(true);
    };

    return (
        <>
            <header className="flex-shrink-0 z-20 bg-[#101922]/80 backdrop-blur-md border-b border-white/10 pt-6 px-6 flex flex-col gap-6">
                <div className="flex flex-wrap items-center justify-between gap-4">
                    <div className="flex flex-col gap-1">
                        <h1 className="text-2xl font-bold text-white tracking-tight">
                            {activeTab === 'kustomisasi-struk' && 'Kustomisasi Struk'}
                            {activeTab === 'sistem-global' && 'Pengaturan Sistem Global'}
                            {activeTab === 'pajak-layanan' && 'Pengaturan Pajak & Layanan'}
                            {activeTab === 'metode-pembayaran' && 'Pengaturan Metode Pembayaran'}
                        </h1>
                        <p className="text-slate-400 text-sm">
                            {activeTab === 'kustomisasi-struk' && 'Sesuaikan tampilan struk belanja yang akan dicetak untuk pelanggan.'}
                            {activeTab === 'sistem-global' && 'Kelola konfigurasi toko, keamanan, dan integrasi Anda.'}
                            {activeTab === 'pajak-layanan' && 'Kelola aturan pajak, PPN, dan biaya layanan tambahan untuk transaksi.'}
                            {activeTab === 'metode-pembayaran' && 'Kelola integrasi pembayaran, dompet digital, dan mesin EDC.'}
                        </p>
                    </div>
                    <div className="flex items-center gap-3">
                        <button className="px-4 py-2 rounded-lg text-sm font-medium text-slate-300 hover:text-white hover:bg-white/5 transition-colors cursor-pointer">
                            {activeTab === 'kustomisasi-struk' ? 'Reset Default' : 'Batalkan'}
                        </button>
                        <button className="flex items-center gap-2 bg-primary hover:bg-blue-600 text-white px-5 py-2.5 rounded-lg text-sm font-bold shadow-lg shadow-primary/20 transition-all active:scale-95 cursor-pointer">
                            <span className="material-symbols-outlined text-[18px]">save</span>
                            {activeTab === 'kustomisasi-struk' ? 'Simpan Desain' : 'Simpan Semua Perubahan'}
                        </button>
                    </div>
                </div>
                <div className="flex items-center gap-6 overflow-x-auto hide-scrollbar text-sm font-medium">
                    <button
                        onClick={() => setActiveTab('sistem-global')}
                        className={`pb-3 px-1 whitespace-nowrap cursor-pointer transition-colors ${activeTab === 'sistem-global' ? 'text-primary border-b-2 border-primary' : 'text-slate-400 hover:text-white border-b-2 border-transparent'}`}
                    >
                        Sistem Global
                    </button>
                    <button
                        onClick={() => setActiveTab('kustomisasi-struk')}
                        className={`pb-3 px-1 whitespace-nowrap cursor-pointer transition-colors ${activeTab === 'kustomisasi-struk' ? 'text-primary border-b-2 border-primary' : 'text-slate-400 hover:text-white border-b-2 border-transparent'}`}
                    >
                        Kustomisasi Struk
                    </button>
                    <button
                        onClick={() => setActiveTab('pajak-layanan')}
                        className={`pb-3 px-1 whitespace-nowrap cursor-pointer transition-colors ${activeTab === 'pajak-layanan' ? 'text-primary border-b-2 border-primary' : 'text-slate-400 hover:text-white border-b-2 border-transparent'}`}
                    >
                        Pajak & Layanan
                    </button>
                    <button
                        onClick={() => setActiveTab('metode-pembayaran')}
                        className={`pb-3 px-1 whitespace-nowrap cursor-pointer transition-colors ${activeTab === 'metode-pembayaran' ? 'text-primary border-b-2 border-primary' : 'text-slate-400 hover:text-white border-b-2 border-transparent'}`}
                    >
                        Metode Pembayaran
                    </button>
                </div>
            </header>

            <div className="flex-1 overflow-y-auto p-6 md:p-8">
                {activeTab === 'sistem-global' && (
                    <div className="mx-auto max-w-6xl flex flex-col gap-6 pb-20">

                        {/* Konfigurasi Tampilan Struk */}
                        <div className="glass-panel rounded-xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 border border-white/10 bg-[#161b22]/50 shadow-sm">
                            <div className="flex items-center gap-4">
                                <div className="size-12 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
                                    <span className="material-symbols-outlined">receipt_long</span>
                                </div>
                                <div className="flex flex-col">
                                    <h3 className="text-base font-bold text-white">Konfigurasi Tampilan Struk</h3>
                                    <p className="text-sm text-slate-400">Sesuaikan logo, footer, dan format struk belanja pelanggan Anda.</p>
                                </div>
                            </div>
                            <button className="px-4 py-2 rounded-full border border-white/10 text-sm font-medium text-slate-300 hover:text-white hover:bg-white/5 transition-colors flex items-center gap-2 w-fit cursor-pointer">
                                Buka Pengaturan
                                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
                            </button>
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

                            {/* Umum */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center gap-4 mb-2">
                                    <div className="size-10 rounded-xl bg-[#161b22] border border-white/5 flex items-center justify-center text-blue-400">
                                        <span className="material-symbols-outlined text-[20px]">tune</span>
                                    </div>
                                    <h2 className="text-lg font-bold text-white">Umum</h2>
                                </div>
                                <div className="space-y-5">
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Nama Aplikasi</label>
                                        <input className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all" type="text" defaultValue="Kasir-AI" />
                                        <p className="text-xs text-slate-500">Terlihat di tab browser dan faktur.</p>
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Logo Toko</label>
                                        <div className="border-2 border-dashed border-white/10 rounded-xl p-6 flex flex-col items-center justify-center bg-white/5 hover:bg-white/10 hover:border-slate-500 transition-colors cursor-pointer group">
                                            <div className="size-12 rounded-full bg-slate-800 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                                                <span className="material-symbols-outlined text-slate-400">cloud_upload</span>
                                            </div>
                                            <p className="text-sm text-slate-300 font-medium">Klik untuk unggah atau seret dan lepas</p>
                                            <p className="text-xs text-slate-500 mt-1">SVG, PNG, JPG (maks. 800x400px)</p>
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Mata Uang Default</label>
                                        <div className="grid grid-cols-2 gap-3">
                                            <label className="cursor-pointer relative">
                                                <input defaultChecked className="peer sr-only" name="currency" type="radio" />
                                                <div className="flex items-center justify-center gap-2 p-3 rounded-lg border border-white/10 bg-[#111418] text-slate-400 peer-checked:border-primary peer-checked:bg-primary/10 peer-checked:text-primary transition-all">
                                                    <span className="font-bold">IDR (Rp)</span>
                                                </div>
                                            </label>
                                            <label className="cursor-pointer relative">
                                                <input className="peer sr-only" name="currency" type="radio" />
                                                <div className="flex items-center justify-center gap-2 p-3 rounded-lg border border-white/10 bg-[#111418] text-slate-400 peer-checked:border-primary peer-checked:bg-primary/10 peer-checked:text-primary transition-all">
                                                    <span className="font-bold">USD ($)</span>
                                                </div>
                                            </label>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Lokalisasi */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center gap-4 mb-2">
                                    <div className="size-10 rounded-xl bg-[#161b22] border border-white/5 flex items-center justify-center text-emerald-400">
                                        <span className="material-symbols-outlined text-[20px]">public</span>
                                    </div>
                                    <h2 className="text-lg font-bold text-white">Lokalisasi</h2>
                                </div>
                                <div className="space-y-5">
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Zona Waktu</label>
                                        <div className="relative">
                                            <select className="w-full appearance-none bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all cursor-pointer">
                                                <option defaultValue="Asia/Jakarta">Asia/Jakarta (WIB)</option>
                                                <option value="Asia/Makassar">Asia/Makassar (WITA)</option>
                                                <option value="Asia/Jayapura">Asia/Jayapura (WIT)</option>
                                                <option value="UTC">UTC (GMT+00:00)</option>
                                            </select>
                                            <span className="material-symbols-outlined absolute right-3 top-2.5 text-slate-500 pointer-events-none">expand_more</span>
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Format Tanggal</label>
                                        <div className="relative">
                                            <select className="w-full appearance-none bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all cursor-pointer">
                                                <option defaultValue="DD/MM/YYYY">DD/MM/YYYY (31/12/2023)</option>
                                                <option value="MM/DD/YYYY">MM/DD/YYYY (12/31/2023)</option>
                                                <option value="YYYY-MM-DD">YYYY-MM-DD (2023-12-31)</option>
                                            </select>
                                            <span className="material-symbols-outlined absolute right-3 top-2.5 text-slate-500 pointer-events-none">expand_more</span>
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Bahasa Sistem</label>
                                        <div className="flex items-center gap-3 p-3 rounded-lg border border-white/10 bg-white/5">
                                            <div className="flex items-center justify-center size-8 bg-slate-800 rounded-full text-xs font-bold text-white border border-slate-600">ID</div>
                                            <div className="flex-1">
                                                <p className="text-sm font-medium text-white">Bahasa Indonesia</p>
                                                <p className="text-xs text-slate-400">Bahasa default untuk semua pengguna</p>
                                            </div>
                                            <button className="text-primary text-sm font-medium hover:underline">Ubah</button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Keamanan */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center gap-4 mb-2">
                                    <div className="size-10 rounded-xl bg-[#161b22] border border-white/5 flex items-center justify-center text-orange-400">
                                        <span className="material-symbols-outlined text-[20px]">security</span>
                                    </div>
                                    <h2 className="text-lg font-bold text-white">Keamanan</h2>
                                </div>
                                <div className="space-y-6">
                                    <div className="flex items-center justify-between">
                                        <div className="flex flex-col gap-1">
                                            <label className="text-sm font-medium text-white">Autentikasi Dua Faktor</label>
                                            <p className="text-xs text-slate-500 max-w-[250px]">Wajibkan 2FA untuk semua akun admin saat login.</p>
                                        </div>
                                        <label className="relative inline-flex items-center cursor-pointer">
                                            <input className="sr-only peer" type="checkbox" value="" />
                                            <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                        </label>
                                    </div>
                                    <div className="border-t border-white/10 my-2"></div>
                                    <div className="flex flex-col gap-4">
                                        <div className="flex justify-between items-center">
                                            <label className="text-sm font-medium text-slate-300">Batas Waktu Sesi</label>
                                            <span className="text-sm font-bold text-primary bg-primary/10 px-2 py-0.5 rounded">30 mnt</span>
                                        </div>
                                        <input className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-primary" max="120" min="5" type="range" defaultValue="30" />
                                        <div className="flex justify-between text-xs text-slate-500">
                                            <span>5m</span>
                                            <span>1j</span>
                                            <span>2j</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Integrasi */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center gap-4 mb-2">
                                    <div className="size-10 rounded-xl bg-[#161b22] border border-white/5 flex items-center justify-center text-purple-400">
                                        <span className="material-symbols-outlined text-[20px]">hub</span>
                                    </div>
                                    <h2 className="text-lg font-bold text-white">Integrasi</h2>
                                </div>
                                <div className="space-y-6">
                                    <div className="flex flex-col gap-3">
                                        <label className="text-sm font-medium text-slate-300 flex items-center justify-between">
                                            Gerbang Pembayaran (Midtrans)
                                            <span className="text-xs text-emerald-400 bg-emerald-400/10 px-2 py-0.5 rounded flex items-center gap-1">
                                                <span className="size-1.5 rounded-full bg-emerald-400"></span> Terhubung
                                            </span>
                                        </label>
                                        <div className="relative group">
                                            <span className="absolute left-3 top-2.5 material-symbols-outlined text-slate-500 text-[20px]">key</span>
                                            <input className="w-full pl-10 pr-10 bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-slate-400 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all" readOnly type="password" defaultValue="SB-Mid-server-x8s7d6f876sd8f76s" />
                                            <button className="absolute right-3 top-2.5 text-slate-500 hover:text-white transition-colors">
                                                <span className="material-symbols-outlined text-[20px]">visibility_off</span>
                                            </button>
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-3">
                                        <label className="text-sm font-medium text-slate-300 flex items-center justify-between">
                                            Gerbang Pembayaran (Xendit)
                                            <span className="text-xs text-slate-400 bg-white/10 px-2 py-0.5 rounded">Belum Dikonfigurasi</span>
                                        </label>
                                        <div className="relative group">
                                            <span className="absolute left-3 top-2.5 material-symbols-outlined text-slate-500 text-[20px]">key</span>
                                            <input className="w-full pl-10 bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all" placeholder="Masukkan Kunci API Rahasia Xendit" type="text" />
                                        </div>
                                    </div>
                                    <div className="border-t border-white/10 my-2"></div>
                                    <div className="flex items-center justify-between">
                                        <div className="flex flex-col gap-1">
                                            <div className="flex items-center gap-2">
                                                <span className="material-symbols-outlined text-green-500 text-[20px]">chat</span>
                                                <label className="text-sm font-medium text-white">Notifikasi WhatsApp</label>
                                            </div>
                                            <p className="text-xs text-slate-500 max-w-[250px]">Kirim struk digital secara otomatis via WA.</p>
                                        </div>
                                        <label className="relative inline-flex items-center cursor-pointer">
                                            <input defaultChecked className="sr-only peer" type="checkbox" value="" />
                                            <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {activeTab === 'kustomisasi-struk' && (
                    <div className="mx-auto max-w-7xl h-full pb-20">
                        <div className="flex flex-col lg:flex-row gap-8 h-full">
                            <div className="w-full lg:w-[60%] flex flex-col gap-6 pb-20">

                                <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                    <div className="flex items-center gap-3 border-b border-white/10 pb-4">
                                        <div className="p-2 rounded-lg bg-blue-500/10 text-blue-400">
                                            <span className="material-symbols-outlined">storefront</span>
                                        </div>
                                        <h2 className="text-lg font-bold text-white">Informasi Bisnis</h2>
                                    </div>
                                    <div className="space-y-4">
                                        <div className="flex flex-col gap-2">
                                            <label className="text-sm font-medium text-slate-300">Nama Toko</label>
                                            <input
                                                name="storeName"
                                                value={receiptConfig.storeName}
                                                onChange={handleReceiptChange}
                                                className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                                type="text"
                                            />
                                        </div>
                                        <div className="flex flex-col gap-2">
                                            <label className="text-sm font-medium text-slate-300">Alamat Lengkap</label>
                                            <textarea
                                                name="address"
                                                value={receiptConfig.address}
                                                onChange={handleReceiptChange}
                                                className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all resize-none h-24"
                                            />
                                        </div>
                                        <div className="flex flex-col gap-2">
                                            <label className="text-sm font-medium text-slate-300">Nomor Telepon</label>
                                            <input
                                                name="phone"
                                                value={receiptConfig.phone}
                                                onChange={handleReceiptChange}
                                                className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                                type="tel"
                                            />
                                        </div>
                                    </div>
                                </div>

                                <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                    <div className="flex items-center gap-3 border-b border-white/10 pb-4">
                                        <div className="p-2 rounded-lg bg-emerald-500/10 text-emerald-400">
                                            <span className="material-symbols-outlined">article</span>
                                        </div>
                                        <h2 className="text-lg font-bold text-white">Konten Struk</h2>
                                    </div>
                                    <div className="space-y-5">
                                        <div className="flex items-center justify-between p-4 rounded-lg bg-slate-900/30 border border-slate-800">
                                            <div className="flex flex-col gap-1">
                                                <span className="text-sm font-medium text-white">Tampilkan Logo</span>
                                                <span className="text-xs text-slate-500">Logo toko akan muncul di bagian atas struk</span>
                                            </div>
                                            <label className="relative inline-flex items-center cursor-pointer">
                                                <input
                                                    name="showLogo"
                                                    checked={receiptConfig.showLogo}
                                                    onChange={handleReceiptChange}
                                                    className="sr-only peer"
                                                    type="checkbox"
                                                />
                                                <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                            </label>
                                        </div>
                                        <div className="flex flex-col gap-2">
                                            <label className="text-sm font-medium text-slate-300">Teks Header</label>
                                            <input
                                                name="headerText"
                                                value={receiptConfig.headerText}
                                                onChange={handleReceiptChange}
                                                className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                                type="text"
                                            />
                                            <p className="text-xs text-slate-500">Teks singkat di bawah info toko.</p>
                                        </div>
                                        <div className="flex flex-col gap-2">
                                            <label className="text-sm font-medium text-slate-300">Pesan Footer</label>
                                            <textarea
                                                name="footerText"
                                                value={receiptConfig.footerText}
                                                onChange={handleReceiptChange}
                                                className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all resize-none h-20"
                                            />
                                            <p className="text-xs text-slate-500">Pesan penutup di bagian paling bawah struk.</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                    <div className="flex items-center gap-3 border-b border-white/10 pb-4">
                                        <div className="p-2 rounded-lg bg-purple-500/10 text-purple-400">
                                            <span className="material-symbols-outlined">calculate</span>
                                        </div>
                                        <h2 className="text-lg font-bold text-white">Pengaturan Tambahan</h2>
                                    </div>
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                        <div className="flex flex-col gap-2">
                                            <label className="text-sm font-medium text-slate-300">Pajak (PPN) %</label>
                                            <div className="relative">
                                                <input
                                                    name="taxRate"
                                                    value={receiptConfig.taxRate}
                                                    onChange={handleReceiptChange}
                                                    className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                                    type="number"
                                                />
                                                <span className="absolute right-4 top-2.5 text-slate-500 font-medium">%</span>
                                            </div>
                                        </div>
                                        <div className="flex flex-col gap-2">
                                            <label className="text-sm font-medium text-slate-300">Biaya Layanan %</label>
                                            <div className="relative">
                                                <input
                                                    name="serviceRate"
                                                    value={receiptConfig.serviceRate}
                                                    onChange={handleReceiptChange}
                                                    className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                                    type="number"
                                                />
                                                <span className="absolute right-4 top-2.5 text-slate-500 font-medium">%</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                            </div>

                            <div className="w-full lg:w-[40%] flex flex-col gap-4">
                                <div className="flex items-center justify-between mb-2">
                                    <h3 className="text-lg font-bold text-white">Pratinjau Struk</h3>
                                    <span className="text-xs bg-emerald-500/10 text-emerald-400 px-2 py-1 rounded border border-emerald-500/20 animate-pulse">Live Update</span>
                                </div>
                                <div className="glass-panel rounded-xl p-8 flex flex-col items-center shadow-2xl relative overflow-hidden receipt-pattern min-h-[600px] text-white font-mono">
                                    <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-b from-[#111418] to-transparent opacity-20"></div>

                                    <div className="flex flex-col items-center gap-1 w-full mt-4">
                                        {receiptConfig.showLogo && (
                                            <div className="size-12 rounded-full bg-slate-800 flex items-center justify-center mb-2 shadow-inner border border-white/10">
                                                <span className="material-symbols-outlined text-slate-400 text-[20px]">storefront</span>
                                            </div>
                                        )}
                                        <h4 className="text-lg font-black tracking-widest uppercase text-white drop-shadow-md text-center">
                                            {receiptConfig.storeName || 'KASIR-AI STORE'}
                                        </h4>
                                        <p className="text-xs text-slate-400 max-w-[80%] text-center uppercase tracking-wider whitespace-pre-line">
                                            {receiptConfig.address || 'JL. TEKNOLOGI NO. 88\nJAKARTA SELATAN'}
                                        </p>
                                        <p className="text-xs text-slate-400 uppercase tracking-wider">{receiptConfig.phone || '+62 812-3456-7890'}</p>
                                    </div>

                                    <div className="w-full border-t-2 border-dashed border-slate-600 my-4"></div>
                                    <p className="text-sm font-bold text-center uppercase tracking-widest mb-4 opacity-90">{receiptConfig.headerText || 'SELAMAT DATANG'}</p>

                                    <div className="w-full flex justify-between text-xs text-slate-400 mb-6 px-2">
                                        <div className="flex flex-col">
                                            <span>Tanggal: 24/10/2023</span>
                                            <span>Waktu: 14:30 WIB</span>
                                        </div>
                                        <div className="flex flex-col text-right">
                                            <span>Kasir: Admin</span>
                                            <span>Order: #INV-001</span>
                                        </div>
                                    </div>

                                    <div className="w-full flex flex-col gap-3 text-sm px-2">
                                        <div className="flex justify-between items-start">
                                            <div className="flex flex-col">
                                                <span className="font-bold">Nasi Goreng Spesial</span>
                                                <span className="text-xs text-slate-400">2x @ Rp 35.000</span>
                                            </div>
                                            <span>Rp 70.000</span>
                                        </div>
                                        <div className="flex justify-between items-start">
                                            <div className="flex flex-col">
                                                <span className="font-bold">Es Teh Manis</span>
                                                <span className="text-xs text-slate-400">5x @ Rp 5.000</span>
                                            </div>
                                            <span>Rp 25.000</span>
                                        </div>
                                    </div>

                                    <div className="w-full border-t border-slate-700 my-4"></div>

                                    <div className="w-full flex flex-col gap-1.5 px-2">
                                        <div className="flex justify-between text-slate-300">
                                            <span>Subtotal</span>
                                            <span>Rp 95.000</span>
                                        </div>
                                        {receiptConfig.serviceRate > 0 && (
                                            <div className="flex justify-between text-slate-300">
                                                <span>Biaya Layanan ({receiptConfig.serviceRate}%)</span>
                                                <span>Rp {(95000 * (receiptConfig.serviceRate / 100)).toLocaleString('id-ID')}</span>
                                            </div>
                                        )}
                                        {receiptConfig.taxRate > 0 && (
                                            <div className="flex justify-between text-slate-300">
                                                <span>Pajak ({receiptConfig.taxRate}%)</span>
                                                <span>Rp {((95000 + (95000 * (receiptConfig.serviceRate / 100))) * (receiptConfig.taxRate / 100)).toLocaleString('id-ID')}</span>
                                            </div>
                                        )}
                                        <div className="w-full border-t border-slate-700 my-1"></div>
                                        <div className="flex justify-between font-bold text-lg mt-1">
                                            <span>Total</span>
                                            <span>Rp {(95000 + (95000 * (receiptConfig.serviceRate / 100)) + ((95000 + (95000 * (receiptConfig.serviceRate / 100))) * (receiptConfig.taxRate / 100))).toLocaleString('id-ID')}</span>
                                        </div>
                                        <div className="flex justify-between text-slate-300 text-xs mt-2">
                                            <span>Tunai</span>
                                            <span>Rp 150.000</span>
                                        </div>
                                        <div className="flex justify-between text-slate-300 text-xs">
                                            <span>Kembali</span>
                                            <span>Rp {(150000 - (95000 + (95000 * (receiptConfig.serviceRate / 100)) + ((95000 + (95000 * (receiptConfig.serviceRate / 100))) * (receiptConfig.taxRate / 100)))).toLocaleString('id-ID')}</span>
                                        </div>
                                    </div>

                                    <div className="w-full border-t-2 border-dashed border-slate-600 my-4"></div>
                                    <p className="text-xs text-center text-slate-400 leading-relaxed whitespace-pre-line px-4">
                                        {receiptConfig.footerText || 'Terima kasih atas kunjungan Anda.\nBarang yang sudah dibeli tidak dapat ditukar.'}
                                    </p>

                                    <div className="mt-8 flex flex-col items-center gap-1">
                                        <span className="material-symbols-outlined text-4xl text-slate-600">qr_code_2</span>
                                        <span className="text-[10px] text-slate-600">Scan untuk struk digital</span>
                                    </div>

                                    <div className="receipt-jagged-edge"></div>
                                    <div className="absolute bottom-0 left-0 w-full h-2 bg-gradient-to-t from-[#111418] to-transparent opacity-20"></div>
                                </div>
                            </div>

                        </div>
                    </div>
                )}

                {activeTab === 'pajak-layanan' && (
                    <div className="mx-auto max-w-6xl flex flex-col gap-6 pb-20">

                        {/* Perhitungan Pajak Otomatis Banner */}
                        <div className="glass-panel rounded-xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 border border-white/10 bg-[#161b22]/50 shadow-sm">
                            <div className="flex items-center gap-4">
                                <div className="size-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
                                    <span className="material-symbols-outlined">calculate</span>
                                </div>
                                <div className="flex flex-col">
                                    <h3 className="text-base font-bold text-white">Perhitungan Pajak Otomatis</h3>
                                    <p className="text-sm text-slate-400">Sistem akan otomatis menghitung pajak pada saat checkout berdasarkan pengaturan ini.</p>
                                </div>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

                            {/* PPN */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center justify-between border-b border-white/10 pb-4">
                                    <div className="flex items-center gap-4">
                                        <div className="size-10 rounded-xl bg-blue-500/10 flex items-center justify-center text-blue-400">
                                            <span className="material-symbols-outlined text-[20px]">percent</span>
                                        </div>
                                        <h2 className="text-lg font-bold text-white">Pajak Pertambahan Nilai (PPN)</h2>
                                    </div>
                                    <label className="relative inline-flex items-center cursor-pointer">
                                        <input defaultChecked className="sr-only peer" type="checkbox" value="" />
                                        <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                    </label>
                                </div>
                                <div className="flex flex-col gap-4">
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Nama Pajak</label>
                                        <input className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all" type="text" defaultValue="PPN" />
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Persentase (%)</label>
                                        <div className="relative">
                                            <input className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all" type="number" defaultValue="11" />
                                            <span className="absolute right-4 top-2.5 text-slate-500 font-medium">%</span>
                                        </div>
                                        <p className="text-xs text-slate-500">Berlaku untuk semua produk kena pajak.</p>
                                    </div>
                                </div>
                            </div>

                            {/* Biaya Layanan */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center justify-between border-b border-white/10 pb-4">
                                    <div className="flex items-center gap-4">
                                        <div className="size-10 rounded-xl bg-purple-500/10 flex items-center justify-center text-purple-400">
                                            <span className="material-symbols-outlined text-[20px]">room_service</span>
                                        </div>
                                        <h2 className="text-lg font-bold text-white">Biaya Layanan (Service Charge)</h2>
                                    </div>
                                    <label className="relative inline-flex items-center cursor-pointer">
                                        <input className="sr-only peer" type="checkbox" value="" />
                                        <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                    </label>
                                </div>
                                <div className="flex flex-col gap-4">
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Label Biaya</label>
                                        <input className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all" type="text" defaultValue="Service Charge" />
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Persentase (%)</label>
                                        <div className="relative">
                                            <input className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all" type="number" defaultValue="5" />
                                            <span className="absolute right-4 top-2.5 text-slate-500 font-medium">%</span>
                                        </div>
                                        <p className="text-xs text-slate-500">Biasanya diterapkan untuk layanan dine-in.</p>
                                    </div>
                                </div>
                            </div>

                            {/* Logika Perhitungan Pajak */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center gap-4 mb-2">
                                    <div className="size-10 rounded-xl bg-yellow-500/10 flex items-center justify-center text-yellow-500">
                                        <span className="material-symbols-outlined text-[20px]">functions</span>
                                    </div>
                                    <h2 className="text-lg font-bold text-white">Logika Perhitungan Pajak</h2>
                                </div>
                                <div className="flex flex-col gap-4">
                                    <label className="cursor-pointer relative">
                                        <input defaultChecked className="peer sr-only" name="taxLogic" type="radio" value="eksklusif" />
                                        <div className="p-4 rounded-xl border border-white/10 bg-[#111418] peer-checked:border-primary peer-checked:bg-primary/5 transition-all">
                                            <div className="flex items-start gap-3">
                                                <div className="mt-0.5 w-4 h-4 rounded-full border border-slate-500 peer-checked:border-primary peer-checked:border-4 transition-all"></div>
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-bold text-white mb-1">Harga Eksklusif Pajak</span>
                                                    <span className="text-xs text-slate-400 mb-3">Harga produk belum termasuk pajak. Pajak akan ditambahkan di akhir pada total transaksi.</span>
                                                    <span className="text-[11px] font-mono text-emerald-400 bg-emerald-400/10 px-2 py-1 rounded w-fit">Harga Rp10.000 + PPN 11% = Total Rp11.100</span>
                                                </div>
                                            </div>
                                        </div>
                                    </label>
                                    <label className="cursor-pointer relative">
                                        <input className="peer sr-only" name="taxLogic" type="radio" value="inklusif" />
                                        <div className="p-4 rounded-xl border border-white/10 bg-[#111418] peer-checked:border-primary peer-checked:bg-primary/5 transition-all">
                                            <div className="flex items-start gap-3">
                                                <div className="mt-0.5 w-4 h-4 rounded-full border border-slate-500 peer-checked:border-primary peer-checked:border-4 transition-all"></div>
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-bold text-white mb-1">Harga Inklusif Pajak</span>
                                                    <span className="text-xs text-slate-400 mb-3">Harga produk sudah termasuk pajak. Sistem akan menghitung mundur nilai pajak dari harga jual.</span>
                                                    <span className="text-[11px] font-mono text-blue-400 bg-blue-400/10 px-2 py-1 rounded w-fit">Harga Rp11.100 (termasuk PPN) = Total Rp11.100</span>
                                                </div>
                                            </div>
                                        </div>
                                    </label>
                                </div>
                            </div>

                            {/* Pajak Kustom */}
                            <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                                <div className="flex items-center justify-between mb-2">
                                    <div className="flex items-center gap-4">
                                        <div className="size-10 rounded-xl bg-pink-500/10 flex items-center justify-center text-pink-500">
                                            <span className="material-symbols-outlined text-[20px]">local_offer</span>
                                        </div>
                                        <h2 className="text-lg font-bold text-white">Pajak Kustom</h2>
                                    </div>
                                    <button
                                        onClick={() => openTaxModal(null)}
                                        className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-slate-300 border border-white/10 rounded-full hover:bg-white/5 hover:text-white transition-colors cursor-pointer"
                                    >
                                        <span className="material-symbols-outlined text-[14px]">add</span>
                                        Tambah Baru
                                    </button>
                                </div>
                                <div className="flex flex-col gap-3">
                                    {customTaxes.map((tax) => (
                                        <div key={tax.id} className={`flex items-center justify-between p-4 bg-[#111418] border border-white/10 rounded-xl transition-all ${!tax.active && 'opacity-60 hover:opacity-100 bg-[#161b22]'}`}>
                                            <div className="flex flex-col gap-1">
                                                <span className="text-sm font-bold text-white">{tax.name}</span>
                                                <span className="text-xs text-slate-400">{tax.desc} {tax.rate}%</span>
                                            </div>
                                            <div className="flex items-center gap-3">
                                                {tax.active ? (
                                                    <span className="text-xs font-bold text-emerald-400 bg-emerald-400/10 px-2 py-0.5 rounded">Aktif</span>
                                                ) : (
                                                    <span className="text-xs font-bold text-slate-400 bg-white/5 px-2 py-0.5 rounded">Nonaktif</span>
                                                )}
                                                <button
                                                    onClick={() => openTaxModal(tax)}
                                                    className="text-slate-500 hover:text-white transition-colors cursor-pointer"
                                                >
                                                    <span className="material-symbols-outlined text-[18px]">edit</span>
                                                </button>
                                            </div>
                                        </div>
                                    ))}
                                    <p className="text-xs text-slate-500 text-center mt-2">Pajak kustom dapat diterapkan pada kategori produk tertentu.</p>
                                </div>
                            </div>

                        </div>
                    </div>
                )}

                {activeTab === 'metode-pembayaran' && (
                    <div className="mx-auto max-w-4xl flex flex-col gap-6 pb-20">

                        {/* Pembayaran Terintegrasi */}
                        <div className="glass-panel rounded-xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 border border-white/10 bg-[#161b22]/50 shadow-sm">
                            <div className="flex items-center gap-4">
                                <div className="size-12 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
                                    <span className="material-symbols-outlined">account_balance_wallet</span>
                                </div>
                                <div className="flex flex-col">
                                    <h3 className="text-base font-bold text-white">Pembayaran Terintegrasi</h3>
                                    <p className="text-sm text-slate-400">Aktifkan pembayaran digital untuk transaksi non-tunai yang lebih cepat.</p>
                                </div>
                            </div>
                            <button
                                onClick={() => openPaymentModal(null)}
                                className="px-4 py-2 rounded-full border border-white/10 text-sm font-medium text-slate-300 hover:text-white hover:bg-white/5 transition-colors flex items-center gap-2 w-fit cursor-pointer"
                            >
                                <span className="material-symbols-outlined text-[16px]">add_card</span>
                                Tambah Metode Baru
                            </button>
                        </div>

                        {/* Pembayaran Tunai */}
                        <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-4">
                                    <div className="size-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-400">
                                        <span className="material-symbols-outlined text-[20px]">payments</span>
                                    </div>
                                    <h2 className="text-lg font-bold text-white">Pembayaran Tunai</h2>
                                </div>
                                <label className="relative inline-flex items-center cursor-pointer">
                                    <input defaultChecked className="sr-only peer" type="checkbox" value="" />
                                    <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-emerald-500/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                                </label>
                            </div>
                            <div className="border-t border-white/10 mt-2"></div>
                            <div className="flex flex-col gap-1 text-sm text-slate-400">
                                <p>Mengaktifkan opsi pembayaran tunai pada halaman checkout.</p>
                                <p>Mendukung perhitungan kembalian otomatis.</p>
                            </div>
                        </div>

                        {/* Dompet Digital */}
                        <div className="glass-panel rounded-xl p-6 flex flex-col gap-6">
                            <div className="flex items-center justify-between mb-2">
                                <div className="flex items-center gap-4">
                                    <div className="size-10 rounded-xl bg-purple-500/10 flex items-center justify-center text-purple-400">
                                        <span className="material-symbols-outlined text-[20px]">account_balance_wallet</span>
                                    </div>
                                    <h2 className="text-lg font-bold text-white">Dompet Digital</h2>
                                </div>
                                <span className="text-xs font-medium text-slate-400 bg-white/5 px-2.5 py-1 rounded">API Terhubung</span>
                            </div>

                            <div className="flex flex-col gap-4">
                                {paymentMethods.map((method) => (
                                    <div key={method.id} className={`flex items-center justify-between p-4 bg-[#111418] border border-white/10 rounded-xl transition-all hover:border-slate-500 ${!method.active && 'opacity-60 hover:opacity-100'}`}>
                                        <div className="flex items-center gap-4">
                                            <div className={`w-12 h-12 ${method.logoBg} rounded-lg flex items-center justify-center p-2`}>
                                                <span className={`${method.logoSize} ${method.logoColor} tracking-tighter`}>{method.logoText}</span>
                                            </div>
                                            <div className="flex flex-col gap-0.5">
                                                <span className="text-base font-bold text-white">{method.name}</span>
                                                <span className="text-sm text-slate-400">{method.desc}</span>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-5">
                                            {method.active ? (
                                                <span className="text-xs font-bold text-emerald-400 bg-emerald-400/10 px-2 py-0.5 rounded">Aktif</span>
                                            ) : (
                                                <span className="text-xs font-bold text-slate-400 bg-white/5 px-2 py-0.5 rounded">Nonaktif</span>
                                            )}
                                            <label className="relative inline-flex items-center cursor-pointer">
                                                <input
                                                    checked={method.active}
                                                    onChange={() => handleTogglePayment(method.id)}
                                                    className="sr-only peer"
                                                    type="checkbox"
                                                />
                                                <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                            </label>
                                            <button
                                                onClick={() => openPaymentModal(method)}
                                                className="text-slate-500 hover:text-white transition-colors cursor-pointer"
                                            >
                                                <span className="material-symbols-outlined text-[20px]">settings</span>
                                            </button>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>

                    </div>
                )}
            </div >

            {/* Modal Tambah/Edit Metode Pembayaran */}
            {isPaymentModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-[#161b22] border border-white/10 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl animate-in fade-in zoom-in duration-200">
                        <div className="flex items-center justify-between p-6 border-b border-white/10 bg-white/5">
                            <h2 className="text-xl font-bold text-white">
                                {currentPayment ? 'Edit Metode Pembayaran' : 'Tambah Metode Baru'}
                            </h2>
                            <button
                                onClick={() => setIsPaymentModalOpen(false)}
                                className="text-slate-400 hover:text-white transition-colors cursor-pointer"
                            >
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>
                        <form onSubmit={handleSavePayment} className="p-6 flex flex-col gap-5">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium text-slate-300">Nama Metode</label>
                                <input
                                    name="name"
                                    type="text"
                                    required
                                    defaultValue={currentPayment?.name || ''}
                                    className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                    placeholder="Contoh: ShopeePay"
                                />
                            </div>
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium text-slate-300">Deskripsi/Keterangan</label>
                                <input
                                    name="desc"
                                    type="text"
                                    required
                                    defaultValue={currentPayment?.desc || ''}
                                    className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                    placeholder="Contoh: Pembayaran e-wallet"
                                />
                            </div>
                            <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/10 mt-2">
                                <div className="flex flex-col gap-0.5">
                                    <span className="text-sm font-bold text-white">Status Aktif</span>
                                    <span className="text-xs text-slate-400">Aktifkan metode ini saat checkout</span>
                                </div>
                                <label className="relative inline-flex items-center cursor-pointer">
                                    <input
                                        name="active"
                                        value="true"
                                        defaultChecked={currentPayment ? currentPayment.active : true}
                                        className="sr-only peer"
                                        type="checkbox"
                                    />
                                    <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                </label>
                            </div>

                            <div className="flex items-center gap-3 mt-4">
                                {currentPayment && (
                                    <button
                                        type="button"
                                        onClick={() => handleDeletePayment(currentPayment.id)}
                                        className="px-5 py-2.5 rounded-lg text-sm font-medium text-red-500 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 transition-colors cursor-pointer mr-auto"
                                    >
                                        Hapus
                                    </button>
                                )}
                                {!currentPayment && <div className="flex-1"></div>}
                                <button
                                    type="button"
                                    onClick={() => setIsPaymentModalOpen(false)}
                                    className="px-5 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:text-white hover:bg-white/5 transition-colors cursor-pointer"
                                >
                                    Batal
                                </button>
                                <button
                                    type="submit"
                                    className="bg-primary hover:bg-blue-600 text-white px-5 py-2.5 rounded-lg text-sm font-bold shadow-lg shadow-primary/20 transition-all active:scale-95 cursor-pointer"
                                >
                                    Simpan
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
            {/* Modal Tambah/Edit Jenis Pajak Kustom */}
            {isTaxModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-[#161b22] border border-white/10 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl animate-in fade-in zoom-in duration-200">
                        <div className="flex items-center justify-between p-6 border-b border-white/10 bg-white/5">
                            <h2 className="text-xl font-bold text-white">
                                {currentTax ? 'Edit Pajak Kustom' : 'Tambah Pajak Kustom'}
                            </h2>
                            <button
                                onClick={() => setIsTaxModalOpen(false)}
                                className="text-slate-400 hover:text-white transition-colors cursor-pointer"
                            >
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>
                        <form onSubmit={handleSaveTax} className="p-6 flex flex-col gap-5">
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium text-slate-300">Nama Pajak</label>
                                <input
                                    name="name"
                                    type="text"
                                    required
                                    defaultValue={currentTax?.name || ''}
                                    className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                    placeholder="Contoh: Pajak Pembangunan"
                                />
                            </div>
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium text-slate-300">Deskripsi Singkat</label>
                                <input
                                    name="desc"
                                    type="text"
                                    required
                                    defaultValue={currentTax?.desc || ''}
                                    className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                    placeholder="Contoh: Biaya lingkungan sekitar"
                                />
                            </div>
                            <div className="flex flex-col gap-2">
                                <label className="text-sm font-medium text-slate-300">Persentase (%)</label>
                                <div className="relative">
                                    <input
                                        name="rate"
                                        type="number"
                                        step="0.01"
                                        required
                                        defaultValue={currentTax?.rate || ''}
                                        className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                        placeholder="Contoh: 10"
                                    />
                                    <span className="absolute right-4 top-2.5 text-slate-500 font-medium">%</span>
                                </div>
                            </div>
                            <div className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/10 mt-2">
                                <div className="flex flex-col gap-0.5">
                                    <span className="text-sm font-bold text-white">Status Aktif</span>
                                    <span className="text-xs text-slate-400">Aktifkan pajak kustom ini</span>
                                </div>
                                <label className="relative inline-flex items-center cursor-pointer">
                                    <input
                                        name="active"
                                        value="true"
                                        defaultChecked={currentTax ? currentTax.active : true}
                                        className="sr-only peer"
                                        type="checkbox"
                                    />
                                    <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                                </label>
                            </div>

                            <div className="flex items-center gap-3 mt-4">
                                {currentTax && (
                                    <button
                                        type="button"
                                        onClick={() => handleDeleteTax(currentTax.id)}
                                        className="px-5 py-2.5 rounded-lg text-sm font-medium text-red-500 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 transition-colors cursor-pointer mr-auto"
                                    >
                                        Hapus
                                    </button>
                                )}
                                {!currentTax && <div className="flex-1"></div>}
                                <button
                                    type="button"
                                    onClick={() => setIsTaxModalOpen(false)}
                                    className="px-5 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:text-white hover:bg-white/5 transition-colors cursor-pointer"
                                >
                                    Batal
                                </button>
                                <button
                                    type="submit"
                                    className="bg-primary hover:bg-blue-600 text-white px-5 py-2.5 rounded-lg text-sm font-bold shadow-lg shadow-primary/20 transition-all active:scale-95 cursor-pointer"
                                >
                                    Simpan
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </>
    );
}

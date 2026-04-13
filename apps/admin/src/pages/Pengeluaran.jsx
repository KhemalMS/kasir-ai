import React, { useState } from 'react';
import { useExpenses, useCreateExpense } from '../hooks/useExpenses';

export default function Pengeluaran() {
    const { data: expenses = [], isLoading } = useExpenses();
    const createExpense = useCreateExpense();
    const [showExpenseModal, setShowExpenseModal] = useState(false);

    return (
        <>
            <header className="flex items-center justify-between px-8 py-5 border-b border-[#283039] glass-panel z-10 transition-all">
                <div className="flex items-center gap-4">
                    <button className="lg:hidden text-[#9dabb9] hover:text-white">
                        <span className="material-symbols-outlined">menu</span>
                    </button>
                    <h2 className="text-xl font-bold text-white tracking-tight">Manajemen Pengeluaran</h2>
                </div>
                <div className="flex items-center gap-4">
                    <button className="flex items-center gap-2 px-3 py-2 rounded-lg bg-[#1c232b] hover:bg-[#252d36] text-[#9dabb9] hover:text-white transition text-sm">
                        <span className="material-symbols-outlined text-[20px]">notifications</span>
                    </button>
                    <button
                        className="flex items-center gap-2 px-4 py-2 rounded-lg bg-primary hover:bg-primary/90 text-white transition text-sm font-medium shadow-lg shadow-primary/20 cursor-pointer"
                        onClick={() => setShowExpenseModal(true)}
                    >
                        <span className="material-symbols-outlined text-[20px]">add</span>
                        <span>Tambah Pengeluaran</span>
                    </button>
                </div>
            </header>

            <div className="flex-1 overflow-y-auto p-4 md:p-8 z-10 scroll-smooth">
                <div className="max-w-7xl mx-auto flex flex-col gap-8">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div className="glass-panel p-5 rounded-xl flex flex-col gap-1 relative overflow-hidden group">
                            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                                <span className="material-symbols-outlined text-6xl">payments</span>
                            </div>
                            <p className="text-[#9dabb9] text-sm font-medium">Total Pengeluaran (Okt)</p>
                            <div className="flex items-baseline gap-2">
                                <h3 className="text-2xl font-bold text-white">Rp 45.250.000</h3>
                            </div>
                            <div className="flex items-center gap-1 mt-2">
                                <span className="material-symbols-outlined text-[#0bda5b] text-base">trending_up</span>
                                <p className="text-[#0bda5b] text-xs font-medium">+12% dari bulan lalu</p>
                            </div>
                        </div>
                        <div className="glass-panel p-5 rounded-xl flex flex-col gap-1 relative overflow-hidden group">
                            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                                <span className="material-symbols-outlined text-6xl">pending_actions</span>
                            </div>
                            <p className="text-[#9dabb9] text-sm font-medium">Menunggu Persetujuan</p>
                            <div className="flex items-baseline gap-2">
                                <h3 className="text-2xl font-bold text-white">12</h3>
                            </div>
                            <div className="flex items-center gap-1 mt-2">
                                <span className="material-symbols-outlined text-orange-400 text-base">warning</span>
                                <p className="text-orange-400 text-xs font-medium">Perlu perhatian</p>
                            </div>
                        </div>
                        <div className="glass-panel p-5 rounded-xl flex flex-col gap-1 relative overflow-hidden group">
                            <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                                <span className="material-symbols-outlined text-6xl">pie_chart</span>
                            </div>
                            <p className="text-[#9dabb9] text-sm font-medium">Anggaran Bulanan</p>
                            <div className="flex items-baseline gap-2">
                                <h3 className="text-2xl font-bold text-white">85% Terpakai</h3>
                            </div>
                            <div className="w-full bg-[#283039] rounded-full h-1.5 mt-3">
                                <div className="bg-primary h-1.5 rounded-full" style={{ width: '85%' }}></div>
                            </div>
                        </div>
                    </div>

                    <div className="flex flex-col md:flex-row items-end md:items-center justify-between gap-4 glass-panel p-4 rounded-xl">
                        <div className="flex flex-col md:flex-row items-center gap-4 w-full md:w-auto">
                            <div className="relative w-full md:w-48 group">
                                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <span className="material-symbols-outlined text-[#9dabb9] text-[20px]">store</span>
                                </div>
                                <select className="block w-full pl-10 pr-10 py-2.5 text-sm bg-[#111418] border border-[#3b4754] text-white rounded-lg focus:ring-primary focus:border-primary appearance-none cursor-pointer hover:border-[#4b5563] transition-colors">
                                    <option>Semua Cabang</option>
                                    <option>Cabang Melawai</option>
                                    <option>Cabang Tebet</option>
                                    <option>Cabang Kemang</option>
                                </select>
                                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                                    <span className="material-symbols-outlined text-[#9dabb9] text-[20px]">expand_more</span>
                                </div>
                            </div>
                            <div className="relative w-full md:w-64">
                                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <span className="material-symbols-outlined text-[#9dabb9] text-[20px]">date_range</span>
                                </div>
                                <input className="block w-full pl-10 pr-3 py-2.5 text-sm bg-[#111418] border border-[#3b4754] text-white rounded-lg focus:ring-primary focus:border-primary hover:border-[#4b5563] transition-colors" readOnly type="text" value="Oct 1, 2023 - Oct 31, 2023" />
                            </div>
                        </div>
                        <div className="flex items-center gap-3 w-full md:w-auto justify-end">
                            <button className="flex items-center gap-2 px-4 py-2.5 rounded-lg border border-[#3b4754] text-[#9dabb9] hover:text-white hover:bg-[#283039] transition text-sm font-medium">
                                <span className="material-symbols-outlined text-[20px]">tune</span>
                                <span>Filter</span>
                            </button>
                            <button className="flex items-center gap-2 px-4 py-2.5 rounded-lg bg-[#283039] text-white hover:bg-[#323b46] transition text-sm font-medium border border-[#3b4754]">
                                <span className="material-symbols-outlined text-[20px]">download</span>
                                <span className="hidden sm:inline">Ekspor CSV</span>
                            </button>
                        </div>
                    </div>

                    <div className="glass-panel rounded-xl overflow-hidden flex flex-col shadow-2xl shadow-black/20">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="border-b border-[#283039] bg-[#1c232b]/50">
                                        <th className="px-6 py-4 text-xs font-semibold text-[#9dabb9] uppercase tracking-wider w-[50px]">
                                            <div className="flex items-center">
                                                <input className="rounded border-[#3b4754] bg-[#111418] text-primary focus:ring-primary/50 focus:ring-offset-0" type="checkbox" />
                                            </div>
                                        </th>
                                        <th className="px-6 py-4 text-xs font-semibold text-[#9dabb9] uppercase tracking-wider cursor-pointer hover:text-white group">
                                            <div className="flex items-center gap-1">
                                                TANGGAL
                                                <span className="material-symbols-outlined text-[16px] opacity-0 group-hover:opacity-100 transition-opacity">arrow_drop_down</span>
                                            </div>
                                        </th>
                                        <th className="px-6 py-4 text-xs font-semibold text-[#9dabb9] uppercase tracking-wider">DESKRIPSI</th>
                                        <th className="px-6 py-4 text-xs font-semibold text-[#9dabb9] uppercase tracking-wider">CABANG</th>
                                        <th className="px-6 py-4 text-xs font-semibold text-[#9dabb9] uppercase tracking-wider">SUMBER</th>
                                        <th className="px-6 py-4 text-xs font-semibold text-[#9dabb9] uppercase tracking-wider text-right">JUMLAH</th>
                                        <th className="px-6 py-4 text-xs font-semibold text-[#9dabb9] uppercase tracking-wider text-center">AKSI</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-[#283039] text-sm text-slate-200">
                                    <tr className="hover:bg-[#1c232b]/80 transition-colors group">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <input className="rounded border-[#3b4754] bg-[#111418] text-primary focus:ring-primary/50 focus:ring-offset-0" type="checkbox" />
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-[#9dabb9]">Oct 24, 2023</td>
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col">
                                                <span className="font-medium text-white">Restock Coffee Beans</span>
                                                <span className="text-xs text-[#9dabb9]">Pemasok: Arabica Suppliers Ltd.</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-2">
                                                <div className="size-2 rounded-full bg-blue-500"></div>
                                                <span>Cabang Melawai</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-purple-500/10 text-purple-400 border border-purple-500/20">
                                                <span className="w-1.5 h-1.5 rounded-full bg-purple-400"></span>
                                                Kas Pusat
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right font-medium text-white">Rp 2.500.000</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-center">
                                            <button className="p-1.5 hover:bg-[#283039] rounded-lg text-[#9dabb9] hover:text-white transition-colors">
                                                <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                            </button>
                                        </td>
                                    </tr>
                                    <tr className="hover:bg-[#1c232b]/80 transition-colors group">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <input className="rounded border-[#3b4754] bg-[#111418] text-primary focus:ring-primary/50 focus:ring-offset-0" type="checkbox" />
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-[#9dabb9]">Oct 24, 2023</td>
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col">
                                                <span className="font-medium text-white">Daily Ice Delivery</span>
                                                <span className="text-xs text-[#9dabb9]">Routine Restock</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-2">
                                                <div className="size-2 rounded-full bg-green-500"></div>
                                                <span>Cabang Tebet</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
                                                <span className="w-1.5 h-1.5 rounded-full bg-amber-400"></span>
                                                Laci
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right font-medium text-white">Rp 150.000</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-center">
                                            <button className="p-1.5 hover:bg-[#283039] rounded-lg text-[#9dabb9] hover:text-white transition-colors">
                                                <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                            </button>
                                        </td>
                                    </tr>
                                    <tr className="hover:bg-[#1c232b]/80 transition-colors group">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <input className="rounded border-[#3b4754] bg-[#111418] text-primary focus:ring-primary/50 focus:ring-offset-0" type="checkbox" />
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-[#9dabb9]">Oct 23, 2023</td>
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col">
                                                <span className="font-medium text-white">Internet Bill</span>
                                                <span className="text-xs text-[#9dabb9]">Penyedia: Biznet</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-2">
                                                <div className="size-2 rounded-full bg-blue-500"></div>
                                                <span>Cabang Melawai</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-purple-500/10 text-purple-400 border border-purple-500/20">
                                                <span className="w-1.5 h-1.5 rounded-full bg-purple-400"></span>
                                                Kas Pusat
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right font-medium text-white">Rp 550.000</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-center">
                                            <button className="p-1.5 hover:bg-[#283039] rounded-lg text-[#9dabb9] hover:text-white transition-colors">
                                                <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                            </button>
                                        </td>
                                    </tr>
                                    <tr className="hover:bg-[#1c232b]/80 transition-colors group">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <input className="rounded border-[#3b4754] bg-[#111418] text-primary focus:ring-primary/50 focus:ring-offset-0" type="checkbox" />
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-[#9dabb9]">Oct 23, 2023</td>
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col">
                                                <span className="font-medium text-white">Kitchen Cleaning Supplies</span>
                                                <span className="text-xs text-[#9dabb9]">Weekly Purchase</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-2">
                                                <div className="size-2 rounded-full bg-rose-500"></div>
                                                <span>Cabang Kemang</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
                                                <span className="w-1.5 h-1.5 rounded-full bg-amber-400"></span>
                                                Laci
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right font-medium text-white">Rp 320.000</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-center">
                                            <button className="p-1.5 hover:bg-[#283039] rounded-lg text-[#9dabb9] hover:text-white transition-colors">
                                                <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                            </button>
                                        </td>
                                    </tr>
                                    <tr className="hover:bg-[#1c232b]/80 transition-colors group">
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <input className="rounded border-[#3b4754] bg-[#111418] text-primary focus:ring-primary/50 focus:ring-offset-0" type="checkbox" />
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-[#9dabb9]">Oct 22, 2023</td>
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col">
                                                <span className="font-medium text-white">POS Thermal Paper</span>
                                                <span className="text-xs text-[#9dabb9]">Inventory Restock</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center gap-2">
                                                <div className="size-2 rounded-full bg-blue-500"></div>
                                                <span>Cabang Melawai</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
                                                <span className="w-1.5 h-1.5 rounded-full bg-amber-400"></span>
                                                Laci
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right font-medium text-white">Rp 85.000</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-center">
                                            <button className="p-1.5 hover:bg-[#283039] rounded-lg text-[#9dabb9] hover:text-white transition-colors">
                                                <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                            </button>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                        <div className="flex items-center justify-between px-6 py-4 border-t border-[#283039] bg-[#1c232b]/30">
                            <p className="text-sm text-[#9dabb9]">Menampilkan <span className="font-medium text-white">1</span> dari <span className="font-medium text-white">5</span> dari <span className="font-medium text-white">42</span> hasil</p>
                            <div className="flex gap-2">
                                <button className="px-3 py-1.5 rounded border border-[#3b4754] text-xs font-medium text-[#9dabb9] hover:bg-[#283039] hover:text-white disabled:opacity-50 disabled:cursor-not-allowed">Sebelumnya</button>
                                <button className="px-3 py-1.5 rounded border border-[#3b4754] text-xs font-medium text-[#9dabb9] hover:bg-[#283039] hover:text-white">Berikutnya</button>
                            </div>
                        </div>
                    </div>

                    <div className="flex items-center gap-4 p-4 rounded-xl bg-gradient-to-r from-primary/10 to-transparent border border-primary/20">
                        <div className="size-10 rounded-full bg-primary/20 flex items-center justify-center text-primary animate-pulse">
                            <span className="material-symbols-outlined">auto_awesome</span>
                        </div>
                        <div className="flex-1">
                            <h4 className="text-white text-sm font-semibold">Wawasan AI Tersedia</h4>
                            <p className="text-[#9dabb9] text-xs">Kami melihat kenaikan 15% pada biaya "Cleaning Supplies" dibanding bulan lalu. Lihat analisis?</p>
                        </div>
                        <button className="text-sm text-primary font-medium hover:text-primary/80">Lihat Detail</button>
                    </div>

                    <div className="h-20"></div>
                </div>
            </div>

            {/* Expense Modal */}
            {showExpenseModal && (
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
                                className="flex items-center justify-center w-8 h-8 rounded-full bg-white/5 hover:bg-white/10 text-slate-400 hover:text-white transition-colors cursor-pointer"
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
                                className="w-full flex items-center justify-center gap-2 bg-primary hover:bg-blue-600 active:scale-[0.98] text-white font-bold py-3.5 px-4 rounded-xl shadow-lg shadow-primary/25 transition-all text-sm cursor-pointer"
                                onClick={() => setShowExpenseModal(false)}
                            >
                                <span className="material-symbols-outlined text-[20px]">save</span>
                                <span>SIMPAN PENGELUARAN</span>
                            </button>
                        </div>
                    </div>
                </div>
            )}

        </>
    );
}

import React, { useState } from 'react';
import { useOrders } from '../hooks/useOrders';
import { SkeletonRow, EmptyState } from '../components/LoadingStates';

export default function Transaksi() {
    const [dateFilter, setDateFilter] = useState('');
    const { data: transactions = [], isLoading } = useOrders({ startDate: dateFilter || undefined, endDate: dateFilter || undefined });

    const filteredTransactions = transactions;
    return (
        <>
            <div className="z-10 flex flex-col gap-6 p-6 pb-2 glass-header border-b border-slate-800">
                <div className="flex flex-wrap items-end justify-between gap-4">
                    <div>
                        <h2 className="text-3xl font-bold text-white tracking-tight">Riwayat Transaksi</h2>
                        <div className="mt-1 flex items-center gap-2 text-slate-400">
                            <span className="material-symbols-outlined text-[18px]">calendar_today</span>
                            <span className="text-sm">Hari ini, 24 Okt 2023</span>
                            <span className="mx-1">•</span>
                            <span className="text-sm text-primary font-medium">Total Penjualan: Rp 12.500.000</span>
                        </div>
                    </div>
                    <div className="flex gap-3">
                        <button className="glass-panel hover:bg-slate-800 transition-colors text-white px-4 py-2 rounded-lg flex items-center gap-2 text-sm font-medium border border-slate-700">
                            <span className="material-symbols-outlined text-[20px]">file_download</span>
                            Export Laporan
                        </button>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-3 pt-2">
                    <div className="relative flex-1 min-w-[240px] max-w-md group">
                        <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors">
                            <span className="material-symbols-outlined">search</span>
                        </div>
                        <input className="w-full bg-[#1c2333] border border-slate-700 rounded-lg py-2.5 pl-10 pr-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" placeholder="Cari Order ID (cth. #ORD-042)..." type="text" />
                    </div>
                    <div className="relative min-w-[160px]">
                        <select className="w-full appearance-none bg-[#1c2333] border border-slate-700 rounded-lg py-2.5 pl-3 pr-10 text-sm text-white focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary cursor-pointer">
                            <option>Semua Cabang</option>
                            <option>Jakarta Selatan</option>
                            <option>Jakarta Pusat</option>
                            <option>Bandung</option>
                        </select>
                        <div className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
                            <span className="material-symbols-outlined text-[20px]">expand_more</span>
                        </div>
                    </div>
                    <div className="relative min-w-[160px]">
                        <input
                            type="date"
                            value={dateFilter}
                            onChange={(e) => setDateFilter(e.target.value)}
                            className="relative w-full appearance-none bg-[#1c2333] border border-slate-700 rounded-lg py-2.5 pl-3 pr-10 text-sm text-white focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-colors cursor-pointer [&::-webkit-calendar-picker-indicator]:opacity-0 [&::-webkit-calendar-picker-indicator]:absolute [&::-webkit-calendar-picker-indicator]:inset-0 [&::-webkit-calendar-picker-indicator]:w-full [&::-webkit-calendar-picker-indicator]:h-full [&::-webkit-calendar-picker-indicator]:cursor-pointer"
                        />
                        <div className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
                            <span className="material-symbols-outlined text-[20px]">calendar_month</span>
                        </div>
                    </div>
                    <div className="relative min-w-[140px]">
                        <select className="w-full appearance-none bg-[#1c2333] border border-slate-700 rounded-lg py-2.5 pl-3 pr-10 text-sm text-white focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary cursor-pointer">
                            <option>Semua Status</option>
                            <option>Lunas</option>
                            <option>Pending</option>
                            <option>Dibatalkan</option>
                        </select>
                        <div className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
                            <span className="material-symbols-outlined text-[20px]">filter_list</span>
                        </div>
                    </div>
                </div>
            </div>

            <div className="z-10 flex-1 overflow-y-auto p-6 scroll-smooth">
                <div className="glass-panel rounded-xl overflow-hidden shadow-2xl shadow-black/20">
                    <table className="w-full text-left border-collapse">
                        <thead className="bg-[#1c2333] border-b border-slate-700 text-xs uppercase text-slate-400 font-semibold tracking-wider sticky top-0 z-20">
                            <tr>
                                <th className="px-6 py-4">Order ID</th>
                                <th className="px-6 py-4">Tanggal &amp; Waktu</th>
                                <th className="px-6 py-4">Cabang</th>
                                <th className="px-6 py-4">Pelanggan</th>
                                <th className="px-6 py-4">Metode Pembayaran</th>
                                <th className="px-6 py-4">Status</th>
                                <th className="px-6 py-4 text-right">Total Bayar</th>
                                <th className="px-6 py-4 text-center">Aksi</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-800/50 text-sm">
                            {isLoading ? (
                                <tr><td colSpan="7" className="p-0"><SkeletonRow count={5} /></td></tr>
                            ) : filteredTransactions.length === 0 ? (
                                <tr><td colSpan="7"><EmptyState icon="receipt_long" title="Belum ada transaksi" description="Transaksi akan muncul di sini." /></td></tr>
                            ) : filteredTransactions.map(t => (
                                <tr key={t.id} className="group hover:bg-slate-800/50 transition-colors">
                                    <td className="px-6 py-4 font-medium text-primary">{t.id}</td>
                                    <td className="px-6 py-4 text-slate-300">
                                        <div className="flex flex-col">
                                            <span className="font-medium text-white">{t.dateDisplay}</span>
                                            <span className="text-xs text-slate-500">{t.time}</span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 text-slate-300">{t.branch}</td>
                                    <td className="px-6 py-4 text-slate-300">{t.customer}</td>
                                    <td className="px-6 py-4">
                                        <div className={`inline-flex items-center gap-1.5 rounded-full border border-${t.methodColor}-500/20 bg-${t.methodColor}-500/10 px-2.5 py-1 text-xs font-medium text-${t.methodColor}-400`}>
                                            <span className="material-symbols-outlined text-[14px]">{t.methodIcon}</span>
                                            {t.method}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className={`inline-flex items-center gap-1.5 rounded-full border border-${t.statusColor}-500/20 bg-${t.statusColor}-500/10 px-2.5 py-1 text-xs font-medium text-${t.statusColor}-400`}>
                                            <div className={`h-1.5 w-1.5 rounded-full bg-${t.statusColor}-400 ${t.isPulsing ? 'animate-pulse' : ''}`}></div>
                                            {t.status}
                                        </div>
                                    </td>
                                    <td className={`px-6 py-4 text-right font-semibold ${t.canceled ? 'text-slate-400 line-through' : 'text-white'}`}>{t.total}</td>
                                    <td className="px-6 py-4 text-center">
                                        <button className="text-slate-400 hover:text-white p-1 rounded-full hover:bg-slate-700 transition-colors">
                                            <span className="material-symbols-outlined text-[20px]">more_vert</span>
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>

                    <div className="flex items-center justify-between border-t border-slate-700 bg-[#1c2333]/50 p-4">
                        <div className="text-sm text-slate-400">
                            Menampilkan <span className="font-medium text-white">1</span> sampai <span className="font-medium text-white">6</span> dari <span className="font-medium text-white">124</span> hasil
                        </div>
                        <div className="flex items-center gap-2">
                            <button className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 bg-slate-800 text-slate-400 hover:bg-slate-700 hover:text-white disabled:opacity-50">
                                <span className="material-symbols-outlined text-[18px]">chevron_left</span>
                            </button>
                            <button className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-sm font-medium text-white shadow-lg shadow-blue-900/40">1</button>
                            <button className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 bg-transparent text-sm font-medium text-slate-400 hover:bg-slate-800 hover:text-white">2</button>
                            <button className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 bg-transparent text-sm font-medium text-slate-400 hover:bg-slate-800 hover:text-white">3</button>
                            <span className="text-slate-500">...</span>
                            <button className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 bg-transparent text-sm font-medium text-slate-400 hover:bg-slate-800 hover:text-white">12</button>
                            <button className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-700 bg-slate-800 text-slate-400 hover:bg-slate-700 hover:text-white">
                                <span className="material-symbols-outlined text-[18px]">chevron_right</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </>
    );
}

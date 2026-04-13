import React, { useState } from 'react';
import { useDailySummary, useTopProducts } from '../hooks/useReports';
import { useOrders } from '../hooks/useOrders';
import { useBranches } from '../hooks/useBranches';
import { SkeletonRow, EmptyState, SectionLoader } from '../components/LoadingStates';

const formatRp = (n) => new Intl.NumberFormat('id-ID').format(n || 0);

const getPaymentBadge = (method) => {
    const config = {
        'Tunai': { icon: 'payments', color: 'emerald' },
        'QRIS': { icon: 'qr_code', color: 'blue' },
        'Kartu Debit': { icon: 'credit_card', color: 'purple' },
        'Kartu Kredit': { icon: 'credit_card', color: 'orange' },
        'Transfer Bank': { icon: 'account_balance', color: 'cyan' },
    };
    const c = config[method] || config['Tunai'];
    return (
        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-${c.color}-500/10 text-${c.color}-400 border border-${c.color}-500/20 text-xs font-medium`}>
            <span className="material-symbols-outlined text-[14px]">{c.icon}</span> {method}
        </span>
    );
};

const getStatusBadge = (status) => {
    if (status === 'completed' || status === 'Sukses') {
        return (
            <span className="inline-flex items-center gap-1.5 text-emerald-400 text-xs font-medium">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span> Sukses
            </span>
        );
    }
    if (status === 'pending' || status === 'Pending') {
        return (
            <span className="inline-flex items-center gap-1.5 text-yellow-400 text-xs font-medium">
                <span className="w-1.5 h-1.5 rounded-full bg-yellow-400 animate-pulse"></span> Pending
            </span>
        );
    }
    if (status === 'cancelled' || status === 'Batal') {
        return (
            <span className="inline-flex items-center gap-1.5 text-rose-400 text-xs font-medium">
                <span className="w-1.5 h-1.5 rounded-full bg-rose-400"></span> Batal
            </span>
        );
    }
    return <span className="text-xs text-slate-400">{status}</span>;
};

const getInitials = (name) => {
    if (!name) return '??';
    return name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase();
};

const STAT_CARDS = [
    { key: 'totalRevenue', label: 'Total Pendapatan', icon: 'payments', color: 'primary', format: 'currency' },
    { key: 'totalTransactions', label: 'Jumlah Transaksi', icon: 'receipt_long', color: 'blue-500', format: 'number' },
    { key: 'averageOrder', label: 'Rata-rata Keranjang', icon: 'shopping_bag', color: 'orange-500', format: 'currency' },
    { key: 'topBranch', label: 'Cabang Terlaris', icon: 'store', color: 'purple-500', format: 'text' },
];

export default function Laporan() {
    const [selectedBranch, setSelectedBranch] = useState(null);
    const [page, setPage] = useState(1);
    const perPage = 10;

    const { data: dailySummary, isLoading: summaryLoading } = useDailySummary(null, selectedBranch);
    const { data: branches = [], isLoading: branchesLoading } = useBranches();
    const { data: ordersData, isLoading: ordersLoading } = useOrders({
        branchId: selectedBranch,
        page,
        limit: perPage,
    });

    const orders = Array.isArray(ordersData) ? ordersData : ordersData?.data || [];
    const totalOrders = ordersData?.total || orders.length;
    const totalPages = Math.max(1, Math.ceil(totalOrders / perPage));

    const today = new Date().toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });

    const getStatValue = (stat) => {
        if (!dailySummary) return stat.format === 'text' ? '-' : '0';
        const val = dailySummary[stat.key];
        if (stat.format === 'currency') return `Rp ${formatRp(val)}`;
        if (stat.format === 'text') return val || '-';
        return formatRp(val);
    };

    const getStatGrowth = (stat) => {
        if (!dailySummary) return null;
        return dailySummary[`${stat.key}Growth`] ?? null;
    };

    return (
        <div className="flex-1 flex flex-col h-screen relative overflow-hidden bg-background-dark">
            <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-primary/10 rounded-full blur-[100px] pointer-events-none"></div>
            <div className="absolute bottom-[-20%] right-[-10%] w-[400px] h-[400px] bg-purple-500/10 rounded-full blur-[100px] pointer-events-none"></div>

            <div className="flex-1 overflow-y-auto overflow-x-hidden p-4 md:p-8 scroll-smooth">
                <div className="mx-auto max-w-7xl flex flex-col gap-6">

                    <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                        <div>
                            <h2 className="text-2xl md:text-3xl font-bold text-white tracking-tight">Laporan Penjualan Harian</h2>
                            <p className="text-slate-400 text-sm mt-1 flex items-center gap-1">
                                <span className="material-symbols-outlined text-[16px]">calendar_today</span>
                                {today}
                            </p>
                        </div>
                        <div className="flex items-center gap-3">
                            <button className="glass-panel px-4 py-2 rounded-lg text-slate-300 text-sm font-medium hover:text-white hover:bg-white/5 transition-colors flex items-center gap-2">
                                <span className="material-symbols-outlined text-[20px]">filter_list</span>
                                Filter
                            </button>
                            <button className="bg-primary hover:bg-primary/90 text-white px-4 py-2 rounded-lg text-sm font-bold shadow-lg shadow-primary/25 transition-all flex items-center gap-2">
                                <span className="material-symbols-outlined text-[20px]">download</span>
                                Unduh Laporan
                            </button>
                        </div>
                    </header>

                    {/* Stat Cards */}
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                        {summaryLoading ? (
                            Array.from({ length: 4 }).map((_, i) => (
                                <div key={i} className="glass-panel p-5 rounded-xl animate-pulse">
                                    <div className="h-4 w-24 bg-white/10 rounded mb-3"></div>
                                    <div className="h-8 w-32 bg-white/10 rounded mb-2"></div>
                                    <div className="h-3 w-20 bg-white/10 rounded"></div>
                                </div>
                            ))
                        ) : (
                            STAT_CARDS.map(stat => {
                                const growth = getStatGrowth(stat);
                                const isPositive = growth >= 0;
                                return (
                                    <div key={stat.key} className="glass-panel p-5 rounded-xl flex flex-col gap-2 relative overflow-hidden group">
                                        <div className={`absolute right-[-10px] top-[-10px] p-8 bg-${stat.color}/10 rounded-full blur-xl transition-all group-hover:bg-${stat.color}/20`}></div>
                                        <div className="flex items-center gap-2 text-slate-400 text-sm font-medium z-10">
                                            <span className="material-symbols-outlined text-[20px]">{stat.icon}</span>
                                            {stat.label}
                                        </div>
                                        <div className="text-2xl lg:text-3xl font-bold text-white z-10">{getStatValue(stat)}</div>
                                        {growth !== null && (
                                            <div className={`flex items-center gap-1 ${isPositive ? 'text-emerald-400' : 'text-rose-400'} text-sm font-medium z-10`}>
                                                <span className="material-symbols-outlined text-[16px]">{isPositive ? 'trending_up' : 'trending_down'}</span>
                                                {isPositive ? '+' : ''}{growth}% <span className="text-slate-500 font-normal">vs kemarin</span>
                                            </div>
                                        )}
                                    </div>
                                );
                            })
                        )}
                    </div>

                    {/* Branch Filter */}
                    <div className="flex flex-wrap gap-3 pb-2 overflow-x-auto hide-scrollbar">
                        <button
                            onClick={() => { setSelectedBranch(null); setPage(1); }}
                            className={`flex h-9 shrink-0 items-center justify-center gap-x-2 rounded-full px-4 text-sm font-medium transition-all ${selectedBranch === null
                                    ? 'bg-primary text-white shadow-md shadow-primary/20'
                                    : 'glass-panel text-slate-300 hover:bg-white/5'
                                }`}
                        >
                            <span className="material-symbols-outlined text-[18px]">storefront</span>
                            Semua Cabang
                        </button>
                        {branches.map(branch => (
                            <button
                                key={branch.id}
                                onClick={() => { setSelectedBranch(branch.id); setPage(1); }}
                                className={`flex h-9 shrink-0 items-center justify-center gap-x-2 rounded-full px-4 text-sm font-medium transition-all ${selectedBranch === branch.id
                                        ? 'bg-primary text-white shadow-md shadow-primary/20'
                                        : 'glass-panel text-slate-300 hover:bg-white/5'
                                    }`}
                            >
                                {branch.name}
                            </button>
                        ))}
                    </div>

                    {/* Transactions Table */}
                    <div className="@container w-full">
                        <div className="glass-panel rounded-xl overflow-hidden shadow-2xl shadow-black/20">
                            <div className="overflow-x-auto">
                                <table className="w-full text-left border-collapse">
                                    <thead>
                                        <tr className="border-b border-white/10 bg-white/5 text-slate-400 text-xs uppercase tracking-wider">
                                            <th className="p-5 font-semibold">Waktu</th>
                                            <th className="p-5 font-semibold">ID Pesanan</th>
                                            <th className="p-5 font-semibold">Tipe</th>
                                            <th className="p-5 font-semibold">Metode</th>
                                            <th className="p-5 font-semibold">Status</th>
                                            <th className="p-5 font-semibold text-right">Total (Rp)</th>
                                        </tr>
                                    </thead>
                                    <tbody className="text-sm divide-y divide-white/5">
                                        {ordersLoading ? (
                                            <tr><td colSpan={6} className="p-8"><SectionLoader message="Memuat transaksi..." /></td></tr>
                                        ) : orders.length === 0 ? (
                                            <tr><td colSpan={6} className="p-8"><EmptyState icon="receipt_long" title="Belum ada transaksi" description="Transaksi akan muncul di sini setelah ada pesanan." /></td></tr>
                                        ) : (
                                            orders.map((order) => {
                                                const time = order.createdAt
                                                    ? new Date(order.createdAt).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
                                                    : '-';
                                                const isCancelled = order.status === 'cancelled' || order.status === 'Batal';
                                                const paymentMethod = order.paymentMethod || order.payments?.[0]?.method || 'Tunai';
                                                return (
                                                    <tr key={order.id} className="glass-row transition-colors duration-200">
                                                        <td className="p-5 text-slate-400 whitespace-nowrap">{time}</td>
                                                        <td className="p-5 text-white font-medium whitespace-nowrap">#{order.orderNumber || order.id}</td>
                                                        <td className="p-5 text-slate-300 whitespace-nowrap capitalize">
                                                            {order.orderType === 'dine_in' ? 'Dine In' : order.orderType === 'takeaway' ? 'Take Away' : order.orderType || '-'}
                                                        </td>
                                                        <td className="p-5 whitespace-nowrap">{getPaymentBadge(paymentMethod)}</td>
                                                        <td className="p-5 whitespace-nowrap">{getStatusBadge(order.status)}</td>
                                                        <td className={`p-5 font-semibold text-right whitespace-nowrap ${isCancelled ? 'text-slate-500 line-through' : 'text-white'}`}>
                                                            {formatRp(order.total)}
                                                        </td>
                                                    </tr>
                                                );
                                            })
                                        )}
                                    </tbody>
                                </table>
                            </div>

                            {/* Pagination */}
                            <div className="flex items-center justify-between border-t border-white/5 bg-white/5 p-4">
                                <span className="text-sm text-slate-400">
                                    Menampilkan {orders.length > 0 ? (page - 1) * perPage + 1 : 0}-{Math.min(page * perPage, totalOrders)} dari {totalOrders} data
                                </span>
                                <div className="flex gap-2">
                                    <button
                                        onClick={() => setPage(p => Math.max(1, p - 1))}
                                        disabled={page <= 1}
                                        className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/10 bg-transparent text-slate-400 hover:bg-white/5 hover:text-white transition-colors disabled:opacity-30"
                                    >
                                        <span className="material-symbols-outlined text-[18px]">chevron_left</span>
                                    </button>
                                    {Array.from({ length: Math.min(3, totalPages) }, (_, i) => i + 1).map(p => (
                                        <button
                                            key={p}
                                            onClick={() => setPage(p)}
                                            className={`flex h-8 w-8 items-center justify-center rounded-lg text-sm font-bold transition-colors ${page === p
                                                    ? 'bg-primary text-white shadow-md shadow-primary/20'
                                                    : 'border border-white/10 bg-transparent text-slate-400 hover:bg-white/5 hover:text-white'
                                                }`}
                                        >
                                            {p}
                                        </button>
                                    ))}
                                    {totalPages > 3 && <span className="flex h-8 w-8 items-center justify-center text-slate-500">...</span>}
                                    <button
                                        onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                                        disabled={page >= totalPages}
                                        className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/10 bg-transparent text-slate-400 hover:bg-white/5 hover:text-white transition-colors disabled:opacity-30"
                                    >
                                        <span className="material-symbols-outlined text-[18px]">chevron_right</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <footer className="mt-4 flex flex-col md:flex-row justify-between items-center text-xs text-slate-500 pb-8">
                        <p>© 2026 Kasir-AI POS System. All rights reserved.</p>
                        <div className="flex gap-4 mt-2 md:mt-0">
                            <a className="hover:text-slate-300 transition-colors" href="#">Bantuan</a>
                            <a className="hover:text-slate-300 transition-colors" href="#">Privasi</a>
                            <a className="hover:text-slate-300 transition-colors" href="#">Syarat & Ketentuan</a>
                        </div>
                    </footer>

                </div>
            </div>
        </div>
    );
}

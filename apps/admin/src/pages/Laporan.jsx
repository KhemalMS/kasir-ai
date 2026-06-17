import React, { useState, useMemo, useCallback } from 'react';
import * as XLSX from 'xlsx';
import {
    LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid,
    Tooltip, ResponsiveContainer, Legend, PieChart, Pie, Cell,
} from 'recharts';
import {
    useProfitLoss, useCashFlow, useExpenseSummary,
    useExpenseReport, useRevenueChart,
} from '../hooks/useReports';
import { useOrders } from '../hooks/useOrders';
import { useBranches } from '../hooks/useBranches';
import { SectionLoader, EmptyState } from '../components/LoadingStates';

// ── Helpers ────────────────────────────────────────────────────────
const fmt = (n) => new Intl.NumberFormat('id-ID').format(Math.round(n || 0));
const fmtRp = (n) => `Rp ${fmt(n)}`;
const fmtDate = (d) => new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });

const toISODate = (d) => d.toISOString().split('T')[0];

const getPreset = (preset) => {
    const now = new Date();
    const end = toISODate(now);
    if (preset === 'today') return { start: end, end };
    if (preset === 'week') {
        const d = new Date(now); d.setDate(d.getDate() - 6);
        return { start: toISODate(d), end };
    }
    if (preset === 'month') {
        const d = new Date(now); d.setDate(1);
        return { start: toISODate(d), end };
    }
    if (preset === '3month') {
        const d = new Date(now); d.setMonth(d.getMonth() - 2); d.setDate(1);
        return { start: toISODate(d), end };
    }
    return { start: end, end };
};

const EXPENSE_COLORS = ['#6366f1', '#22d3ee', '#f59e0b', '#10b981', '#ec4899', '#8b5cf6', '#f97316'];

const TABS = [
    { id: 'overview', label: 'Ringkasan', icon: 'dashboard' },
    { id: 'profit', label: 'Laba Rugi', icon: 'trending_up' },
    { id: 'cashflow', label: 'Arus Kas', icon: 'swap_horiz' },
    { id: 'transactions', label: 'Transaksi', icon: 'receipt_long' },
];

// ── Sub-components ─────────────────────────────────────────────────
function MetricCard({ label, value, icon, sub, color = 'primary', trend }) {
    const isPositive = trend >= 0;
    return (
        <div className="glass-panel rounded-xl p-5 flex flex-col gap-2 relative overflow-hidden group">
            <div className={`absolute right-[-10px] top-[-10px] p-8 bg-${color}/10 rounded-full blur-xl transition-all group-hover:bg-${color}/20`} />
            <div className="flex items-center gap-2 text-slate-400 text-sm font-medium z-10">
                <span className="material-symbols-outlined text-[20px]">{icon}</span>
                {label}
            </div>
            <div className="text-2xl xl:text-3xl font-bold text-white z-10 truncate">{value}</div>
            {sub && <div className="text-xs text-slate-500 z-10">{sub}</div>}
            {trend != null && (
                <div className={`flex items-center gap-1 ${isPositive ? 'text-emerald-400' : 'text-rose-400'} text-sm font-medium z-10`}>
                    <span className="material-symbols-outlined text-[16px]">{isPositive ? 'trending_up' : 'trending_down'}</span>
                    {isPositive ? '+' : ''}{trend}% vs periode lalu
                </div>
            )}
        </div>
    );
}

function SectionCard({ title, icon, children, action }) {
    return (
        <div className="glass-panel rounded-xl overflow-hidden">
            <div className="flex items-center justify-between px-6 py-4 border-b border-white/10 bg-white/5">
                <div className="flex items-center gap-2 text-white font-semibold">
                    <span className="material-symbols-outlined text-[20px] text-primary">{icon}</span>
                    {title}
                </div>
                {action}
            </div>
            <div className="p-6">{children}</div>
        </div>
    );
}

const CustomTooltip = ({ active, payload, label }) => {
    if (!active || !payload?.length) return null;
    return (
        <div className="bg-[#1e2533] border border-white/10 rounded-xl p-3 shadow-2xl text-sm min-w-[160px]">
            <p className="text-slate-400 mb-2 font-medium">{label}</p>
            {payload.map((p) => (
                <p key={p.name} style={{ color: p.color }} className="font-semibold">
                    {p.name}: {fmtRp(p.value)}
                </p>
            ))}
        </div>
    );
};

// ── Tab: Overview ──────────────────────────────────────────────────
function TabOverview({ dateRange, branchId }) {
    const { data: pl, isLoading: plLoading } = useProfitLoss(dateRange.start, dateRange.end, branchId);
    const { data: chart } = useRevenueChart(7, branchId);
    const { data: expSummary } = useExpenseSummary(dateRange.start, dateRange.end, branchId);

    const profitMargin = pl?.totalRevenue > 0
        ? Math.round((pl.profit / pl.totalRevenue) * 100)
        : 0;

    const chartData = Array.isArray(chart)
        ? chart.map(d => ({ label: d.date?.slice(5) || d.label, Pendapatan: d.totalRevenue }))
        : [];

    const pieData = expSummary?.categories?.slice(0, 6) || [];

    if (plLoading) return <SectionLoader message="Memuat ringkasan keuangan..." />;

    return (
        <div className="flex flex-col gap-6">
            {/* KPI Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                <MetricCard label="Total Pendapatan" value={fmtRp(pl?.totalRevenue)} icon="payments" color="primary" />
                <MetricCard label="Total Pengeluaran" value={fmtRp(pl?.totalExpenses)} icon="account_balance_wallet" color="rose-500" />
                <MetricCard
                    label="Laba Bersih"
                    value={fmtRp(pl?.profit)}
                    icon="trending_up"
                    color={pl?.profit >= 0 ? 'emerald-500' : 'rose-500'}
                    sub={`Margin ${profitMargin}%`}
                />
                <MetricCard
                    label="Food Cost %"
                    value={`${pl?.totalRevenue > 0 ? Math.round((pl.totalExpenses / pl.totalRevenue) * 100) : 0}%`}
                    icon="restaurant"
                    color="orange-500"
                    sub="Pengeluaran / Pendapatan"
                />
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
                {/* Revenue chart */}
                <div className="xl:col-span-2">
                    <SectionCard title="Tren Pendapatan 7 Hari" icon="show_chart">
                        <ResponsiveContainer width="100%" height={220}>
                            <LineChart data={chartData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" />
                                <XAxis dataKey="label" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                                <YAxis tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} tick={{ fill: '#94a3b8', fontSize: 11 }} axisLine={false} tickLine={false} />
                                <Tooltip content={<CustomTooltip />} />
                                <Line type="monotone" dataKey="Pendapatan" stroke="#6366f1" strokeWidth={2.5} dot={false} activeDot={{ r: 5, fill: '#6366f1' }} />
                            </LineChart>
                        </ResponsiveContainer>
                    </SectionCard>
                </div>

                {/* Expense Pie */}
                <SectionCard title="Komposisi Pengeluaran" icon="donut_large">
                    {pieData.length === 0 ? (
                        <EmptyState icon="donut_large" title="Tidak ada data" description="Belum ada pengeluaran di periode ini." />
                    ) : (
                        <>
                            <ResponsiveContainer width="100%" height={160}>
                                <PieChart>
                                    <Pie data={pieData} dataKey="total" nameKey="category" cx="50%" cy="50%" outerRadius={70} innerRadius={40}>
                                        {pieData.map((_, i) => <Cell key={i} fill={EXPENSE_COLORS[i % EXPENSE_COLORS.length]} />)}
                                    </Pie>
                                    <Tooltip formatter={(v) => fmtRp(v)} />
                                </PieChart>
                            </ResponsiveContainer>
                            <div className="flex flex-col gap-2 mt-2">
                                {pieData.map((d, i) => (
                                    <div key={d.category} className="flex items-center justify-between text-sm">
                                        <div className="flex items-center gap-2">
                                            <div className="w-2.5 h-2.5 rounded-full" style={{ background: EXPENSE_COLORS[i % EXPENSE_COLORS.length] }} />
                                            <span className="text-slate-300">{d.category}</span>
                                        </div>
                                        <span className="text-slate-400">{d.percentage}%</span>
                                    </div>
                                ))}
                            </div>
                        </>
                    )}
                </SectionCard>
            </div>
        </div>
    );
}

// ── Tab: Laba Rugi ─────────────────────────────────────────────────
function TabProfitLoss({ dateRange, branchId, onExport }) {
    const { data: pl, isLoading } = useProfitLoss(dateRange.start, dateRange.end, branchId);
    const { data: expSummary } = useExpenseSummary(dateRange.start, dateRange.end, branchId);
    const { data: expReport } = useExpenseReport(dateRange.start, dateRange.end, branchId);
    const [openCategory, setOpenCategory] = useState(null);

    const expensesByCategory = useMemo(() => {
        if (!expReport) return {};
        return expReport.reduce((acc, e) => {
            if (!acc[e.category]) acc[e.category] = [];
            acc[e.category].push(e);
            return acc;
        }, {});
    }, [expReport]);

    if (isLoading) return <SectionLoader message="Memuat laporan laba rugi..." />;

    const rows = [
        { label: 'Total Pendapatan', value: pl?.totalRevenue, indent: 0, type: 'income', bold: true },
        { label: 'Estimasi HPP (dari Pengeluaran Bahan Baku)', value: expSummary?.categories?.find(c => c.category.toLowerCase().includes('bahan'))?.total ?? 0, indent: 1, type: 'deduction' },
        { label: 'Laba Kotor', value: (pl?.totalRevenue || 0) - (expSummary?.categories?.find(c => c.category.toLowerCase().includes('bahan'))?.total ?? 0), indent: 0, type: 'gross', bold: true },
        { label: 'Total Pengeluaran Operasional', value: pl?.totalExpenses, indent: 0, type: 'deduction', bold: true, expandable: true },
        ...(expSummary?.categories || []).map(c => ({ label: c.category, value: c.total, indent: 1, type: 'deduction', sub: true })),
        { label: 'Laba Bersih', value: pl?.profit, indent: 0, type: pl?.profit >= 0 ? 'profit' : 'loss', bold: true, size: 'lg' },
    ];

    return (
        <div className="flex flex-col gap-6">
            <div className="grid grid-cols-3 gap-4">
                <MetricCard label="Total Pendapatan" value={fmtRp(pl?.totalRevenue)} icon="payments" color="primary" />
                <MetricCard label="Total Pengeluaran" value={fmtRp(pl?.totalExpenses)} icon="remove_circle" color="rose-500" />
                <MetricCard label="Laba Bersih" value={fmtRp(pl?.profit)} icon={pl?.profit >= 0 ? 'trending_up' : 'trending_down'} color={pl?.profit >= 0 ? 'emerald-500' : 'rose-500'} />
            </div>

            <SectionCard title="Rincian Laba Rugi" icon="account_balance" action={
                <button onClick={() => onExport('profit-loss')} className="flex items-center gap-1.5 text-sm text-primary hover:text-primary/80 transition-colors">
                    <span className="material-symbols-outlined text-[18px]">download</span> Export Excel
                </button>
            }>
                <table className="w-full text-sm">
                    <thead>
                        <tr className="border-b border-white/10 text-slate-400 text-xs uppercase">
                            <th className="py-3 text-left font-semibold">Keterangan</th>
                            <th className="py-3 text-right font-semibold">Jumlah</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5">
                        {rows.map((r, i) => (
                            <tr key={i} className={`${r.sub ? 'opacity-70' : ''} hover:bg-white/5 transition-colors`}>
                                <td className={`py-3 ${r.indent === 1 ? 'pl-8' : ''} ${r.bold ? 'font-semibold text-white' : 'text-slate-300'}`}>
                                    {r.label}
                                </td>
                                <td className={`py-3 text-right font-${r.size === 'lg' ? 'bold text-lg' : 'medium'} ${r.type === 'income' ? 'text-emerald-400' : r.type === 'profit' ? 'text-emerald-400' : r.type === 'loss' ? 'text-rose-400' : r.type === 'gross' ? 'text-blue-400' : 'text-rose-300'}`}>
                                    {r.type === 'deduction' ? `(${fmtRp(r.value)})` : fmtRp(r.value)}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </SectionCard>

            {/* Expense breakdown accordion */}
            {expSummary?.categories?.length > 0 && (
                <SectionCard title="Rincian Pengeluaran per Kategori" icon="list_alt">
                    <div className="flex flex-col gap-2">
                        {expSummary.categories.map((cat, i) => (
                            <div key={cat.category} className="border border-white/10 rounded-xl overflow-hidden">
                                <button
                                    onClick={() => setOpenCategory(openCategory === cat.category ? null : cat.category)}
                                    className="w-full flex items-center justify-between px-4 py-3 hover:bg-white/5 transition-colors text-left"
                                >
                                    <div className="flex items-center gap-3">
                                        <div className="w-3 h-3 rounded-full" style={{ background: EXPENSE_COLORS[i % EXPENSE_COLORS.length] }} />
                                        <span className="font-medium text-white">{cat.category}</span>
                                        <span className="text-slate-500 text-xs">{cat.count} transaksi</span>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <span className="text-rose-300 font-semibold">{fmtRp(cat.total)}</span>
                                        <span className="material-symbols-outlined text-slate-400 text-[18px]">
                                            {openCategory === cat.category ? 'expand_less' : 'expand_more'}
                                        </span>
                                    </div>
                                </button>
                                {openCategory === cat.category && (
                                    <div className="border-t border-white/10 bg-white/5 px-4 py-3">
                                        {(expensesByCategory[cat.category] || []).length === 0 ? (
                                            <p className="text-slate-500 text-sm">Tidak ada detail tersedia.</p>
                                        ) : (
                                            <table className="w-full text-sm">
                                                <thead>
                                                    <tr className="text-slate-500 text-xs">
                                                        <th className="py-1 text-left">Tanggal</th>
                                                        <th className="py-1 text-left">Deskripsi</th>
                                                        <th className="py-1 text-right">Jumlah</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    {expensesByCategory[cat.category].map(e => (
                                                        <tr key={e.id} className="border-t border-white/5">
                                                            <td className="py-2 text-slate-400">{fmtDate(e.createdAt)}</td>
                                                            <td className="py-2 text-slate-300">{e.description || '-'}</td>
                                                            <td className="py-2 text-right text-rose-300 font-medium">{fmtRp(e.amount)}</td>
                                                        </tr>
                                                    ))}
                                                </tbody>
                                            </table>
                                        )}
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                </SectionCard>
            )}
        </div>
    );
}

// ── Tab: Arus Kas ──────────────────────────────────────────────────
function TabCashFlow({ dateRange, branchId, onExport }) {
    const { data: cf, isLoading } = useCashFlow(dateRange.start, dateRange.end, branchId);

    const chartData = (cf || []).map(d => ({
        label: d.label,
        'Kas Masuk': d.cashIn,
        'Kas Keluar': d.cashOut,
        'Saldo Bersih': d.netFlow,
    }));

    const totals = (cf || []).reduce((acc, d) => ({
        cashIn: acc.cashIn + d.cashIn,
        cashOut: acc.cashOut + d.cashOut,
        net: acc.net + d.netFlow,
    }), { cashIn: 0, cashOut: 0, net: 0 });

    if (isLoading) return <SectionLoader message="Memuat arus kas..." />;

    return (
        <div className="flex flex-col gap-6">
            <div className="grid grid-cols-3 gap-4">
                <MetricCard label="Total Kas Masuk" value={fmtRp(totals.cashIn)} icon="arrow_downward" color="emerald-500" />
                <MetricCard label="Total Kas Keluar" value={fmtRp(totals.cashOut)} icon="arrow_upward" color="rose-500" />
                <MetricCard label="Saldo Bersih" value={fmtRp(totals.net)} icon="account_balance" color={totals.net >= 0 ? 'blue-500' : 'rose-500'} />
            </div>

            <SectionCard title="Grafik Arus Kas" icon="waterfall_chart">
                <ResponsiveContainer width="100%" height={240}>
                    <BarChart data={chartData} barSize={18}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" />
                        <XAxis dataKey="label" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                        <YAxis tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} tick={{ fill: '#94a3b8', fontSize: 11 }} axisLine={false} tickLine={false} />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend wrapperStyle={{ color: '#94a3b8', fontSize: 12 }} />
                        <Bar dataKey="Kas Masuk" fill="#10b981" radius={[4, 4, 0, 0]} />
                        <Bar dataKey="Kas Keluar" fill="#f43f5e" radius={[4, 4, 0, 0]} />
                    </BarChart>
                </ResponsiveContainer>
            </SectionCard>

            <SectionCard title="Mutasi Kas Harian" icon="list_alt" action={
                <button onClick={() => onExport('cash-flow')} className="flex items-center gap-1.5 text-sm text-primary hover:text-primary/80 transition-colors">
                    <span className="material-symbols-outlined text-[18px]">download</span> Export Excel
                </button>
            }>
                {!cf || cf.length === 0 ? (
                    <EmptyState icon="swap_horiz" title="Tidak ada data" description="Tidak ada transaksi di rentang waktu ini." />
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="border-b border-white/10 text-slate-400 text-xs uppercase">
                                    <th className="py-3 text-left">Tanggal</th>
                                    <th className="py-3 text-right">Kas Masuk</th>
                                    <th className="py-3 text-right">Kas Keluar</th>
                                    <th className="py-3 text-right">Saldo Bersih</th>
                                    <th className="py-3 text-right">Saldo Kumulatif</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-white/5">
                                {cf.map((row) => {
                                    const isToday = row.date === toISODate(new Date());
                                    const isNeg = row.netFlow < 0;
                                    return (
                                        <tr key={row.date} className={`hover:bg-white/5 transition-colors ${isToday ? 'bg-primary/5' : ''}`}>
                                            <td className={`py-3 font-medium ${isToday ? 'text-primary' : 'text-slate-300'}`}>
                                                {fmtDate(row.date)} {isToday && <span className="text-xs bg-primary/20 text-primary px-1.5 py-0.5 rounded ml-1">Hari ini</span>}
                                            </td>
                                            <td className="py-3 text-right text-emerald-400 font-medium">{fmtRp(row.cashIn)}</td>
                                            <td className="py-3 text-right text-rose-400 font-medium">{fmtRp(row.cashOut)}</td>
                                            <td className={`py-3 text-right font-semibold ${isNeg ? 'text-rose-400' : 'text-emerald-400'}`}>
                                                {isNeg ? '-' : '+'}{fmtRp(Math.abs(row.netFlow))}
                                            </td>
                                            <td className={`py-3 text-right font-medium ${row.runningBalance < 0 ? 'text-rose-400' : 'text-blue-400'}`}>
                                                {fmtRp(row.runningBalance)}
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                            <tfoot>
                                <tr className="border-t-2 border-white/20 font-bold text-white bg-white/5">
                                    <td className="py-3 pl-1">TOTAL</td>
                                    <td className="py-3 text-right text-emerald-400">{fmtRp(totals.cashIn)}</td>
                                    <td className="py-3 text-right text-rose-400">{fmtRp(totals.cashOut)}</td>
                                    <td className={`py-3 text-right ${totals.net >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>{fmtRp(totals.net)}</td>
                                    <td className="py-3 text-right text-blue-400">—</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                )}
            </SectionCard>
        </div>
    );
}

// ── Tab: Transaksi ─────────────────────────────────────────────────
function TabTransactions({ branchId, onExport }) {
    const [page, setPage] = useState(1);
    const perPage = 15;
    const { data: ordersData, isLoading } = useOrders({ branchId, page, limit: perPage });

    const orders = Array.isArray(ordersData) ? ordersData : ordersData?.data || [];
    const totalOrders = ordersData?.total || orders.length;
    const totalPages = Math.max(1, Math.ceil(totalOrders / perPage));

    const getMethod = (o) => o.paymentMethod || o.payments?.[0]?.method || 'Tunai';

    const statusColor = { Sukses: 'emerald', Pending: 'yellow', Batal: 'rose', completed: 'emerald', pending: 'yellow', cancelled: 'rose' };
    const statusLabel = { Sukses: 'Sukses', Pending: 'Pending', Batal: 'Batal', completed: 'Sukses', pending: 'Pending', cancelled: 'Batal' };

    return (
        <SectionCard title="Daftar Transaksi" icon="receipt_long" action={
            <button onClick={() => onExport('transactions')} className="flex items-center gap-1.5 text-sm text-primary hover:text-primary/80 transition-colors">
                <span className="material-symbols-outlined text-[18px]">download</span> Export Excel
            </button>
        }>
            <div className="overflow-x-auto">
                <table className="w-full text-sm">
                    <thead>
                        <tr className="border-b border-white/10 text-slate-400 text-xs uppercase">
                            <th className="py-3 text-left">Waktu</th>
                            <th className="py-3 text-left">No. Pesanan</th>
                            <th className="py-3 text-left">Tipe</th>
                            <th className="py-3 text-left">Metode</th>
                            <th className="py-3 text-left">Status</th>
                            <th className="py-3 text-right">Total</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5">
                        {isLoading ? (
                            <tr><td colSpan={6} className="p-8"><SectionLoader message="Memuat transaksi..." /></td></tr>
                        ) : orders.length === 0 ? (
                            <tr><td colSpan={6} className="p-8"><EmptyState icon="receipt_long" title="Belum ada transaksi" /></td></tr>
                        ) : orders.map((o) => {
                            const sc = statusColor[o.status] || 'slate';
                            return (
                                <tr key={o.id} className="hover:bg-white/5 transition-colors">
                                    <td className="py-3 text-slate-400">{o.createdAt ? new Date(o.createdAt).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-'}</td>
                                    <td className="py-3 text-white font-medium">#{o.orderNumber || o.id?.slice(0, 8)}</td>
                                    <td className="py-3 text-slate-300 capitalize">{o.orderType === 'dine_in' ? 'Dine In' : o.orderType === 'takeaway' ? 'Take Away' : o.orderType || '-'}</td>
                                    <td className="py-3">
                                        <span className={`px-2 py-0.5 rounded text-xs font-medium bg-blue-500/10 text-blue-400 border border-blue-500/20`}>{getMethod(o)}</span>
                                    </td>
                                    <td className="py-3">
                                        <span className={`inline-flex items-center gap-1 text-${sc}-400 text-xs font-medium`}>
                                            <span className={`w-1.5 h-1.5 rounded-full bg-${sc}-400`} />{statusLabel[o.status] || o.status}
                                        </span>
                                    </td>
                                    <td className={`py-3 text-right font-semibold ${o.status === 'cancelled' || o.status === 'Batal' ? 'text-slate-500 line-through' : 'text-white'}`}>
                                        {fmtRp(o.totalAmount ?? o.total)}
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
            {/* Pagination */}
            <div className="flex items-center justify-between border-t border-white/5 pt-4 mt-2">
                <span className="text-sm text-slate-400">
                    Menampilkan {orders.length > 0 ? (page - 1) * perPage + 1 : 0}–{Math.min(page * perPage, totalOrders)} dari {totalOrders}
                </span>
                <div className="flex gap-2">
                    <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1}
                        className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/10 text-slate-400 hover:bg-white/5 disabled:opacity-30">
                        <span className="material-symbols-outlined text-[18px]">chevron_left</span>
                    </button>
                    {Array.from({ length: Math.min(5, totalPages) }, (_, i) => i + Math.max(1, page - 2)).filter(p => p <= totalPages).map(p => (
                        <button key={p} onClick={() => setPage(p)}
                            className={`flex h-8 w-8 items-center justify-center rounded-lg text-sm font-bold transition-colors ${page === p ? 'bg-primary text-white' : 'border border-white/10 text-slate-400 hover:bg-white/5'}`}>
                            {p}
                        </button>
                    ))}
                    <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages}
                        className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/10 text-slate-400 hover:bg-white/5 disabled:opacity-30">
                        <span className="material-symbols-outlined text-[18px]">chevron_right</span>
                    </button>
                </div>
            </div>
        </SectionCard>
    );
}

// ── Main Component ─────────────────────────────────────────────────
export default function Laporan() {
    const [activeTab, setActiveTab] = useState('overview');
    const [selectedBranch, setSelectedBranch] = useState('');
    const [preset, setPreset] = useState('month');
    const [customStart, setCustomStart] = useState('');
    const [customEnd, setCustomEnd] = useState('');

    const { data: branches = [] } = useBranches();

    const dateRange = useMemo(() => {
        if (preset === 'custom' && customStart && customEnd) {
            return { start: customStart, end: customEnd };
        }
        return getPreset(preset);
    }, [preset, customStart, customEnd]);

    const branchId = selectedBranch || undefined;

    // Export to Excel
    const { data: plData } = useProfitLoss(dateRange.start, dateRange.end, branchId);
    const { data: cfData } = useCashFlow(dateRange.start, dateRange.end, branchId);
    const { data: txData } = useOrders({ branchId, page: 1, limit: 500 });

    const handleExport = useCallback((type) => {
        let sheetData = [];
        let fileName = 'laporan';

        if (type === 'profit-loss') {
            sheetData = [
                ['Laporan Laba Rugi', '', `${dateRange.start} s/d ${dateRange.end}`],
                [],
                ['Keterangan', 'Jumlah (Rp)'],
                ['Total Pendapatan', plData?.totalRevenue ?? 0],
                ['Total Pengeluaran', plData?.totalExpenses ?? 0],
                ['Laba Bersih', plData?.profit ?? 0],
            ];
            fileName = `laba-rugi_${dateRange.start}_${dateRange.end}`;
        } else if (type === 'cash-flow') {
            sheetData = [
                ['Laporan Arus Kas', '', `${dateRange.start} s/d ${dateRange.end}`],
                [],
                ['Tanggal', 'Kas Masuk (Rp)', 'Kas Keluar (Rp)', 'Saldo Bersih (Rp)', 'Saldo Kumulatif (Rp)'],
                ...(cfData || []).map(d => [d.date, d.cashIn, d.cashOut, d.netFlow, d.runningBalance]),
            ];
            fileName = `arus-kas_${dateRange.start}_${dateRange.end}`;
        } else if (type === 'transactions') {
            const orders = Array.isArray(txData) ? txData : txData?.data || [];
            sheetData = [
                ['Daftar Transaksi', '', `${dateRange.start} s/d ${dateRange.end}`],
                [],
                ['No. Pesanan', 'Waktu', 'Tipe', 'Metode', 'Status', 'Total (Rp)'],
                ...orders.map(o => [
                    o.orderNumber || o.id,
                    o.createdAt ? new Date(o.createdAt).toLocaleString('id-ID') : '-',
                    o.orderType || '-',
                    o.paymentMethod || '-',
                    o.status,
                    o.totalAmount ?? o.total ?? 0,
                ]),
            ];
            fileName = `transaksi_${dateRange.start}_${dateRange.end}`;
        }

        const wb = XLSX.utils.book_new();
        const ws = XLSX.utils.aoa_to_sheet(sheetData);
        XLSX.utils.book_append_sheet(wb, ws, 'Laporan');
        XLSX.writeFile(wb, `${fileName}.xlsx`);
    }, [plData, cfData, txData, dateRange]);

    const today = new Date().toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

    return (
        <div className="flex-1 flex flex-col h-screen relative overflow-hidden bg-background-dark">
            {/* Ambient glow */}
            <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-primary/10 rounded-full blur-[100px] pointer-events-none" />
            <div className="absolute bottom-[-20%] right-[-10%] w-[400px] h-[400px] bg-purple-500/10 rounded-full blur-[100px] pointer-events-none" />

            <div className="flex-1 overflow-y-auto overflow-x-hidden p-4 md:p-8 scroll-smooth">
                <div className="mx-auto max-w-7xl flex flex-col gap-6">

                    {/* Header */}
                    <header className="flex flex-col gap-4">
                        <div className="flex flex-col md:flex-row md:items-start justify-between gap-4">
                            <div>
                                <h2 className="text-2xl md:text-3xl font-bold text-white tracking-tight">Laporan Keuangan</h2>
                                <p className="text-slate-400 text-sm mt-1 flex items-center gap-1">
                                    <span className="material-symbols-outlined text-[16px]">calendar_today</span>
                                    {today}
                                </p>
                            </div>
                            <div className="flex flex-wrap items-center gap-3">
                                {/* Preset selector */}
                                <div className="flex items-center gap-1 glass-panel rounded-lg p-1">
                                    {[
                                        { id: 'today', label: 'Hari ini' },
                                        { id: 'week', label: '7 Hari' },
                                        { id: 'month', label: 'Bulan ini' },
                                        { id: '3month', label: '3 Bulan' },
                                        { id: 'custom', label: 'Kustom' },
                                    ].map(p => (
                                        <button key={p.id} onClick={() => setPreset(p.id)}
                                            className={`px-3 py-1.5 rounded-md text-sm font-medium transition-all ${preset === p.id ? 'bg-primary text-white shadow' : 'text-slate-400 hover:text-white'}`}>
                                            {p.label}
                                        </button>
                                    ))}
                                </div>

                                {/* Custom date range */}
                                {preset === 'custom' && (
                                    <div className="flex items-center gap-2">
                                        <input type="date" value={customStart} onChange={e => setCustomStart(e.target.value)}
                                            className="bg-[#111418] border border-white/10 text-white text-sm rounded-lg px-3 py-2 outline-none focus:ring-2 focus:ring-primary/50" />
                                        <span className="text-slate-500">–</span>
                                        <input type="date" value={customEnd} onChange={e => setCustomEnd(e.target.value)}
                                            className="bg-[#111418] border border-white/10 text-white text-sm rounded-lg px-3 py-2 outline-none focus:ring-2 focus:ring-primary/50" />
                                    </div>
                                )}

                                {/* Branch filter */}
                                <select value={selectedBranch} onChange={e => setSelectedBranch(e.target.value)}
                                    className="bg-[#111418] border border-white/10 text-slate-200 text-sm rounded-lg px-3 py-2 outline-none focus:ring-2 focus:ring-primary/50 cursor-pointer">
                                    <option value="">Semua Cabang</option>
                                    {branches.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                                </select>
                            </div>
                        </div>

                        {/* Date range display */}
                        <div className="flex items-center gap-2 text-sm text-slate-500">
                            <span className="material-symbols-outlined text-[16px]">date_range</span>
                            Menampilkan data: <span className="text-primary font-medium">{fmtDate(dateRange.start)}</span>
                            <span>–</span>
                            <span className="text-primary font-medium">{fmtDate(dateRange.end)}</span>
                        </div>
                    </header>

                    {/* Tabs */}
                    <div className="flex items-center gap-1 glass-panel rounded-xl p-1 overflow-x-auto">
                        {TABS.map(tab => (
                            <button key={tab.id} onClick={() => setActiveTab(tab.id)}
                                className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium whitespace-nowrap transition-all flex-1 justify-center ${activeTab === tab.id
                                    ? 'bg-primary text-white shadow-lg shadow-primary/25'
                                    : 'text-slate-400 hover:text-white hover:bg-white/5'
                                    }`}>
                                <span className="material-symbols-outlined text-[18px]">{tab.icon}</span>
                                {tab.label}
                            </button>
                        ))}
                    </div>

                    {/* Tab Content */}
                    <div>
                        {activeTab === 'overview' && <TabOverview dateRange={dateRange} branchId={branchId} />}
                        {activeTab === 'profit' && <TabProfitLoss dateRange={dateRange} branchId={branchId} onExport={handleExport} />}
                        {activeTab === 'cashflow' && <TabCashFlow dateRange={dateRange} branchId={branchId} onExport={handleExport} />}
                        {activeTab === 'transactions' && <TabTransactions branchId={branchId} onExport={handleExport} />}
                    </div>

                </div>
            </div>
        </div>
    );
}

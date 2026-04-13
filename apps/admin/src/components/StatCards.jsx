import React from 'react';
import { useReportSummary } from '../hooks/useReports';
import { SectionLoader } from './LoadingStates';

const STAT_CONFIG = [
    { key: 'totalRevenue', label: 'Total Omzet', icon: 'payments', iconColor: 'text-primary', format: 'currency' },
    { key: 'totalTransactions', label: 'Total Transaksi', icon: 'receipt', iconColor: 'text-purple-400', format: 'number' },
    { key: 'netProfit', label: 'Laba Bersih', icon: 'account_balance_wallet', iconColor: 'text-amber-400', format: 'currency' },
];

export default function StatCards() {
    const { data: summary, isLoading } = useReportSummary();

    const formatValue = (val, format) => {
        if (format === 'currency') return `Rp ${new Intl.NumberFormat('id-ID').format(val || 0)}`;
        return new Intl.NumberFormat('id-ID').format(val || 0);
    };

    if (isLoading) return <SectionLoader message="Memuat statistik..." />;

    return (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {STAT_CONFIG.map(stat => {
                const value = summary?.[stat.key] ?? 0;
                const growth = summary?.[`${stat.key}Growth`] ?? null;
                const isPositive = growth >= 0;

                return (
                    <div key={stat.key} className="glass-card relative overflow-hidden rounded-xl p-6 group">
                        <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                            <span className={`material-symbols-outlined text-6xl ${stat.iconColor}`}>{stat.icon}</span>
                        </div>
                        <div className="flex flex-col gap-1">
                            <p className="text-sm font-medium text-slate-400">{stat.label}</p>
                            <h3 className="font-display text-3xl font-bold text-white tracking-tight">
                                {formatValue(value, stat.format)}
                            </h3>
                            {growth !== null && (
                                <div className="flex items-center gap-2 mt-2">
                                    <span className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-bold ${isPositive ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'}`}>
                                        <span className="material-symbols-outlined text-[14px]">
                                            {isPositive ? 'trending_up' : 'trending_down'}
                                        </span>
                                        {isPositive ? '+' : ''}{growth}%
                                    </span>
                                    <span className="text-xs text-slate-500">vs periode lalu</span>
                                </div>
                            )}
                        </div>
                    </div>
                );
            })}
        </div>
    );
}

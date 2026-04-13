import React, { useState } from 'react';
import { useRevenueChart } from '../hooks/useReports';
import { SectionLoader, EmptyState } from './LoadingStates';
import {
    AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';

// Fallback demo data when API returns empty
const DEMO_DATA = [
    { date: 'Sen', revenue: 4200000 },
    { date: 'Sel', revenue: 5800000 },
    { date: 'Rab', revenue: 3500000 },
    { date: 'Kam', revenue: 7200000 },
    { date: 'Jum', revenue: 6100000 },
    { date: 'Sab', revenue: 8500000 },
    { date: 'Min', revenue: 6800000 },
];

const formatRp = (value) => {
    if (value >= 1000000) return `${(value / 1000000).toFixed(1)}jt`;
    if (value >= 1000) return `${(value / 1000).toFixed(0)}rb`;
    return value.toString();
};

const CustomTooltip = ({ active, payload, label }) => {
    if (!active || !payload?.length) return null;
    return (
        <div className="bg-[#1e293b] border border-white/10 rounded-lg px-4 py-3 shadow-2xl backdrop-blur-xl">
            <p className="text-xs font-bold text-slate-400 mb-2">{label}</p>
            {payload.map((entry, i) => (
                <div key={i} className="flex items-center gap-2 text-sm">
                    <span className="w-2 h-2 rounded-full" style={{ backgroundColor: entry.color }}></span>
                    <span className="text-slate-300">{entry.name}:</span>
                    <span className="font-bold text-white">Rp {new Intl.NumberFormat('id-ID').format(entry.value)}</span>
                </div>
            ))}
        </div>
    );
};

export default function RevenueChart() {
    const [days, setDays] = useState(7);
    const { data: apiData, isLoading } = useRevenueChart(days);

    // Use API data if available, otherwise demo data
    const chartData = apiData?.length > 0 ? apiData : DEMO_DATA;

    return (
        <div className="glass-card rounded-xl p-6">
            <div className="mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h3 className="text-lg font-bold text-white">Omzet Harian</h3>
                    <p className="text-sm text-slate-400">Performa pendapatan di cabang utama</p>
                </div>
                <div className="flex items-center gap-2">
                    {[7, 14, 30].map(d => (
                        <button
                            key={d}
                            onClick={() => setDays(d)}
                            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-colors ${days === d
                                    ? 'bg-primary/20 text-primary border border-primary/30'
                                    : 'text-slate-400 hover:bg-white/5 hover:text-white border border-white/10'
                                }`}
                        >
                            {d}H
                        </button>
                    ))}
                </div>
            </div>

            {isLoading ? (
                <div className="h-[300px] flex items-center justify-center">
                    <SectionLoader message="Memuat grafik..." />
                </div>
            ) : chartData.length === 0 ? (
                <div className="h-[300px] flex items-center justify-center">
                    <EmptyState icon="bar_chart" title="Belum ada data" description="Data omzet akan muncul setelah ada transaksi." />
                </div>
            ) : (
                <div className="h-[300px] w-full">
                    <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={chartData} margin={{ top: 5, right: 10, left: -10, bottom: 5 }}>
                            <defs>
                                <linearGradient id="gradientRevenue" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="0%" stopColor="#1f8fff" stopOpacity={0.3} />
                                    <stop offset="100%" stopColor="#1f8fff" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                            <XAxis
                                dataKey="date"
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#64748b', fontSize: 12, fontWeight: 500 }}
                            />
                            <YAxis
                                axisLine={false}
                                tickLine={false}
                                tickFormatter={formatRp}
                                tick={{ fill: '#64748b', fontSize: 11 }}
                                width={50}
                            />
                            <Tooltip content={<CustomTooltip />} cursor={{ stroke: 'rgba(255,255,255,0.1)' }} />
                            <Area
                                type="monotone"
                                dataKey="revenue"
                                name="Omzet"
                                stroke="#1f8fff"
                                strokeWidth={2.5}
                                fill="url(#gradientRevenue)"
                                dot={false}
                                activeDot={{ r: 5, fill: '#101418', stroke: '#1f8fff', strokeWidth: 2 }}
                            />
                        </AreaChart>
                    </ResponsiveContainer>
                </div>
            )}
        </div>
    );
}

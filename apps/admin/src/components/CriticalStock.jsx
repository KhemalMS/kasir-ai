import React from 'react';
import { useCriticalStock } from '../hooks/useReports';
import { SectionLoader, EmptyState } from './LoadingStates';

export default function CriticalStock() {
    const { data: criticalItems = [], isLoading } = useCriticalStock();

    const getItemStyle = (level) => {
        if (level === 'critical' || level === 'Habis') {
            return {
                border: 'border-red-500/20',
                bg: 'bg-red-500/5',
                hover: 'hover:bg-red-500/10',
                iconBg: 'bg-red-500/20',
                iconColor: 'text-red-400',
                textColor: 'text-red-300',
                icon: 'warning',
                label: 'Kritis',
            };
        }
        return {
            border: 'border-amber-500/20',
            bg: 'bg-amber-500/5',
            hover: 'hover:bg-amber-500/10',
            iconBg: 'bg-amber-500/20',
            iconColor: 'text-amber-400',
            textColor: 'text-amber-300',
            icon: 'priority_high',
            label: 'Rendah',
        };
    };

    return (
        <div className="glass-card rounded-xl p-6 flex flex-col h-full relative overflow-hidden">
            <div className="pointer-events-none absolute -top-10 -right-10 h-32 w-32 rounded-full bg-primary/20 blur-[40px]"></div>
            <div className="flex items-center justify-between mb-4 relative z-10">
                <div className="flex items-center gap-2">
                    <h3 className="text-lg font-bold text-white">Stok Kritis</h3>
                    <div className="flex items-center gap-1 rounded bg-primary/20 px-1.5 py-0.5 text-[10px] font-bold text-primary border border-primary/20">
                        <span className="material-symbols-outlined text-[12px]">auto_awesome</span>
                        PREDIKSI AI
                    </div>
                </div>
                <button className="text-xs font-medium text-primary hover:text-blue-400">Kelola Stok</button>
            </div>
            <div className="flex flex-col gap-3 relative z-10">
                {isLoading ? (
                    <SectionLoader message="Memuat stok..." />
                ) : criticalItems.length === 0 ? (
                    <EmptyState icon="check_circle" title="Stok aman" description="Tidak ada item dengan stok kritis saat ini." />
                ) : (
                    criticalItems.map((item, i) => {
                        const style = getItemStyle(item.level || item.status);
                        return (
                            <div key={item.id || i} className={`group flex items-center justify-between rounded-lg border ${style.border} ${style.bg} p-4 transition ${style.hover}`}>
                                <div className="flex items-center gap-3">
                                    <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${style.iconBg} ${style.iconColor}`}>
                                        <span className="material-symbols-outlined">{style.icon}</span>
                                    </div>
                                    <div>
                                        <h4 className="text-sm font-semibold text-white">{item.name}</h4>
                                        <p className={`text-xs ${style.textColor}`}>
                                            {style.label} • Sisa {item.quantity} {item.unit || ''}
                                        </p>
                                    </div>
                                </div>
                                <button className="rounded-action bg-primary px-3 py-1.5 text-xs font-bold text-white shadow-lg shadow-blue-500/20 hover:bg-blue-600 transition">
                                    Pesan Ulang
                                </button>
                            </div>
                        );
                    })
                )}
            </div>
        </div>
    );
}

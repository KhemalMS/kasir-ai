import React from 'react';
import { useTopProducts } from '../hooks/useReports';
import { SectionLoader, EmptyState } from './LoadingStates';

export default function TopProducts() {
    const { data: topProducts = [], isLoading } = useTopProducts(5);

    return (
        <div className="glass-card rounded-xl p-6 flex flex-col h-full">
            <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-white">Produk Terlaris</h3>
                <button className="text-xs font-medium text-primary hover:text-blue-400">Lihat Semua</button>
            </div>
            <div className="flex flex-col gap-4">
                {isLoading ? (
                    <SectionLoader message="Memuat produk..." />
                ) : topProducts.length === 0 ? (
                    <EmptyState icon="restaurant_menu" title="Belum ada data" description="Data produk terlaris akan muncul setelah ada transaksi." />
                ) : (
                    topProducts.map((product, i) => (
                        <div key={product.id || i} className="flex items-center justify-between p-3 rounded-lg hover:bg-white/5 transition border border-transparent hover:border-white/5">
                            <div className="flex items-center gap-3">
                                <div className="h-12 w-12 rounded-lg bg-gray-700 overflow-hidden flex items-center justify-center">
                                    {product.image ? (
                                        <img alt={product.name} className="h-full w-full object-cover" src={product.image} />
                                    ) : (
                                        <span className="material-symbols-outlined text-slate-500">fastfood</span>
                                    )}
                                </div>
                                <div>
                                    <h4 className="text-sm font-semibold text-white">{product.name}</h4>
                                    <p className="text-xs text-slate-400">{product.category || 'Produk'}</p>
                                </div>
                            </div>
                            <div className="text-right">
                                <p className="text-sm font-bold text-white">
                                    {new Intl.NumberFormat('id-ID').format(product.totalSold || 0)}
                                </p>
                                <p className="text-xs text-slate-400">Terjual</p>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}

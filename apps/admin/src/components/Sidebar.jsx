import React from 'react';
import { useAuth } from '../hooks/useAuth';

export default function Sidebar() {
    const { user } = useAuth();


    return (
        <aside className="hidden w-72 border-r border-white/10 bg-[#101418] dark:bg-[#101418] lg:flex lg:flex-col">
            <div className="flex h-20 items-center gap-3 px-6 border-b border-white/5 shrink-0">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/20 text-primary">
                    <span className="material-symbols-outlined text-3xl">restaurant_menu</span>
                </div>
                <div>
                    <h1 className="font-display text-lg font-bold leading-tight tracking-tight text-white">Kasir-AI</h1>
                    <p className="text-xs font-medium text-slate-400">{user?.name || 'Super Admin'}</p>
                </div>
            </div>
            <nav className="flex-1 flex flex-col gap-2 overflow-y-auto px-4 py-6">
                <a className="flex items-center gap-3 rounded-lg bg-primary/15 px-4 py-3 text-primary transition-colors" href="#">
                    <span className="material-symbols-outlined filled">dashboard</span>
                    <span className="font-medium">Beranda</span>
                </a>
                <a className="flex items-center gap-3 rounded-lg px-4 py-3 text-slate-400 hover:bg-white/5 hover:text-white transition-colors" href="#">
                    <span className="material-symbols-outlined">receipt_long</span>
                    <span className="font-medium">Transaksi</span>
                </a>
                <a className="flex items-center gap-3 rounded-lg px-4 py-3 text-slate-400 hover:bg-white/5 hover:text-white transition-colors" href="#">
                    <span className="material-symbols-outlined">inventory_2</span>
                    <span className="font-medium">Inventaris</span>
                </a>
                <a className="flex items-center gap-3 rounded-lg px-4 py-3 text-slate-400 hover:bg-white/5 hover:text-white transition-colors" href="#">
                    <span className="material-symbols-outlined">account_balance_wallet</span>
                    <span className="font-medium">Pengeluaran</span>
                </a>
                <a className="flex items-center gap-3 rounded-lg px-4 py-3 text-slate-400 hover:bg-white/5 hover:text-white transition-colors" href="#">
                    <span className="material-symbols-outlined">group</span>
                    <span className="font-medium">Staf</span>
                </a>
                <a className="flex items-center gap-3 rounded-lg px-4 py-3 text-slate-400 hover:bg-white/5 hover:text-white transition-colors" href="#">
                    <span className="material-symbols-outlined">store</span>
                    <span className="font-medium">Cabang</span>
                </a>
                <a className="flex items-center gap-3 rounded-lg px-4 py-3 text-slate-400 hover:bg-white/5 hover:text-white transition-colors" href="#">
                    <span className="material-symbols-outlined">settings</span>
                    <span className="font-medium">Pengaturan</span>
                </a>
                <div className="my-2 border-t border-white/10"></div>
                <a className="group flex items-center gap-3 rounded-lg px-4 py-3 text-slate-400 hover:bg-white/5 hover:text-white transition-colors" href="#">
                    <span className="material-symbols-outlined text-purple-400 group-hover:text-purple-300">auto_awesome</span>
                    <span className="font-medium bg-gradient-to-r from-purple-400 to-primary bg-clip-text text-transparent group-hover:from-purple-300 group-hover:to-blue-300">Wawasan AI</span>
                </a>
            </nav>
        </aside>
    );
}

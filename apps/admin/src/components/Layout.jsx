import React from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';

export default function Layout() {
    const navigate = useNavigate();

    return (
        <div className="flex h-screen w-full overflow-hidden bg-background-dark text-slate-100 font-display antialiased">
            <aside className="hidden w-72 flex-col border-r border-[#1e293b] bg-[#111418] lg:flex">
                <div className="flex h-full flex-col justify-between p-4">
                    <div className="flex flex-col gap-4">
                        <div className="flex items-center gap-3 px-2 py-3">
                            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-blue-600 shadow-lg shadow-blue-900/20">
                                <span className="material-symbols-outlined text-white">smart_toy</span>
                            </div>
                            <div className="flex flex-col">
                                <h1 className="text-lg font-bold text-white">Kasir-AI</h1>
                                <p className="text-xs text-slate-400">Cabang Pusat</p>
                            </div>
                        </div>
                        <nav className="flex flex-col gap-2">
                            <NavLink
                                to="/dashboard"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                <span className={`material-symbols-outlined`}>dashboard</span>
                                <span className="text-sm font-medium">Beranda</span>
                            </NavLink>
                            <NavLink
                                to="/transaksi"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>receipt_long</span>
                                        <span className="text-sm font-medium">Transaksi</span>
                                    </>
                                )}
                            </NavLink>
                            <NavLink
                                to="/inventaris"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>inventory_2</span>
                                        <span className="text-sm font-medium">Inventaris</span>
                                    </>
                                )}
                            </NavLink>
                            <NavLink
                                to="/produk"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>local_offer</span>
                                        <span className="text-sm font-medium">Produk</span>
                                    </>
                                )}
                            </NavLink>
                            <NavLink
                                to="/pengeluaran"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>account_balance_wallet</span>
                                        <span className="text-sm font-medium">Pengeluaran</span>
                                    </>
                                )}
                            </NavLink>
                            <NavLink
                                to="/staf"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>group</span>
                                        <span className="text-sm font-medium">Staf</span>
                                    </>
                                )}
                            </NavLink>
                            <NavLink
                                to="/cabang"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>store</span>
                                        <span className="text-sm font-medium">Cabang</span>
                                    </>
                                )}
                            </NavLink>
                            <NavLink
                                to="/laporan"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>bar_chart</span>
                                        <span className="text-sm font-medium">Laporan</span>
                                    </>
                                )}
                            </NavLink>
                            <div className="my-2 border-t border-slate-800"></div>
                            <NavLink
                                to="/pengaturan"
                                className={({ isActive }) =>
                                    `flex items-center gap-3 rounded-lg px-3 py-2 transition-colors ${isActive
                                        ? 'bg-primary/10 text-primary ring-1 ring-primary/20'
                                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                                    }`
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <span className={`material-symbols-outlined ${isActive ? 'fill-1' : ''}`}>settings</span>
                                        <span className="text-sm font-medium">Pengaturan</span>
                                    </>
                                )}
                            </NavLink>
                        </nav>
                    </div>
                </div>
            </aside>

            <main className="flex h-full flex-1 flex-col overflow-hidden bg-background-dark relative">
                <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none z-0">
                    <div className="absolute top-[-10%] left-[10%] w-[500px] h-[500px] bg-primary/10 rounded-full blur-[100px]"></div>
                    <div className="absolute bottom-[-10%] right-[5%] w-[400px] h-[400px] bg-blue-600/5 rounded-full blur-[80px]"></div>
                </div>

                <Outlet />
            </main>
        </div>
    );
}

import React, { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function Header() {
    const navigate = useNavigate();
    const { user, signOut } = useAuth();
    const [showMenu, setShowMenu] = useState(false);
    const menuRef = useRef(null);

    const handleLogout = async () => {
        setShowMenu(false);
        try {
            await signOut();
        } catch (e) {
            console.error('Sign out error:', e);
        }
        navigate('/login', { replace: true });
    };

    // Close menu when clicking outside
    useEffect(() => {
        const handleClickOutside = (e) => {
            if (menuRef.current && !menuRef.current.contains(e.target)) {
                setShowMenu(false);
            }
        };
        if (showMenu) document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, [showMenu]);

    return (
        <header className="glass-header sticky top-0 z-20 flex h-20 items-center justify-between px-8">
            <div className="flex items-center gap-4">
                <button className="lg:hidden text-slate-400 hover:text-white">
                    <span className="material-symbols-outlined">menu</span>
                </button>
                <div>
                    <h2 className="text-xl font-bold text-white tracking-tight">Kasir-AI | Semua Cabang</h2>
                    <p className="text-sm text-slate-400 hidden sm:block">Selamat datang kembali, {user?.name || 'Admin'}</p>
                </div>
            </div>
            <div className="flex items-center gap-4 md:gap-6">
                <div className="hidden md:flex items-center gap-2 rounded-action border border-white/10 bg-[#1b2128] px-3 py-2">
                    <span className="material-symbols-outlined text-slate-400 text-[20px]">store</span>
                    <select className="bg-transparent text-sm font-medium text-white border-none focus:ring-0 p-0 pr-6 cursor-pointer">
                        <option>Semua Cabang</option>
                    </select>
                </div>
                <div className="hidden md:flex items-center gap-2 rounded-action border border-white/10 bg-[#1b2128] px-3 py-2">
                    <span className="material-symbols-outlined text-slate-400 text-[20px]">calendar_today</span>
                    <select className="bg-transparent text-sm font-medium text-white border-none focus:ring-0 p-0 pr-6 cursor-pointer">
                        <option>7 Hari Terakhir</option>
                        <option>30 Hari Terakhir</option>
                        <option>Bulan Ini</option>
                    </select>
                </div>
                <div className="h-8 w-[1px] bg-white/10 hidden md:block"></div>
                <button className="relative rounded-xl p-2 text-slate-400 hover:bg-white/5 hover:text-white transition">
                    <span className="material-symbols-outlined">notifications</span>
                    <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-red-500 border border-[#0f1115]"></span>
                </button>
                {/* Profile Button with Dropdown */}
                <div className="relative" ref={menuRef}>
                    <button
                        type="button"
                        onClick={() => setShowMenu(!showMenu)}
                        className="h-10 w-10 overflow-hidden rounded-full border-2 border-white/10 hover:border-primary/50 transition-colors cursor-pointer flex items-center justify-center bg-primary/20 text-primary font-bold text-sm"
                    >
                        {user?.name ? user.name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase() : 'AD'}
                    </button>
                    {showMenu && (
                        <div className="absolute right-0 top-14 w-56 bg-[#1e293b] border border-white/10 rounded-xl shadow-2xl py-2 z-50">
                            <div className="px-4 py-3 border-b border-white/10">
                                <p className="text-sm font-bold text-white">{user?.name || 'Admin'}</p>
                                <p className="text-xs text-slate-400 truncate">{user?.email || '-'}</p>
                            </div>
                            <button
                                type="button"
                                onClick={handleLogout}
                                className="w-full flex items-center gap-3 px-4 py-3 text-sm text-slate-300 hover:bg-rose-500/10 hover:text-red-400 transition-colors cursor-pointer"
                            >
                                <span className="material-symbols-outlined text-[18px]">logout</span>
                                Keluar
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </header>
    );
}

import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { updateUser, changePassword } from '../lib/auth-client';

export default function Profil() {
    const { user } = useAuth();
    const [name, setName] = useState(user?.name || '');
    const [isUpdatingName, setIsUpdatingName] = useState(false);
    
    const [oldPassword, setOldPassword] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [isUpdatingPassword, setIsUpdatingPassword] = useState(false);

    const handleUpdateProfile = async (e) => {
        e.preventDefault();
        setIsUpdatingName(true);
        try {
            const { error } = await updateUser({
                name,
            });
            if (error) throw new Error(error.message);
            alert('Profil berhasil diperbarui!');
        } catch (err) {
            alert('Gagal: ' + err.message);
        } finally {
            setIsUpdatingName(false);
        }
    };

    const handleUpdatePassword = async (e) => {
        e.preventDefault();
        if (newPassword !== confirmPassword) {
            alert('Password baru dan konfirmasi tidak cocok!');
            return;
        }
        setIsUpdatingPassword(true);
        try {
            const { error } = await changePassword({
                newPassword: newPassword,
                currentPassword: oldPassword,
                revokeOtherSessions: true,
            });
            if (error) throw new Error(error.message);
            alert('Password berhasil diubah!');
            setOldPassword('');
            setNewPassword('');
            setConfirmPassword('');
        } catch (err) {
            alert('Gagal: ' + err.message);
        } finally {
            setIsUpdatingPassword(false);
        }
    };

    return (
        <div className="flex-1 overflow-y-auto z-10">
            <div className="p-8 max-w-[1200px] mx-auto space-y-8">
                <div>
                    <h1 className="text-3xl font-bold text-white tracking-tight">Profil Akun</h1>
                    <p className="text-slate-400">Kelola informasi pribadi dan keamanan akun Anda.</p>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    {/* Kolom Kiri: Identitas Utama */}
                    <div className="lg:col-span-1 space-y-6">
                        <div className="glass-panel rounded-2xl p-8 flex flex-col items-center text-center">
                            <div className="size-28 rounded-full border-4 border-white/10 bg-primary/20 text-primary flex items-center justify-center text-4xl font-bold mb-4 shadow-xl">
                                {user?.name ? user.name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase() : 'AD'}
                            </div>
                            <h2 className="text-xl font-bold text-white mb-1">{user?.name}</h2>
                            <p className="text-slate-400 text-sm mb-4">{user?.email}</p>
                            <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-500/10 text-blue-400 border border-blue-500/20 text-xs font-bold uppercase tracking-wider">
                                <span className="material-symbols-outlined text-[16px]">verified_user</span>
                                {user?.role || 'Admin'}
                            </div>
                        </div>

                        <div className="glass-panel rounded-2xl p-6">
                            <h3 className="text-lg font-bold text-white mb-4">Informasi Sesi</h3>
                            <div className="space-y-4">
                                <div className="flex items-start gap-3">
                                    <span className="material-symbols-outlined text-slate-500">login</span>
                                    <div>
                                        <p className="text-sm font-medium text-white">Terakhir Login</p>
                                        <p className="text-xs text-slate-400">Hari ini, 10:30 WIB</p>
                                    </div>
                                </div>
                                <div className="flex items-start gap-3">
                                    <span className="material-symbols-outlined text-slate-500">devices</span>
                                    <div>
                                        <p className="text-sm font-medium text-white">Perangkat Aktif</p>
                                        <p className="text-xs text-slate-400">Windows PC (Chrome)</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Kolom Kanan: Form Edit */}
                    <div className="lg:col-span-2 space-y-6">
                        <div className="glass-panel rounded-2xl p-6 md:p-8">
                            <div className="flex items-center gap-3 mb-6 border-b border-white/10 pb-4">
                                <span className="material-symbols-outlined text-blue-400">person</span>
                                <h3 className="text-lg font-bold text-white">Informasi Dasar</h3>
                            </div>
                            <form onSubmit={handleUpdateProfile} className="space-y-5">
                                <div className="flex flex-col gap-2">
                                    <label className="text-sm font-medium text-slate-300">Nama Lengkap</label>
                                    <input 
                                        type="text" 
                                        value={name}
                                        onChange={(e) => setName(e.target.value)}
                                        className="w-full bg-[#111418] border border-white/10 rounded-xl px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                        required
                                    />
                                </div>
                                <div className="flex flex-col gap-2">
                                    <label className="text-sm font-medium text-slate-300">Alamat Email</label>
                                    <input 
                                        type="email" 
                                        value={user?.email || ''}
                                        readOnly
                                        className="w-full bg-[#111418]/50 border border-white/5 rounded-xl px-4 py-3 text-slate-500 cursor-not-allowed"
                                    />
                                    <p className="text-xs text-slate-500">Email tidak dapat diubah saat ini.</p>
                                </div>
                                <div className="pt-2">
                                    <button 
                                        type="submit" 
                                        disabled={isUpdatingName}
                                        className="px-6 py-2.5 rounded-lg bg-primary hover:bg-blue-600 text-white text-sm font-bold shadow-lg shadow-primary/25 transition-all disabled:opacity-50"
                                    >
                                        {isUpdatingName ? 'Menyimpan...' : 'Simpan Perubahan'}
                                    </button>
                                </div>
                            </form>
                        </div>

                        <div className="glass-panel rounded-2xl p-6 md:p-8">
                            <div className="flex items-center gap-3 mb-6 border-b border-white/10 pb-4">
                                <span className="material-symbols-outlined text-orange-400">lock</span>
                                <h3 className="text-lg font-bold text-white">Ganti Password</h3>
                            </div>
                            <form onSubmit={handleUpdatePassword} className="space-y-5">
                                <div className="flex flex-col gap-2">
                                    <label className="text-sm font-medium text-slate-300">Password Lama</label>
                                    <input 
                                        type="password" 
                                        value={oldPassword}
                                        onChange={(e) => setOldPassword(e.target.value)}
                                        className="w-full bg-[#111418] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                        required
                                        placeholder="••••••••"
                                    />
                                </div>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Password Baru</label>
                                        <input 
                                            type="password" 
                                            value={newPassword}
                                            onChange={(e) => setNewPassword(e.target.value)}
                                            className="w-full bg-[#111418] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                            required
                                            placeholder="••••••••"
                                        />
                                    </div>
                                    <div className="flex flex-col gap-2">
                                        <label className="text-sm font-medium text-slate-300">Konfirmasi Password Baru</label>
                                        <input 
                                            type="password" 
                                            value={confirmPassword}
                                            onChange={(e) => setConfirmPassword(e.target.value)}
                                            className="w-full bg-[#111418] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                            required
                                            placeholder="••••••••"
                                        />
                                    </div>
                                </div>
                                <div className="pt-2">
                                    <button 
                                        type="submit" 
                                        disabled={isUpdatingPassword}
                                        className="px-6 py-2.5 rounded-lg bg-orange-500 hover:bg-orange-600 text-white text-sm font-bold shadow-lg shadow-orange-500/25 transition-all disabled:opacity-50"
                                    >
                                        {isUpdatingPassword ? 'Mengubah...' : 'Ubah Password'}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

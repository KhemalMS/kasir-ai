import React, { useState } from 'react';
import { useBranches, useCreateBranch, useUpdateBranch, useDeleteBranch } from '../hooks/useBranches';
import { SkeletonCard, ErrorBanner, EmptyState } from '../components/LoadingStates';

export default function Cabang() {
    const { data: branches = [], isLoading } = useBranches();
    const createBranch = useCreateBranch();
    const updateBranch = useUpdateBranch();
    const deleteBranch = useDeleteBranch();
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [currentBranch, setCurrentBranch] = useState(null);

    const openModal = (branch = null) => {
        setCurrentBranch(branch);
        setIsModalOpen(true);
    };

    const handleSave = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);

        const data = {
            name: formData.get('name'),
            locationCode: formData.get('locationCode'),
            address: formData.get('address'),
            manager: formData.get('manager'),
            staffCount: parseInt(formData.get('staffCount'), 10),
            status: formData.get('status') === 'true' ? 'Buka' : 'Tutup',
            img: formData.get('img') || null,
        };

        try {
            if (currentBranch) {
                await updateBranch.mutateAsync({ id: currentBranch.id, data });
            } else {
                await createBranch.mutateAsync(data);
            }
            setIsModalOpen(false);
        } catch (err) {
            alert('Gagal menyimpan: ' + err.message);
        }
    };

    const handleDelete = async (id) => {
        try {
            await deleteBranch.mutateAsync(id);
            setIsModalOpen(false);
        } catch (err) {
            alert('Gagal menghapus: ' + err.message);
        }
    };
    return (
        <div className="flex-1 h-screen overflow-y-auto bg-background-dark relative">
            <div className="absolute top-0 left-0 w-full h-[500px] bg-gradient-to-b from-primary/5 to-transparent pointer-events-none"></div>
            <div className="relative max-w-[1400px] mx-auto p-8">

                <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
                    <div className="space-y-2">
                        <h2 className="text-3xl font-bold text-white tracking-tight">Manajemen Cabang</h2>
                        <p className="text-slate-400">Ikhtisar semua lokasi toko dan status performa langsung.</p>
                    </div>
                    <button onClick={() => openModal(null)} className="flex items-center gap-2 bg-primary hover:bg-blue-600 text-white px-5 py-3 rounded-xl font-medium transition-all shadow-lg shadow-primary/25 hover:shadow-primary/40 active:scale-95 cursor-pointer">
                        <span className="material-symbols-outlined text-[20px]">add</span>
                        <span>Tambah Cabang Baru</span>
                    </button>
                </div>

                <div className="flex flex-col lg:flex-row gap-4 mb-8">
                    <div className="flex-1 glass-card rounded-xl p-1.5 flex items-center group focus-within:border-primary/50 transition-colors">
                        <div className="w-10 h-10 flex items-center justify-center text-slate-400">
                            <span className="material-symbols-outlined">search</span>
                        </div>
                        <input className="bg-transparent border-none text-white placeholder-slate-500 w-full focus:ring-0 text-sm h-full" placeholder="Cari cabang berdasarkan nama, manajer, atau lokasi..." type="text" />
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-6">

                    {isLoading ? <SkeletonCard count={4} /> : branches.length === 0 ? (
                        <div className="col-span-full">
                            <EmptyState icon="store" title="Belum ada cabang" description="Tambahkan cabang pertama Anda untuk memulai." />
                        </div>
                    ) : branches.map(branch => (
                        <div key={branch.id} className={`glass-card rounded-2xl p-5 flex flex-col gap-4 group transition-all duration-300 ${branch.status === 'Tutup' ? 'opacity-80 hover:opacity-100' : ''} ${branch.alertType === 'warning' ? 'relative overflow-hidden' : ''}`}>
                            {branch.alertType === 'warning' && (
                                <div className="absolute -top-10 -right-10 w-24 h-24 bg-amber-500/20 blur-2xl rounded-full pointer-events-none"></div>
                            )}
                            <div className="flex justify-between items-start relative z-10">
                                <div className="flex gap-3">
                                    <div className={`w-12 h-12 rounded-lg bg-surface-dark border border-white/10 overflow-hidden shrink-0 ${branch.status === 'Tutup' ? 'grayscale' : ''}`}>
                                        <img className="w-full h-full object-cover" data-alt={`Location of ${branch.name}`} src={branch.img} />
                                    </div>
                                    <div>
                                        <h3 className="text-white font-bold text-lg leading-tight group-hover:text-primary transition-colors">{branch.name}</h3>
                                        <p className="text-slate-400 text-xs mt-0.5">ID: {branch.locationCode}</p>
                                    </div>
                                </div>
                            </div>
                            <div className="h-px bg-white/10"></div>

                            <div className="grid grid-cols-2 gap-y-4 text-sm mt-1">
                                <div className="col-span-2 flex items-start gap-2 text-slate-300">
                                    <span className="material-symbols-outlined text-slate-500 text-[18px] mt-0.5">location_on</span>
                                    <span className="truncate">{branch.address}</span>
                                </div>
                                <div className="flex items-center gap-2 text-slate-300">
                                    <span className="material-symbols-outlined text-slate-500 text-[18px]">person</span>
                                    <span>{branch.manager}</span>
                                </div>
                                <div className="flex items-center gap-2 text-slate-300">
                                    <span className="material-symbols-outlined text-slate-500 text-[18px]">groups</span>
                                    <span>{branch.staffCount} Staf</span>
                                </div>
                            </div>
                            <div className="mt-auto pt-2">
                                <button onClick={() => openModal(branch)} className="w-full py-2 rounded-lg bg-surface-dark hover:bg-primary hover:text-white border border-white/10 hover:border-primary text-slate-300 text-sm font-medium transition-all flex items-center justify-center gap-2 group/btn cursor-pointer">
                                    Kelola Cabang
                                    <span className="material-symbols-outlined text-[16px] group-hover/btn:translate-x-1 transition-transform">arrow_forward</span>
                                </button>
                            </div>
                        </div>
                    ))}

                    <button onClick={() => openModal(null)} className="rounded-2xl border-2 border-dashed border-white/10 hover:border-primary/50 hover:bg-surface-dark/50 p-5 flex flex-col items-center justify-center gap-4 group transition-all duration-300 min-h-[280px] cursor-pointer">
                        <div className="w-16 h-16 rounded-full bg-surface-dark border border-white/10 flex items-center justify-center group-hover:bg-primary group-hover:border-primary transition-colors shadow-lg">
                            <span className="material-symbols-outlined text-slate-400 text-3xl group-hover:text-white">add</span>
                        </div>
                        <div className="text-center">
                            <h3 className="text-white font-bold text-lg group-hover:text-primary transition-colors">Buka Cabang Baru</h3>
                            <p className="text-slate-400 text-sm mt-1 max-w-[200px]">Konfigurasi lokasi, staf, dan inventaris untuk toko baru.</p>
                        </div>
                    </button>

                </div>
            </div>

            {/* Cabang Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-[#161b22] border border-white/10 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl animate-in fade-in zoom-in duration-200 flex flex-col max-h-[90vh]">
                        <div className="flex items-center justify-between p-6 border-b border-white/10 bg-white/5 shrink-0">
                            <h2 className="text-xl font-bold text-white">
                                {currentBranch ? 'Kelola Cabang' : 'Tambah Cabang Baru'}
                            </h2>
                            <button
                                onClick={() => setIsModalOpen(false)}
                                className="text-slate-400 hover:text-white transition-colors cursor-pointer"
                            >
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>

                        <div className="p-6 overflow-y-auto">
                            <form id="cabangForm" onSubmit={handleSave} className="flex flex-col gap-5">
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="flex flex-col gap-2 col-span-2 md:col-span-1">
                                        <label className="text-sm font-medium text-slate-300">Nama Cabang</label>
                                        <input
                                            name="name"
                                            defaultValue={currentBranch?.name || ''}
                                            required
                                            className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                            placeholder="Contoh: Batam Centre HQ"
                                        />
                                    </div>
                                    <div className="flex flex-col gap-2 col-span-2 md:col-span-1">
                                        <label className="text-sm font-medium text-slate-300">Kode Lokasi</label>
                                        <input
                                            name="locationCode"
                                            defaultValue={currentBranch?.locationCode || ''}
                                            required
                                            className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                            placeholder="Contoh: #HQ-001"
                                        />
                                    </div>
                                </div>
                                <div className="flex flex-col gap-2">
                                    <label className="text-sm font-medium text-slate-300">Alamat Lengkap</label>
                                    <textarea
                                        name="address"
                                        defaultValue={currentBranch?.address || ''}
                                        required
                                        className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all resize-none h-20"
                                        placeholder="Alamat fisik cabang..."
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="flex flex-col gap-2 col-span-2 md:col-span-1">
                                        <label className="text-sm font-medium text-slate-300">Manajer Cabang</label>
                                        <input
                                            name="manager"
                                            defaultValue={currentBranch?.manager || ''}
                                            required
                                            className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                            placeholder="Nama manajer..."
                                        />
                                    </div>
                                    <div className="flex flex-col gap-2 col-span-2 md:col-span-1">
                                        <label className="text-sm font-medium text-slate-300">Jumlah Staf Dasar</label>
                                        <input
                                            name="staffCount"
                                            type="number"
                                            min="0"
                                            defaultValue={currentBranch?.staffCount || 0}
                                            required
                                            className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                                        />
                                    </div>
                                </div>
                                <div className="flex flex-col gap-2 mb-2">
                                    <label className="text-sm font-medium text-slate-300">Status Operasional</label>
                                    <select
                                        name="status"
                                        defaultValue={currentBranch?.status === 'Buka' ? 'true' : 'false'}
                                        className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all cursor-pointer"
                                    >
                                        <option value="true">Buka Sekarang</option>
                                        <option value="false">Tutup Sementara</option>
                                    </select>
                                </div>
                                <div className="flex flex-col gap-2">
                                    <label className="text-sm font-medium text-slate-300">URL Gambar (Opsional)</label>
                                    <input
                                        name="img"
                                        defaultValue={currentBranch?.img || ''}
                                        className="w-full bg-[#111418] border border-white/10 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all text-xs font-mono"
                                        placeholder="https://images.unsplash..."
                                    />
                                </div>
                            </form>
                        </div>

                        <div className="p-6 border-t border-white/10 bg-white/5 flex items-center shrink-0">
                            {currentBranch && (
                                <button
                                    type="button"
                                    onClick={() => handleDelete(currentBranch.id)}
                                    className="px-5 py-2.5 rounded-lg text-sm font-medium text-red-500 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 transition-colors cursor-pointer mr-auto"
                                >
                                    Hapus
                                </button>
                            )}
                            <div className="flex-1"></div>
                            <div className="flex gap-3">
                                <button
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="px-5 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:text-white hover:bg-white/5 transition-colors cursor-pointer"
                                >
                                    Batal
                                </button>
                                <button
                                    type="submit"
                                    form="cabangForm"
                                    className="bg-primary hover:bg-blue-600 text-white px-5 py-2.5 rounded-lg text-sm font-bold shadow-lg shadow-primary/20 transition-all active:scale-95 cursor-pointer"
                                >
                                    Simpan Cabang
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

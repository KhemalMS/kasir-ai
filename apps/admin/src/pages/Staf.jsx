import React, { useState } from 'react';
import { useStaff, useCreateStaff, useUpdateStaff, useDeleteStaff } from '../hooks/useStaff';
import { SkeletonRow, EmptyState } from '../components/LoadingStates';

export default function Staf() {
    const [searchQuery, setSearchQuery] = useState('');
    const { data: staffList = [], isLoading } = useStaff({ search: searchQuery || undefined });
    const createStaff = useCreateStaff();
    const updateStaff = useUpdateStaff();
    const deleteStaff = useDeleteStaff();
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [currentStaf, setCurrentStaf] = useState(null);

    const openModal = (staf = null) => {
        setCurrentStaf(staf);
        setIsModalOpen(true);
    };

    const handleSave = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const nameData = formData.get('name');

        const data = {
            name: nameData,
            email: formData.get('email'),
            role: formData.get('role'),
            branchId: formData.get('branch'),
            status: formData.get('status') === 'true' ? 'Aktif' : 'Tidak Aktif',
            img: formData.get('img') || null,
        };

        try {
            if (currentStaf) {
                await updateStaff.mutateAsync({ id: currentStaf.id, data });
            } else {
                await createStaff.mutateAsync(data);
            }
            setIsModalOpen(false);
        } catch (err) {
            alert('Gagal menyimpan: ' + err.message);
        }
    };

    const handleDelete = async (id) => {
        try {
            await deleteStaff.mutateAsync(id);
            setIsModalOpen(false);
        } catch (err) {
            alert('Gagal menghapus: ' + err.message);
        }
    };

    const filteredStaff = staffList.filter(staf =>
        staf.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        staf.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        staf.role.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <>
            <div className="flex-1 overflow-y-auto z-10">
                <div className="p-8 max-w-[1600px] mx-auto space-y-6">
                    <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
                        <div>
                            <div className="flex items-center gap-2 mb-1">
                                <h1 className="text-3xl font-bold text-white tracking-tight">Manajemen Staff</h1>
                                <span className="px-2 py-0.5 rounded-md bg-green-500/10 text-green-400 text-xs font-medium border border-green-500/20">Sistem Online</span>
                            </div>
                            <p className="text-slate-400">Kelola akses, peran, dan kinerja di seluruh 12 cabang.</p>
                        </div>
                        <div className="flex items-center gap-3">
                            <button onClick={() => openModal()} className="flex items-center gap-2 px-4 py-2.5 rounded-lg bg-primary hover:bg-blue-600 text-white shadow-lg shadow-primary/25 transition-all text-sm font-bold">
                                <span className="material-symbols-outlined text-lg">add</span>
                                Tambah Staff
                            </button>
                        </div>
                    </div>

                    <div className="glass-panel rounded-xl p-4 flex flex-col md:flex-row gap-4 items-center justify-between">
                        <div className="flex items-center flex-1 w-full md:w-auto gap-4">
                            <div className="relative w-full md:max-w-md group">
                                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors">search</span>
                                <input value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full bg-[#111418] border border-[#3b4754] text-slate-200 text-sm rounded-lg pl-10 pr-4 py-2.5 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all placeholder:text-slate-500" placeholder="Cari karyawan berdasarkan nama, peran atau email..." type="text" />
                            </div>
                            <div className="relative hidden md:block">
                                <select className="appearance-none bg-[#111418] border border-[#3b4754] text-slate-200 text-sm rounded-lg pl-4 pr-10 py-2.5 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none cursor-pointer">
                                    <option>Semua Cabang</option>
                                    <option>Pusat Kota (HQ)</option>
                                    <option>Uptown Mall</option>
                                    <option>Westside Plaza</option>
                                </select>
                                <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none text-lg">expand_more</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-2 w-full md:w-auto justify-end">
                            <button className="p-2.5 rounded-lg hover:bg-white/5 text-slate-400 hover:text-white transition-colors border border-transparent hover:border-white/10" title="Filter list">
                                <span className="material-symbols-outlined">filter_list</span>
                            </button>
                            <button className="p-2.5 rounded-lg hover:bg-white/5 text-slate-400 hover:text-white transition-colors border border-transparent hover:border-white/10" title="Export data">
                                <span className="material-symbols-outlined">download</span>
                            </button>
                        </div>
                    </div>

                    <div className="glass-panel rounded-xl overflow-hidden border border-[#3b4754] flex flex-col">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-white/5 text-slate-400 text-xs uppercase tracking-wider font-semibold border-b border-white/5">
                                        <th className="px-6 py-4 w-12">
                                            <input className="rounded border-slate-600 bg-[#111418] text-primary focus:ring-offset-0 focus:ring-primary/50" type="checkbox" />
                                        </th>
                                        <th className="px-6 py-4 min-w-[240px]">Karyawan</th>
                                        <th className="px-6 py-4">Peran</th>
                                        <th className="px-6 py-4">Cabang</th>
                                        <th className="px-6 py-4">Status</th>
                                        <th className="px-6 py-4">Terakhir Aktif</th>
                                        <th className="px-6 py-4 text-right">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-white/5 text-sm">
                                    {isLoading ? (
                                        <tr><td colSpan="7" className="p-0"><SkeletonRow count={5} /></td></tr>
                                    ) : filteredStaff.length === 0 ? (
                                        <tr><td colSpan="7"><EmptyState icon="group" title="Belum ada staf" description="Tambahkan staf untuk memulai." /></td></tr>
                                    ) : filteredStaff.map((staff) => (
                                        <tr key={staff.id} className="group hover:bg-white/[0.02] transition-colors">
                                            <td className="px-6 py-4">
                                                <input className="rounded border-slate-600 bg-[#111418] text-primary focus:ring-offset-0 focus:ring-primary/50 opacity-0 group-hover:opacity-100 transition-opacity" type="checkbox" />
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-3">
                                                    <div className="h-10 w-10 rounded-full bg-slate-700 overflow-hidden border border-white/10 flex items-center justify-center text-slate-300 text-xs font-bold">
                                                        {staff.img ? (
                                                            <img alt={staff.name} className="h-full w-full object-cover" src={staff.img} />
                                                        ) : (
                                                            staff.initial || staff.name.substring(0, 2).toUpperCase()
                                                        )}
                                                    </div>
                                                    <div>
                                                        <p className="font-medium text-white flex items-center gap-2">
                                                            {staff.name}
                                                            {staff.isNew && <span className="px-1.5 py-0.5 rounded bg-blue-500/20 text-blue-400 text-[10px] font-bold uppercase tracking-wider">Baru</span>}
                                                        </p>
                                                        <p className="text-xs text-slate-500">{staff.email}</p>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium ${staff.role === 'Manager' || staff.role === 'Admin' ? 'bg-purple-500/10 text-purple-400 border border-purple-500/20' : staff.role === 'Kepala Koki' ? 'bg-orange-500/10 text-orange-400 border border-orange-500/20' : staff.role === 'Dapur' ? 'bg-pink-500/10 text-pink-400 border border-pink-500/20' : 'bg-blue-500/10 text-blue-400 border border-blue-500/20'}`}>
                                                    <span className={`w-1.5 h-1.5 rounded-full ${staff.role === 'Manager' || staff.role === 'Admin' ? 'bg-purple-400' : staff.role === 'Kepala Koki' ? 'bg-orange-400' : staff.role === 'Dapur' ? 'bg-pink-400' : 'bg-blue-400'}`}></span>
                                                    {staff.role}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-slate-300">{staff.branch}</td>
                                            <td className="px-6 py-4">
                                                <span className={`inline-flex px-2 py-1 rounded-full text-xs font-medium border ${staff.status === 'Aktif' ? 'bg-green-500/10 text-green-400 border-green-500/20' : 'bg-slate-700/50 text-slate-400 border-[#3b4754]'}`}>
                                                    {staff.status}
                                                </span>
                                            </td>
                                            <td className={`px-6 py-4 font-mono text-xs ${staff.activeText === 'Baru saja' ? 'text-green-400 font-semibold' : 'text-slate-400'}`}>
                                                {staff.activeText}
                                            </td>
                                            <td className="px-6 py-4 text-right">
                                                <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                                    <button onClick={() => openModal(staff)} className="p-1.5 rounded hover:bg-white/10 text-slate-400 hover:text-white transition-colors cursor-pointer">
                                                        <span className="material-symbols-outlined text-[20px]">edit</span>
                                                    </button>
                                                    <button onClick={() => handleDelete(staff.id)} className="p-1.5 rounded hover:bg-white/10 text-slate-400 hover:text-red-400 transition-colors cursor-pointer">
                                                        <span className="material-symbols-outlined text-[20px]">delete</span>
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        <div className="flex items-center justify-between px-6 py-4 border-t border-white/5 bg-white/[0.01]">
                            <p className="text-sm text-slate-400">Menampilkan <span className="text-white font-medium">1-6</span> dari <span className="text-white font-medium">48</span> anggota staff</p>
                            <div className="flex items-center gap-2">
                                <button className="px-3 py-1.5 rounded-lg border border-white/10 text-slate-400 text-sm hover:bg-white/5 hover:text-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed" disabled>
                                    Sebelumnya
                                </button>
                                <div className="flex items-center gap-1">
                                    <button className="w-8 h-8 rounded-lg bg-primary text-white text-sm font-medium flex items-center justify-center">1</button>
                                    <button className="w-8 h-8 rounded-lg hover:bg-white/5 text-slate-400 hover:text-white text-sm font-medium flex items-center justify-center transition-colors">2</button>
                                    <button className="w-8 h-8 rounded-lg hover:bg-white/5 text-slate-400 hover:text-white text-sm font-medium flex items-center justify-center transition-colors">3</button>
                                    <span className="text-slate-500 px-1">...</span>
                                    <button className="w-8 h-8 rounded-lg hover:bg-white/5 text-slate-400 hover:text-white text-sm font-medium flex items-center justify-center transition-colors">8</button>
                                </div>
                                <button className="px-3 py-1.5 rounded-lg border border-white/10 text-slate-400 text-sm hover:bg-white/5 hover:text-white transition-colors">
                                    Berikutnya
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-[#161b22] border border-white/10 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl animate-in fade-in zoom-in duration-200 flex flex-col max-h-[90vh]">
                        <div className="flex items-center justify-between p-6 border-b border-white/10 bg-white/5 shrink-0">
                            <h3 className="text-xl font-bold text-white tracking-tight">
                                {currentStaf ? 'Kelola Data Karyawan' : 'Tambah Karyawan Baru'}
                            </h3>
                            <button onClick={() => setIsModalOpen(false)} className="p-2 -mr-2 text-slate-400 hover:text-white hover:bg-white/10 rounded-xl transition-all cursor-pointer">
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>
                        <div className="p-6 overflow-y-auto">
                            <form id="stafForm" onSubmit={handleSave} className="flex flex-col gap-5">
                                <div className="space-y-4">
                                    <div className="space-y-2">
                                        <label className="text-sm font-semibold text-slate-300">Nama Lengkap</label>
                                        <input defaultValue={currentStaf?.name || ''} name="name" required className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all placeholder-slate-500" placeholder="John Doe" type="text" />
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-sm font-semibold text-slate-300">Email Utama</label>
                                        <input defaultValue={currentStaf?.email || ''} name="email" required className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all placeholder-slate-500" placeholder="john@kasir.ai" type="email" />
                                    </div>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <label className="text-sm font-semibold text-slate-300">Peran Karyawan</label>
                                            <select defaultValue={currentStaf?.role || 'Kasir'} name="role" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all appearance-none cursor-pointer">
                                                <option>Admin</option>
                                                <option>Manager</option>
                                                <option>Kepala Koki</option>
                                                <option>Dapur</option>
                                                <option>Kasir</option>
                                            </select>
                                        </div>
                                        <div className="space-y-2">
                                            <label className="text-sm font-semibold text-slate-300">Cabang Tugas</label>
                                            <select defaultValue={currentStaf?.branch || 'Downtown HQ'} name="branch" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all appearance-none cursor-pointer">
                                                <option>Downtown HQ</option>
                                                <option>Uptown Mall</option>
                                                <option>HQ Office</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-sm font-semibold text-slate-300">Status Akun</label>
                                        <select defaultValue={currentStaf?.status === 'Aktif' ? 'true' : 'false'} name="status" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all appearance-none cursor-pointer">
                                            <option value="true">Aktif</option>
                                            <option value="false">Tidak Aktif</option>
                                        </select>
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-sm font-semibold text-slate-300 flex items-center justify-between">
                                            <span>URL Foto Profil</span>
                                        </label>
                                        <input defaultValue={currentStaf?.img || ''} name="img" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none font-mono text-xs transition-all placeholder-slate-600 truncate" placeholder="https://images.unsplash..." type="url" />
                                    </div>
                                </div>
                            </form>
                        </div>
                        <div className="p-6 border-t border-white/10 bg-white/5 flex items-center shrink-0">
                            {currentStaf && (
                                <button type="button" onClick={() => handleDelete(currentStaf.id)} className="px-4 py-2.5 rounded-lg border border-red-500/20 bg-red-500/10 text-red-400 hover:bg-red-500 hover:text-white text-sm font-bold transition-colors">
                                    Hapus
                                </button>
                            )}
                            <div className="flex-1"></div>
                            <div className="flex gap-3">
                                <button onClick={() => setIsModalOpen(false)} className="px-4 py-2.5 rounded-lg border border-white/10 text-slate-300 hover:bg-white/10 hover:text-white text-sm font-bold transition-colors cursor-pointer">
                                    Batal
                                </button>
                                <button type="submit" form="stafForm" className="px-6 py-2.5 rounded-lg bg-primary hover:bg-blue-600 text-white text-sm font-bold shadow-lg shadow-primary/25 transition-all cursor-pointer">
                                    Simpan Data
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}

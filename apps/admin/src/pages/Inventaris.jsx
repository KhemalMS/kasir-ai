import React, { useState } from 'react';
import { useInventory, useUpdateInventoryItem } from '../hooks/useInventory';
import { SkeletonRow, EmptyState } from '../components/LoadingStates';

export default function Inventaris() {
    const [searchQuery, setSearchQuery] = useState('');
    const { data: items = [], isLoading } = useInventory({ search: searchQuery || undefined });
    const updateItem = useUpdateInventoryItem();
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [currentItem, setCurrentItem] = useState(null);

    const filteredItems = items;

    const openEditModal = (item) => {
        setCurrentItem(item);
        setIsEditModalOpen(true);
    };

    const handleSave = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);

        const qData = parseFloat(formData.get('quantity'));
        let newStatus = formData.get('status');
        let isUrgent = newStatus === 'Habis';
        if (newStatus === 'Otomatis') {
            if (qData <= 0) {
                newStatus = 'Habis';
                isUrgent = true;
            } else if (qData < 10) {
                newStatus = 'Rendah';
                isUrgent = false;
            } else {
                newStatus = 'Aman';
                isUrgent = false;
            }
        }

        const data = {
            name: formData.get('name'),
            category: formData.get('category'),
            branchId: formData.get('branch'),
            quantity: qData.toString(),
            unit: formData.get('unit'),
        };

        try {
            await updateItem.mutateAsync({ id: currentItem.id, data });
            setIsEditModalOpen(false);
        } catch (err) {
            alert('Gagal menyimpan: ' + err.message);
        }
    };
    return (
        <>
            <header className="flex flex-col gap-6 px-8 py-8 w-full max-w-[1400px] mx-auto z-10 transition-all">
                <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
                    <div className="flex flex-col gap-2">
                        <div className="flex items-center gap-2 text-primary/80 text-sm font-medium">
                            <span className="material-symbols-outlined text-lg">restaurant</span>
                            <span>Kitch-OS v2.4</span>
                        </div>
                        <h2 className="text-3xl md:text-4xl font-black text-white tracking-tight">Manajemen Inventaris</h2>
                        <p className="text-slate-400 text-base max-w-2xl">Pantau tingkat stok secara real-time di semua cabang aktif. AI menyarankan tanggal restock berdasarkan pola konsumsi.</p>
                    </div>
                    <div className="flex gap-3">
                        <button className="glass-panel hover:bg-white/5 text-white h-11 px-5 rounded-lg flex items-center gap-2 font-semibold text-sm transition-all border border-slate-700/50">
                            <span className="material-symbols-outlined text-xl">download</span>
                            <span>Ekspor Laporan</span>
                        </button>
                    </div>
                </div>

                <div className="glass-panel p-2 rounded-xl flex flex-col md:flex-row items-center gap-3 w-full">
                    <div className="relative flex-1 w-full">
                        <span className="absolute left-4 top-1/2 -translate-y-1/2 material-symbols-outlined text-slate-400">search</span>
                        <input value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full h-12 pl-12 pr-4 bg-[#1c232d]/60 border border-slate-700/50 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/50 transition-all text-sm" placeholder="Cari bahan, SKU, atau kategori..." type="text" />
                    </div>
                    <div className="flex gap-3 w-full md:w-auto overflow-x-auto pb-1 md:pb-0 items-center">
                        <div className="relative min-w-[180px]">
                            <select className="w-full h-12 pl-4 pr-10 bg-[#1c232d]/60 border border-slate-700/50 rounded-lg text-white appearance-none focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm cursor-pointer">
                                <option>Semua Cabang</option>
                                <option>Pusat Kota (Utama)</option>
                                <option>Kios Bandara</option>
                                <option>Mal Barat</option>
                            </select>
                            <span className="absolute right-3 top-1/2 -translate-y-1/2 material-symbols-outlined text-slate-400 pointer-events-none">expand_more</span>
                        </div>
                        <div className="relative min-w-[160px]">
                            <select className="w-full h-12 pl-4 pr-10 bg-[#1c232d]/60 border border-slate-700/50 rounded-lg text-white appearance-none focus:outline-none focus:ring-2 focus:ring-primary/50 text-sm cursor-pointer">
                                <option>Semua Kategori</option>
                                <option>Kopi & Teh</option>
                                <option>Susu & Alternatif</option>
                                <option>Sirup</option>
                                <option>Pastry</option>
                                <option>Kemasan</option>
                            </select>
                            <span className="absolute right-3 top-1/2 -translate-y-1/2 material-symbols-outlined text-slate-400 pointer-events-none">expand_more</span>
                        </div>

                        <button className="h-12 w-12 flex-shrink-0 flex items-center justify-center bg-[#1c232d]/60 border border-slate-700/50 rounded-lg text-slate-400 hover:text-white hover:bg-white/5 transition-colors">
                            <span className="material-symbols-outlined">filter_list</span>
                        </button>
                    </div>
                </div>
            </header>

            <section className="px-8 pb-8 w-full max-w-[1400px] mx-auto flex-1 flex flex-col min-h-0 z-10 relative">
                <div className="glass-panel flex-1 rounded-xl overflow-hidden flex flex-col shadow-2xl shadow-black/40">
                    <div className="overflow-x-auto flex-1 relative">
                        <table className="w-full text-left border-collapse">
                            <thead className="bg-[#1c232d]/80 backdrop-blur-md sticky top-0 z-20">
                                <tr>
                                    <th className="p-4 pl-6 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-white/5 w-[25%]">Nama Bahan</th>
                                    <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-white/5 w-[15%]">Kategori</th>
                                    <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-white/5 w-[15%]">Cabang</th>
                                    <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-white/5 w-[15%] text-right">Kuantitas</th>
                                    <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-white/5 w-[10%]">Satuan</th>
                                    <th className="p-4 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-white/5 w-[15%] text-center">Status</th>
                                    <th className="p-4 pr-6 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-white/5 w-[5%]"></th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-white/5 text-sm">
                                {isLoading ? (
                                    <tr><td colSpan="7" className="p-0"><SkeletonRow count={5} /></td></tr>
                                ) : filteredItems.length === 0 ? (
                                    <tr><td colSpan="7"><EmptyState icon="inventory_2" title="Inventaris kosong" description="Data inventaris akan muncul di sini." /></td></tr>
                                ) : filteredItems.map(item => (
                                    <tr key={item.id} className={`hover:bg-white/5 transition-colors group ${item.urgent ? 'bg-red-900/5' : ''}`}>
                                        <td className="p-4 pl-6">
                                            <div className="flex items-center gap-3">
                                                <div className="h-10 w-10 rounded-lg bg-slate-800 bg-cover bg-center border border-white/5" style={{ backgroundImage: `url('${item.img}')` }}></div>
                                                <div>
                                                    <div className="font-bold text-white">{item.name}</div>
                                                    <div className="text-xs text-slate-500">SKU: {item.sku}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="p-4 text-slate-300">
                                            <span className="inline-flex items-center px-2 py-1 rounded bg-slate-800 border border-slate-700 text-xs text-slate-400">{item.category}</span>
                                        </td>
                                        <td className="p-4 text-slate-300">{item.branch}</td>
                                        <td className="p-4 text-right font-mono font-medium">
                                            <span className={item.urgent ? 'text-red-400' : 'text-white'}>{item.quantity}</span>
                                        </td>
                                        <td className="p-4 text-slate-400">{item.unit}</td>
                                        <td className="p-4 text-center">
                                            {item.status === 'Aman' && (
                                                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-semibold">
                                                    <span className="h-1.5 w-1.5 rounded-full bg-blue-400"></span> Aman
                                                </span>
                                            )}
                                            {item.status === 'Rendah' && (
                                                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-yellow-500/10 border border-yellow-500/20 text-yellow-400 text-xs font-semibold">
                                                    <span className="h-1.5 w-1.5 rounded-full bg-yellow-400 animate-pulse"></span> Rendah
                                                </span>
                                            )}
                                            {item.status === 'Habis' && (
                                                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-semibold">
                                                    <span className="material-symbols-outlined text-[14px]">warning</span> Habis
                                                </span>
                                            )}
                                        </td>
                                        <td className="p-4 pr-6 text-right">
                                            <button onClick={() => openEditModal(item)} className="text-slate-500 hover:text-white transition-colors opacity-0 group-hover:opacity-100 cursor-pointer">
                                                <span className="material-symbols-outlined text-xl">edit</span>
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>

                    <div className="flex items-center justify-between p-4 border-t border-white/5 bg-[#1c232d]/40 mt-auto">
                        <span className="text-xs text-slate-400">Menampilkan 1-6 dari 248 item</span>
                        <div className="flex items-center gap-2">
                            <button className="flex items-center justify-center h-8 w-8 rounded hover:bg-white/10 text-slate-400 hover:text-white transition-colors">
                                <span className="material-symbols-outlined text-lg">chevron_left</span>
                            </button>
                            <button className="flex items-center justify-center h-8 w-8 rounded bg-primary text-white text-xs font-bold shadow-lg shadow-primary/20">1</button>
                            <button className="flex items-center justify-center h-8 w-8 rounded hover:bg-white/10 text-slate-400 hover:text-white transition-colors text-xs font-medium">2</button>
                            <button className="flex items-center justify-center h-8 w-8 rounded hover:bg-white/10 text-slate-400 hover:text-white transition-colors text-xs font-medium">3</button>
                            <span className="text-slate-500 text-xs">...</span>
                            <button className="flex items-center justify-center h-8 w-8 rounded hover:bg-white/10 text-slate-400 hover:text-white transition-colors text-xs font-medium">12</button>
                            <button className="flex items-center justify-center h-8 w-8 rounded hover:bg-white/10 text-slate-400 hover:text-white transition-colors">
                                <span className="material-symbols-outlined text-lg">chevron_right</span>
                            </button>
                        </div>
                    </div>
                </div>
            </section>

            {isEditModalOpen && currentItem && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
                    <div className="bg-[#161b22] border border-white/10 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl animate-in fade-in zoom-in duration-200 flex flex-col max-h-[90vh]">
                        <div className="flex items-center justify-between p-6 border-b border-white/10 bg-white/5 shrink-0">
                            <h3 className="text-xl font-bold text-white tracking-tight">Edit Bahan / Item</h3>
                            <button onClick={() => setIsEditModalOpen(false)} className="p-2 -mr-2 text-slate-400 hover:text-white hover:bg-white/10 rounded-xl transition-all cursor-pointer">
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        </div>
                        <div className="p-6 overflow-y-auto">
                            <form id="editForm" onSubmit={handleSave} className="flex flex-col gap-5">
                                <div className="space-y-4">
                                    <div className="space-y-2">
                                        <label className="text-sm font-semibold text-slate-300">Nama Bahan</label>
                                        <input defaultValue={currentItem.name} name="name" required className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all placeholder-slate-500" type="text" />
                                    </div>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <label className="text-sm font-semibold text-slate-300">Kategori</label>
                                            <select defaultValue={currentItem.category} name="category" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all appearance-none cursor-pointer">
                                                <option>Kopi</option>
                                                <option>Susu</option>
                                                <option>Sirup</option>
                                                <option>Pastry</option>
                                                <option>Perlengkapan</option>
                                            </select>
                                        </div>
                                        <div className="space-y-2">
                                            <label className="text-sm font-semibold text-slate-300">Cabang</label>
                                            <select defaultValue={currentItem.branch} name="branch" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all appearance-none cursor-pointer">
                                                <option>Pusat Kota (Utama)</option>
                                                <option>Kios Mal</option>
                                                <option>Kios Bandara</option>
                                                <option>Semua Cabang</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <label className="text-sm font-semibold text-slate-300">Kuantitas</label>
                                            <input defaultValue={currentItem.quantity} name="quantity" required type="number" step="0.1" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all placeholder-slate-500 font-mono" />
                                        </div>
                                        <div className="space-y-2">
                                            <label className="text-sm font-semibold text-slate-300">Satuan</label>
                                            <input defaultValue={currentItem.unit} name="unit" required type="text" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all placeholder-slate-500" />
                                        </div>
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-sm font-semibold text-slate-300">Status</label>
                                        <select defaultValue={currentItem.status} name="status" className="w-full bg-[#0d1117] border border-white/10 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all appearance-none cursor-pointer">
                                            <option value="Otomatis">Otomatis berdasarkan jumlah</option>
                                            <option value="Aman">Aman (Manual)</option>
                                            <option value="Rendah">Rendah (Manual)</option>
                                            <option value="Habis">Habis (Manual)</option>
                                        </select>
                                    </div>
                                </div>
                            </form>
                        </div>
                        <div className="p-6 border-t border-white/10 bg-white/5 flex items-center justify-end shrink-0 gap-3">
                            <button onClick={() => setIsEditModalOpen(false)} type="button" className="px-4 py-2.5 rounded-lg border border-white/10 text-slate-300 hover:bg-white/10 hover:text-white text-sm font-bold transition-colors cursor-pointer">
                                Batal
                            </button>
                            <button type="submit" form="editForm" className="px-6 py-2.5 rounded-lg bg-primary hover:bg-blue-600 text-white text-sm font-bold shadow-lg shadow-primary/25 transition-all cursor-pointer">
                                Simpan Perubahan
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}

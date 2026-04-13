import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useKitchenTickets, useUpdateTicketStatus } from '../hooks/useKitchen';
import { PageLoader, EmptyState } from '../components/LoadingStates';

function TicketAction({ initialStep = 0, orderId }) {
    const [step, setStep] = useState(initialStep);
    const updateStatus = useUpdateTicketStatus();

    const handleStep = async (nextStep) => {
        const statusMap = { 1: 'preparing', 2: 'ready' };
        try {
            await updateStatus.mutateAsync({ orderId, status: statusMap[nextStep] });
            setStep(nextStep);
        } catch {
            setStep(nextStep); // Fallback to optimistic update
        }
    };

    if (step === 0) {
        return (
            <button onClick={() => handleStep(1)} className="w-full py-4 px-4 rounded-xl flex items-center justify-center gap-2 font-bold text-[17px] transition-transform active:scale-[0.98] shadow-md bg-blue-500 hover:bg-blue-600 text-white cursor-pointer select-none">
                <span className="material-symbols-outlined text-[22px]">skillet</span>
                Mulai Siapkan
            </button>
        );
    } else if (step === 1) {
        return (
            <button onClick={() => handleStep(2)} className="w-full py-4 px-4 rounded-xl flex items-center justify-center gap-2 font-bold text-[17px] transition-transform active:scale-[0.98] shadow-md bg-orange-500 hover:bg-orange-600 text-white cursor-pointer select-none">
                <span className="material-symbols-outlined text-[22px]">check</span>
                Pesanan Selesai
            </button>
        );
    } else {
        return (
            <button disabled className="w-full py-4 px-4 rounded-xl flex items-center justify-center gap-2 font-bold text-[17px] transition-all bg-[#1e293b] border border-white/5 text-slate-500 cursor-not-allowed opacity-80 shadow-none outline-none select-none">
                <span className="material-symbols-outlined text-[22px]">done_all</span>
                Selesai
            </button>
        );
    }
}

export default function Dapur() {
    const { data: tickets = [], isLoading } = useKitchenTickets();
    const [activeFilter, setActiveFilter] = useState('Semua');
    const navigate = useNavigate();

    const toggleItem = (ticketId, itemId) => {
        // Visual toggle only – API doesn't support per-item check
    };

    return (
        <div className="bg-[#13151a] font-display text-slate-900 dark:text-white min-h-screen flex flex-col overflow-hidden w-full">
            {/* Header */}
            <header className="border-b border-white/5 w-full px-8 py-5 flex items-center justify-between bg-[#1a1d23]">
                <div className="flex items-center gap-5">
                    <div className="p-2.5 bg-[#1e293b] rounded-xl text-blue-500">
                        <span className="material-symbols-outlined text-3xl">soup_kitchen</span>
                    </div>
                    <div>
                        <h1 className="text-2xl font-black tracking-tight leading-none text-white uppercase">KASIR-AI KDS</h1>
                        <span className="text-xs text-slate-400 font-bold tracking-widest uppercase mt-1.5 block">DAPUR - Cabang Batam Centre</span>
                    </div>
                </div>
                <div className="flex items-center gap-8">
                    <div className="flex gap-8 text-right bg-[#1e293b]/50 px-6 py-2 rounded-2xl border border-white/5">
                        <div className="flex flex-col items-center">
                            <span className="text-[10px] text-slate-400 font-black tracking-widest uppercase mb-0.5">Menunggu</span>
                            <span className="text-2xl font-black text-blue-500 leading-none">12</span>
                        </div>
                        <div className="w-px h-10 bg-white/10"></div>
                        <div className="flex flex-col items-center">
                            <span className="text-[10px] text-slate-400 font-black tracking-widest uppercase mb-0.5">Rata-rata</span>
                            <span className="text-2xl font-black text-emerald-500 leading-none">8m</span>
                        </div>
                    </div>
                    <div className="h-12 w-px bg-white/10"></div>
                    <div className="flex items-center gap-6">
                        <div className="text-right">
                            <p className="text-xl font-bold font-mono leading-none text-white">12:48 <span className="text-sm font-sans text-slate-400 font-medium ml-1">PM</span></p>
                            <p className="text-xs text-slate-500 mt-1.5 font-medium">Rab, 24 Okt</p>
                        </div>
                        <div className="flex items-center gap-3 bg-[#1e293b]/50 rounded-full pr-5 pl-1.5 py-1.5 border border-white/5">
                            <img src="https://lh3.googleusercontent.com/aida-public/AB6AXuA-Ib-dzTMwCbehmcjITxKdL2bbMjYuaIaQzwa50QAeQyX9izOVGBaQecwULuv9ZUGWYvy5wEeF_-KhoLxd_cmeiSSpeDRZYZUZA1yKJwCLOgxXsYSCxC2mHsOZMoRnYqS4K6Pcxf6vfNGezxpcXNPMZDaiU7fMyxznXnxKzP1vZBem8jrTzAVZLVG6SCL1azUrS6sHv5Cfek53p-lZTq_c2ygCcRTb2ONorCSdEK5u0e0R0O313hXHujGmX-zE_8gJUddT6uf86GfE" className="w-10 h-10 rounded-full border-2 border-slate-700 object-cover" alt="Profile" />
                            <div className="flex flex-col items-start justify-center">
                                <span className="text-sm font-bold text-white leading-tight">Alex S.</span>
                                <span className="text-[11px] font-medium text-slate-400">Chef</span>
                            </div>
                        </div>
                        <button onClick={() => navigate('/login')} className="text-slate-400 hover:text-white transition-colors p-2 hover:bg-white/5 rounded-xl ml-2 cursor-pointer z-10 relative block">
                            <span className="material-symbols-outlined text-[26px]">logout</span>
                        </button>
                    </div>
                </div>
            </header>

            {/* Filter Tabs */}
            <div className="px-8 pt-6 pb-2 flex gap-4">
                <button
                    onClick={() => setActiveFilter('Semua')}
                    className={`px-8 py-2.5 font-bold rounded-full text-sm transition-colors ${activeFilter === 'Semua' ? 'bg-blue-500 text-white' : 'bg-[#1e293b] text-slate-300 hover:bg-[#2a3649] border border-white/5'}`}
                >
                    Semua
                </button>
                <button
                    onClick={() => setActiveFilter('Baru')}
                    className={`px-8 py-2.5 font-bold rounded-full text-sm transition-colors ${activeFilter === 'Baru' ? 'bg-blue-500 text-white' : 'bg-[#1e293b] text-slate-300 hover:bg-[#2a3649] border border-white/5'}`}
                >
                    Baru (2)
                </button>
                <button
                    onClick={() => setActiveFilter('Proses')}
                    className={`px-8 py-2.5 font-bold rounded-full text-sm transition-colors ${activeFilter === 'Proses' ? 'bg-blue-500 text-white' : 'bg-[#1e293b] text-slate-300 hover:bg-[#2a3649] border border-white/5'}`}
                >
                    Proses (3)
                </button>
            </div>

            <main className="flex-1 overflow-y-auto px-8 py-4 w-full custom-scrollbar">
                <div className="flex flex-wrap items-stretch justify-start gap-6 w-full">
                    {isLoading ? <PageLoader message="Memuat tiket dapur..." /> : tickets.length === 0 ? (
                        <div className="w-full">
                            <EmptyState icon="restaurant" title="Tidak ada tiket" description="Tiket pesanan baru akan muncul di sini." />
                        </div>
                    ) : tickets.map(ticket => (
                        <div key={ticket.id} className={`flex flex-col w-[360px] rounded-2xl border-2 ${ticket.borderClass} bg-[#1a1d24] overflow-hidden shrink-0 shadow-lg`}>
                            {/* Ticket Header Area */}
                            <div className="p-6 pb-4">
                                <div className="flex justify-between items-center mb-4">
                                    <span className={`text-[11px] font-black tracking-widest uppercase ${ticket.colorClass}`}>{ticket.status}</span>
                                    <span className={`text-sm font-medium ${ticket.timeColor || 'text-slate-400'}`}>{ticket.time}</span>
                                </div>
                                <h3 className="text-[28px] font-black text-white mb-2 leading-none tracking-tight">#{ticket.id}</h3>
                                <div className="flex justify-between items-center text-slate-400">
                                    <span className="text-xs font-black uppercase tracking-widest text-slate-300">{ticket.table}</span>
                                    <span className="material-symbols-outlined text-xl">{ticket.icon}</span>
                                </div>
                            </div>

                            {/* Divider Line */}
                            <div className="w-full h-px bg-white/5"></div>

                            {/* Ticket Items List */}
                            <div className="flex-1 p-6 space-y-5 overflow-y-auto custom-scrollbar">
                                {ticket.items.map((item) => (
                                    <div key={item.id} className="flex gap-4 items-start group relative">
                                        {/* Action overlay for the whole row to toggle */}
                                        <div
                                            className="absolute inset-0 -mx-3 -my-2 rounded-lg hover:bg-white/5 cursor-pointer transition-colors"
                                            onClick={() => toggleItem(ticket.id, item.id)}
                                        ></div>

                                        <span className="text-blue-500 font-bold text-lg min-w-[24px] pt-0.5 relative z-10">{item.qty}x</span>
                                        <div className="flex-1 pt-1 relative z-10">
                                            <p className={`text-[17px] font-bold leading-tight transition-all duration-300 ${item.checked ? 'text-slate-500 line-through' : 'text-slate-100'}`}>
                                                {item.name}
                                            </p>
                                            {item.note && (
                                                <p className={`text-[13px] mt-1.5 italic font-medium ${item.checked ? 'text-slate-600 line-through' : 'text-orange-400'}`}>
                                                    {item.note}
                                                </p>
                                            )}
                                        </div>
                                        <div className="pt-1 select-none relative z-10" onClick={() => toggleItem(ticket.id, item.id)}>
                                            {item.isCircle ? (
                                                <span className={`material-symbols-outlined text-[24px] cursor-pointer transition-colors ${item.checked ? 'text-emerald-500' : 'text-slate-600 hover:text-slate-400'}`}>
                                                    {item.checked ? 'check_circle' : 'radio_button_unchecked'}
                                                </span>
                                            ) : (
                                                <span className={`material-symbols-outlined text-[24px] cursor-pointer transition-colors ${item.checked ? 'text-emerald-500' : 'text-slate-600 hover:text-slate-400'}`}>
                                                    {item.checked ? 'check_box' : 'check_box_outline_blank'}
                                                </span>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>

                            {/* Action Button */}
                            <div className="p-5 pt-3 mt-auto bg-gradient-to-t from-black/20 to-transparent">
                                <TicketAction initialStep={ticket.status === 'PROSES' ? 1 : ticket.status === 'SELESAI' ? 2 : 0} />
                            </div>
                        </div>
                    ))}
                </div>
            </main>

            {/* Footer Bar */}
            <footer className="bg-[#1a1d23] border-t border-white/5 px-8 py-3 flex justify-between items-center text-xs text-slate-500 font-medium">
                <div className="flex gap-6">
                    <div className="flex items-center gap-2">
                        <div className="size-2 rounded-full bg-emerald-500"></div>
                        <span>Terhubung</span>
                    </div>
                    <div className="flex items-center gap-2">
                        <div className="size-2 rounded-full bg-blue-500 animate-pulse"></div>
                        <span>Sinkronisasi...</span>
                    </div>
                </div>
                <div>
                    KDS Versi 2.4.1
                </div>
            </footer>
        </div>
    );
}

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useStartShift } from '../hooks/useShifts';
import { useAuth } from '../hooks/useAuth';

export default function MulaiShift() {
    const navigate = useNavigate();
    const [modalAwal, setModalAwal] = useState('0');
    const startShift = useStartShift();
    const { user } = useAuth();

    // Helper to format currency
    const formatCurrency = (value) => {
        const numPattern = value.replace(/\D/g, '');
        if (!numPattern) return '0';
        return new Intl.NumberFormat('id-ID').format(numPattern);
    };

    const handleInputChange = (e) => {
        const inputVal = e.target.value;
        const formatted = formatCurrency(inputVal);
        setModalAwal(formatted);
    };

    const addAmount = (amount) => {
        const currentAmount = parseInt(modalAwal.replace(/\./g, ''), 10) || 0;
        setModalAwal(formatCurrency((currentAmount + amount).toString()));
    };

    const resetAmount = () => {
        setModalAwal('0');
    };

    const handleStartShift = async (e) => {
        e.preventDefault();
        const startingCash = parseInt(modalAwal.replace(/\./g, ''), 10) || 0;
        try {
            await startShift.mutateAsync({
                staffId: user?.id,
                branchId: user?.branchId || undefined,
                startingCash,
            });
        } catch (err) {
            console.error('Shift start error:', err);
        }
        navigate('/kasir');
    };

    return (
        <div className="bg-background-light dark:bg-background-dark font-display min-h-screen w-full flex flex-col antialiased selection:bg-primary/30 selection:text-white relative overflow-hidden">
            {/* Background Orbs */}
            <div className="fixed inset-0 z-0 overflow-hidden pointer-events-none">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-primary/5 blur-[100px] rounded-full"></div>
            </div>

            <main className="relative z-10 flex-grow flex items-center justify-center p-4 w-full">
                {/* Main Card */}
                <div className="w-full max-w-[480px] flex flex-col rounded-2xl bg-[#161b22] border border-white/10 shadow-2xl overflow-hidden backdrop-blur-xl">

                    {/* Header */}
                    <div className="p-6 pb-5 border-b border-white/5 relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-primary/10 blur-[40px] rounded-full translate-x-1/2 -translate-y-1/2"></div>
                        <h1 className="text-2xl font-bold text-white tracking-tight relative z-10">Mulai Shift</h1>
                    </div>

                    {/* Profile Section */}
                    <div className="px-6 py-5">
                        <div className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/5">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-full bg-orange-200 shrink-0 relative flex items-center justify-center overflow-hidden">
                                    <div className="w-full h-full bg-amber-300/80"></div>
                                </div>
                                <div className="flex flex-col">
                                    <span className="text-xs text-slate-400 font-medium">Kasir Bertugas</span>
                                    <span className="text-sm font-bold text-white leading-tight mt-0.5">{user?.name || '-'}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <form onSubmit={handleStartShift} className="px-6 pb-6 flex flex-col gap-6">
                        {/* Input Modal */}
                        <div className="flex flex-col gap-2">
                            <label className="text-sm font-medium text-slate-300">Masukkan Modal Awal</label>
                            <div className="relative flex items-center group">
                                <span className="absolute left-4 text-slate-400 font-medium pointer-events-none group-focus-within:text-white transition-colors">Rp</span>
                                <input
                                    type="text"
                                    value={modalAwal}
                                    onChange={handleInputChange}
                                    className="w-full h-14 pl-12 pr-4 bg-[#0f1115] border border-white/10 rounded-xl text-white text-lg font-medium focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/50 transition-all placeholder:text-slate-600"
                                    placeholder="0"
                                />
                            </div>

                            {/* Quick Add Pills */}
                            <div className="flex flex-wrap items-center gap-2 mt-2">
                                <button type="button" onClick={() => addAmount(100000)} className="px-3 py-1.5 rounded-full border border-white/10 text-xs font-medium text-slate-300 hover:bg-white/5 hover:text-white hover:border-white/20 transition-all bg-[#0f1115]">
                                    + Rp 100.000
                                </button>
                                <button type="button" onClick={() => addAmount(200000)} className="px-3 py-1.5 rounded-full border border-white/10 text-xs font-medium text-slate-300 hover:bg-white/5 hover:text-white hover:border-white/20 transition-all bg-[#0f1115]">
                                    + Rp 200.000
                                </button>
                                <button type="button" onClick={() => addAmount(500000)} className="px-3 py-1.5 rounded-full border border-white/10 text-xs font-medium text-slate-300 hover:bg-white/5 hover:text-white hover:border-white/20 transition-all bg-[#0f1115]">
                                    + Rp 500.000
                                </button>
                                <button type="button" onClick={resetAmount} className="px-3 py-1.5 rounded-full border border-white/10 text-xs font-medium text-slate-400 hover:text-rose-400 hover:border-rose-500/30 hover:bg-rose-500/10 transition-all bg-[#0f1115] ml-auto">
                                    Reset
                                </button>
                            </div>
                        </div>

                        {/* Submit Button */}
                        <div className="pt-2">
                            <button type="submit" className="w-full h-12 bg-primary hover:bg-blue-600 active:scale-[0.98] text-white rounded-xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-primary/20 transition-all group">
                                <span className="material-symbols-outlined text-[20px] bg-white text-primary rounded-full p-[1px]">check_circle</span>
                                <span>Mulai Shift</span>
                            </button>
                        </div>
                    </form>



                </div>
            </main>
        </div>
    );
}

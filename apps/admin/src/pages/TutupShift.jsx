import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useShiftSummary, useCloseShift } from '../hooks/useShifts';
import { useAuth } from '../hooks/useAuth';

export default function TutupShift() {
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();
    const shiftId = searchParams.get('shiftId');
    const { data: summary, isLoading } = useShiftSummary(shiftId);
    const closeShift = useCloseShift();
    const { user, signOut } = useAuth();
    const [endingCash, setEndingCash] = useState(0);
    const [isClosing, setIsClosing] = useState(false);

    const formatRp = (num) => new Intl.NumberFormat('id-ID').format(num || 0);

    // Computed values from summary or fallback to 0
    const modalAwal = summary?.startingCash || 0;
    const penjualanTunai = summary?.cashSales || 0;
    const pengeluaran = summary?.expenses || 0;
    const expectedCash = modalAwal + penjualanTunai - pengeluaran;
    const qrisSales = summary?.qrisSales || 0;
    const cardSales = summary?.cardSales || 0;
    const selisih = endingCash - expectedCash;

    // Numpad handlers
    const handleNumpadClick = (value) => {
        if (value === 'CLEAR') {
            setEndingCash(0);
            return;
        }
        if (value === 'BACKSPACE') {
            const str = endingCash.toString();
            setEndingCash(str.length > 1 ? parseInt(str.slice(0, -1), 10) : 0);
            return;
        }
        const currentStr = endingCash.toString();
        const newStr = currentStr === '0' ? value : currentStr + value;
        if (newStr.length > 10) return;
        setEndingCash(Number(newStr));
    };

    const handleInputChange = (e) => {
        const stripped = e.target.value.replace(/\D/g, '');
        setEndingCash(stripped === '' ? 0 : Number(stripped));
    };

    const handleClose = async () => {
        setIsClosing(true);
        try {
            if (shiftId) {
                await closeShift.mutateAsync({ id: shiftId, endingCash });
            }
        } catch (err) {
            console.error('Shift close error:', err);
        }
        try {
            await signOut();
        } catch (err) {
            console.error('Sign out error:', err);
        }
        navigate('/login');
    };

    // Selisih styling
    const isSesuai = selisih === 0;
    const isLebih = selisih > 0;
    const selisihColor = isSesuai ? 'emerald' : isLebih ? 'blue' : 'rose';
    const selisihLabel = isSesuai ? 'Sesuai' : isLebih ? 'Lebih' : 'Kurang';
    const selisihIcon = isSesuai ? 'thumb_up' : isLebih ? 'trending_up' : 'trending_down';

    return (
        <div className="bg-[#0f172a] text-white font-display overflow-hidden h-screen w-screen relative">

            {/* Background */}
            <div className="absolute inset-0 z-0 bg-black/60 backdrop-blur-sm"></div>

            {/* Main Content */}
            <div className="relative z-10 flex h-full w-full items-center justify-center p-4">
                <div className="w-full max-w-[1024px] rounded-2xl border border-white/10 bg-[rgba(15,23,42,0.85)] backdrop-blur-xl shadow-2xl flex flex-col md:flex-row overflow-hidden max-h-[90vh]">

                    {/* Left Panel: Summary */}
                    <div className="flex-1 flex flex-col p-8 border-b md:border-b-0 md:border-r border-white/10 overflow-y-auto custom-scrollbar">

                        {/* Header */}
                        <div className="mb-8">
                            <h1 className="text-3xl font-bold tracking-tight text-white mb-1">Tutup Shift</h1>
                            <div className="flex items-center gap-2 text-slate-400">
                                <span className="material-symbols-outlined text-[18px]">person</span>
                                <p className="text-sm font-medium">Kasir: {user?.name || '-'}</p>
                            </div>
                        </div>

                        {isLoading ? (
                            <div className="flex-1 flex items-center justify-center">
                                <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                            </div>
                        ) : (
                            <>
                                {/* Summary Cards */}
                                <div className="flex flex-col gap-3 mb-8">
                                    <div className="flex items-center justify-between p-4 rounded-xl bg-white/5 border border-white/5 hover:border-primary/30 transition-colors group">
                                        <div className="flex items-center gap-3 text-slate-400 group-hover:text-primary transition-colors">
                                            <span className="material-symbols-outlined text-[20px]">account_balance_wallet</span>
                                            <span className="text-sm font-medium">Modal Awal</span>
                                        </div>
                                        <span className="text-white font-bold text-lg tracking-tight">Rp {formatRp(modalAwal)}</span>
                                    </div>

                                    <div className="flex items-center justify-between p-4 rounded-xl bg-white/5 border border-white/5 hover:border-primary/30 transition-colors group">
                                        <div className="flex items-center gap-3 text-slate-400 group-hover:text-primary transition-colors">
                                            <span className="material-symbols-outlined text-[20px]">payments</span>
                                            <span className="text-sm font-medium">Penjualan Tunai</span>
                                        </div>
                                        <span className="text-white font-bold text-lg tracking-tight">Rp {formatRp(penjualanTunai)}</span>
                                    </div>

                                    <div className="flex items-center justify-between p-4 rounded-xl bg-white/5 border border-white/5 hover:border-rose-400/30 transition-colors group">
                                        <div className="flex items-center gap-3 text-slate-400 group-hover:text-rose-400 transition-colors">
                                            <span className="material-symbols-outlined text-[20px]">receipt_long</span>
                                            <span className="text-sm font-medium">Pengeluaran</span>
                                        </div>
                                        <span className="text-rose-400 font-bold text-lg tracking-tight">- Rp {formatRp(pengeluaran)}</span>
                                    </div>

                                    <div className="flex items-center justify-between p-4 rounded-xl bg-primary/10 border border-primary/20 mt-2">
                                        <div className="flex items-center gap-3 text-primary">
                                            <span className="material-symbols-outlined text-[20px]">calculate</span>
                                            <span className="text-xs font-bold uppercase tracking-wider">TOTAL UANG FISIK (SISTEM)</span>
                                        </div>
                                        <span className="text-white font-bold text-xl tracking-tight">Rp {formatRp(expectedCash)}</span>
                                    </div>
                                </div>

                                {/* Non-Tunai Ringkasan */}
                                <div className="mt-auto pt-6 border-t border-white/10">
                                    <p className="text-slate-400 text-xs font-semibold uppercase tracking-wider mb-4">Ringkasan Non-Tunai</p>
                                    <div className="space-y-3">
                                        <div className="flex justify-between items-center group">
                                            <div className="flex items-center gap-3">
                                                <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center text-white/70 group-hover:bg-primary/20 group-hover:text-primary transition-colors">
                                                    <span className="material-symbols-outlined text-[18px]">qr_code_2</span>
                                                </div>
                                                <span className="text-gray-300 text-sm">Transaksi QRIS</span>
                                            </div>
                                            <span className="text-white font-medium">Rp {formatRp(qrisSales)}</span>
                                        </div>
                                        <div className="flex justify-between items-center group">
                                            <div className="flex items-center gap-3">
                                                <div className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center text-white/70 group-hover:bg-primary/20 group-hover:text-primary transition-colors">
                                                    <span className="material-symbols-outlined text-[18px]">credit_card</span>
                                                </div>
                                                <span className="text-gray-300 text-sm">Debit / Kredit</span>
                                            </div>
                                            <span className="text-white font-medium">Rp {formatRp(cardSales)}</span>
                                        </div>
                                    </div>
                                </div>
                            </>
                        )}
                    </div>

                    {/* Right Panel: Verification */}
                    <div className="w-full md:w-[400px] bg-[#0f172a]/50 backdrop-blur-md p-8 flex flex-col justify-between border-l border-white/5">
                        <div className="flex flex-col gap-6">

                            {/* Input Uang Fisik */}
                            <div>
                                <h2 className="text-lg font-semibold text-white mb-4">Verifikasi Uang Fisik</h2>
                                <label className="flex flex-col gap-2">
                                    <span className="text-slate-400 text-sm">Masukkan Jumlah Aktual di Laci</span>
                                    <div className="relative group">
                                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                            <span className="text-gray-400 font-medium">Rp</span>
                                        </div>
                                        <input
                                            className="w-full bg-[#1e293b] border border-[#334155] text-white text-2xl font-bold rounded-xl py-4 pl-12 pr-12 focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all placeholder:text-white/20"
                                            placeholder="0"
                                            type="text"
                                            value={endingCash === 0 ? '' : formatRp(endingCash)}
                                            onChange={handleInputChange}
                                            autoFocus
                                        />
                                        {endingCash > 0 && (
                                            <div className={`absolute inset-y-0 right-0 pr-4 flex items-center text-${selisihColor}-500`}>
                                                <span className="material-symbols-outlined">
                                                    {isSesuai ? 'check_circle' : 'info'}
                                                </span>
                                            </div>
                                        )}
                                    </div>
                                </label>
                            </div>

                            {/* Status Selisih */}
                            <div className={`bg-${selisihColor}-500/10 rounded-xl p-4 border border-${selisihColor}-500/20 flex items-center justify-between`}>
                                <div className="flex flex-col">
                                    <span className={`text-xs text-${selisihColor}-500 font-medium uppercase tracking-wider`}>Status Selisih</span>
                                    <span className="text-lg font-bold text-white">
                                        {selisihLabel} (Rp {formatRp(Math.abs(selisih))})
                                    </span>
                                </div>
                                <div className={`bg-${selisihColor}-500 text-black rounded-full p-1.5 flex items-center justify-center`}>
                                    <span className="material-symbols-outlined text-[20px]">{selisihIcon}</span>
                                </div>
                            </div>

                            {/* Numpad */}
                            <div className="grid grid-cols-3 gap-3 mt-2">
                                {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => (
                                    <button
                                        key={num}
                                        onClick={() => handleNumpadClick(num.toString())}
                                        className="h-14 bg-[#1e293b] hover:bg-[#334155] active:bg-[#0f172a] text-white font-bold text-xl rounded-xl transition-colors shadow-sm cursor-pointer"
                                    >
                                        {num}
                                    </button>
                                ))}
                                <button
                                    onClick={() => handleNumpadClick('CLEAR')}
                                    className="h-14 bg-rose-500/10 hover:bg-rose-500/20 active:bg-rose-500/30 text-rose-400 font-bold text-sm rounded-xl transition-colors shadow-sm tracking-wider uppercase cursor-pointer"
                                >
                                    Clear
                                </button>
                                <button
                                    onClick={() => handleNumpadClick('0')}
                                    className="h-14 bg-[#1e293b] hover:bg-[#334155] active:bg-[#0f172a] text-white font-bold text-xl rounded-xl transition-colors shadow-sm cursor-pointer"
                                >
                                    0
                                </button>
                                <button
                                    onClick={() => handleNumpadClick('BACKSPACE')}
                                    className="h-14 bg-[#1e293b] hover:bg-[#334155] active:bg-[#0f172a] text-slate-400 hover:text-white font-bold text-xl rounded-xl transition-colors shadow-sm flex items-center justify-center gap-1 cursor-pointer"
                                >
                                    <span className="material-symbols-outlined">backspace</span>
                                </button>
                            </div>
                        </div>

                        {/* Footer Actions */}
                        <div className="mt-8 flex flex-col gap-3">
                            <button
                                className="w-full bg-primary hover:bg-blue-600 active:scale-[0.98] text-white font-bold text-lg py-4 rounded-xl transition-all shadow-lg shadow-primary/20 flex items-center justify-center gap-2 group disabled:opacity-50 disabled:cursor-not-allowed"
                                onClick={handleClose}
                                disabled={isClosing}
                            >
                                {isClosing ? (
                                    <><div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div> Menutup Shift...</>
                                ) : (
                                    <><span className="material-symbols-outlined group-hover:scale-110 transition-transform">lock</span> TUTUP SHIFT</>
                                )}
                            </button>
                            <button
                                className="w-full bg-transparent hover:bg-white/5 text-slate-400 font-medium text-sm py-3 rounded-xl transition-all flex items-center justify-center gap-2"
                                onClick={() => navigate('/kasir')}
                            >
                                <span className="material-symbols-outlined text-[18px]">arrow_back</span>
                                Kembali ke Kasir
                            </button>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    );
}

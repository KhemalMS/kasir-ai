import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { getHomeForRole } from '../components/AuthGuard';

export default function Login() {
    const [showPassword, setShowPassword] = useState(false);
    const navigate = useNavigate();
    const location = useLocation();
    const { signIn } = useAuth();

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            const result = await signIn.email(email, password);
            if (result.error) {
                setError(result.error.message || 'Login gagal');
            } else {
                const role = result.data?.user?.role || 'kasir';
                // Kasir must always go through mulai-shift first
                const destination = role === 'kasir'
                    ? '/mulai-shift'
                    : (location.state?.from || getHomeForRole(role));
                navigate(destination, { replace: true });
            }
        } catch (err) {
            setError('Terjadi kesalahan. Silakan coba lagi.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="bg-background-light dark:bg-background-dark font-display min-h-screen w-full flex flex-col antialiased selection:bg-primary/30 selection:text-white overflow-hidden relative">

            {/* Background Orbs */}
            <div className="fixed inset-0 z-0 overflow-hidden pointer-events-none">
                <div className="absolute -top-[20%] -left-[10%] w-[60vw] h-[60vw] rounded-full bg-primary/20 blur-[120px] opacity-40 mix-blend-screen animate-pulse duration-[10000ms]"></div>
                <div className="absolute -bottom-[20%] -right-[10%] w-[50vw] h-[50vw] rounded-full bg-primary/10 blur-[100px] opacity-30 mix-blend-screen"></div>
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-primary/5 blur-[80px] rounded-full pointer-events-none"></div>
            </div>

            <main className="relative z-10 flex-grow flex items-center justify-center p-4 sm:p-6 lg:p-8">

                <div className="w-full max-w-[440px] flex flex-col gap-8 rounded-2xl bg-[#1e293b]/70 backdrop-blur-xl border border-white/10 shadow-2xl p-8 sm:p-12 relative overflow-hidden">

                    <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-primary/50 to-transparent opacity-50"></div>

                    <div className="flex flex-col items-center gap-2 text-center">
                        <div className="h-16 w-16 bg-gradient-to-tr from-primary to-blue-400 rounded-xl flex items-center justify-center mb-2 shadow-lg shadow-primary/20">
                            <span className="material-symbols-outlined text-white text-4xl">point_of_sale</span>
                        </div>
                        <h1 className="text-3xl font-black tracking-tight text-slate-900 dark:text-white">
                            Kasir-AI
                        </h1>
                        <p className="text-slate-500 dark:text-slate-400 text-sm font-medium leading-relaxed max-w-[280px]">
                            Akses sistem POS cerdas untuk bisnis multi-cabang Anda.
                        </p>
                    </div>

                    <form className="flex flex-col gap-5 w-full" onSubmit={handleLogin}>

                        {error && (
                            <div className="flex items-center gap-2 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
                                <span className="material-symbols-outlined text-lg">error</span>
                                {error}
                            </div>
                        )}

                        {/* Email Field */}
                        <div className="flex flex-col gap-2 group">
                            <label className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 pl-1 group-focus-within:text-primary transition-colors" htmlFor="email">
                                Email
                            </label>
                            <div className="relative flex items-center">
                                <span className="material-symbols-outlined absolute left-4 text-slate-400 text-xl pointer-events-none group-focus-within:text-primary transition-colors">mail</span>
                                <input
                                    className="w-full h-12 pl-12 pr-4 bg-slate-100 dark:bg-slate-900/50 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/50 transition-all font-medium"
                                    id="email"
                                    name="email"
                                    placeholder="Masukkan email Anda"
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                />
                            </div>
                        </div>

                        {/* Password Field */}
                        <div className="flex flex-col gap-2 group">
                            <label className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 pl-1 group-focus-within:text-primary transition-colors" htmlFor="password">
                                Kata Sandi
                            </label>
                            <div className="relative flex items-center">
                                <span className="material-symbols-outlined absolute left-4 text-slate-400 text-xl pointer-events-none group-focus-within:text-primary transition-colors">lock</span>
                                <input
                                    className="w-full h-12 pl-12 pr-4 bg-slate-100 dark:bg-slate-900/50 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/50 transition-all font-medium"
                                    id="password"
                                    name="password"
                                    placeholder="Masukkan kata sandi"
                                    type={showPassword ? "text" : "password"}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                />
                                <button
                                    className="absolute right-4 text-slate-400 hover:text-slate-200 transition-colors focus:outline-none"
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                >
                                    <span className="material-symbols-outlined text-xl">
                                        {showPassword ? "visibility_off" : "visibility"}
                                    </span>
                                </button>
                            </div>
                        </div>

                        {/* Login Action */}
                        <div className="pt-2">
                            <button disabled={loading} className="w-full h-12 bg-primary hover:bg-blue-600 active:scale-[0.98] text-white text-base font-bold rounded-xl shadow-lg shadow-primary/30 transition-all duration-200 flex items-center justify-center gap-2 group disabled:opacity-50 disabled:cursor-not-allowed">
                                <span>{loading ? 'Memproses...' : 'Masuk'}</span>
                                {!loading && <span className="material-symbols-outlined text-xl group-hover:translate-x-1 transition-transform">arrow_forward</span>}
                            </button>
                        </div>

                        <div className="flex items-center justify-between mt-2 px-1">
                            <a className="text-sm text-slate-500 dark:text-slate-400 hover:text-primary dark:hover:text-white transition-colors" href="#">
                                Lupa Kata Sandi?
                            </a>
                            <a className="text-sm text-slate-500 dark:text-slate-400 hover:text-primary dark:hover:text-white transition-colors" href="#">
                                Bantuan & Dukungan
                            </a>
                        </div>

                    </form>

                    <div className="absolute bottom-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-slate-700/50 to-transparent"></div>
                </div>

                <div className="absolute bottom-6 w-full text-center pointer-events-none">
                    <p className="text-xs text-slate-500/50 dark:text-slate-600 font-medium">
                        © 2024 Kasir-AI POS System. Seluruh hak cipta dilindungi.
                    </p>
                </div>

            </main>
        </div>
    );
}

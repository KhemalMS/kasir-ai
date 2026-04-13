import React from 'react';

/**
 * Full-page loading spinner for standalone pages.
 */
export function PageLoader({ message = 'Memuat data...' }) {
    return (
        <div className="flex-1 flex items-center justify-center min-h-[400px]">
            <div className="flex flex-col items-center gap-4">
                <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
                <p className="text-slate-400 text-sm font-medium">{message}</p>
            </div>
        </div>
    );
}

/**
 * Inline loading spinner for sections within a page.
 */
export function SectionLoader({ message = 'Memuat...' }) {
    return (
        <div className="flex items-center justify-center py-12">
            <div className="flex items-center gap-3">
                <div className="w-6 h-6 border-3 border-primary border-t-transparent rounded-full animate-spin"></div>
                <p className="text-slate-400 text-sm">{message}</p>
            </div>
        </div>
    );
}

/**
 * Skeleton cards for grid layouts (products, branches, etc.)
 */
export function SkeletonCard({ count = 4 }) {
    return (
        <>
            {Array.from({ length: count }).map((_, i) => (
                <div key={i} className="glass-panel rounded-2xl overflow-hidden animate-pulse">
                    <div className="aspect-[4/3] bg-slate-700/50"></div>
                    <div className="p-4 flex flex-col gap-3">
                        <div className="h-4 bg-slate-700/50 rounded w-3/4"></div>
                        <div className="h-3 bg-slate-700/50 rounded w-1/2"></div>
                        <div className="h-5 bg-slate-700/50 rounded w-1/3"></div>
                    </div>
                </div>
            ))}
        </>
    );
}

/**
 * Skeleton rows for table/list layouts (staff, inventory, transactions, etc.)
 */
export function SkeletonRow({ count = 5 }) {
    return (
        <>
            {Array.from({ length: count }).map((_, i) => (
                <div key={i} className="glass-panel rounded-xl p-4 flex items-center gap-4 animate-pulse">
                    <div className="w-12 h-12 rounded-xl bg-slate-700/50 shrink-0"></div>
                    <div className="flex-1 flex flex-col gap-2">
                        <div className="h-4 bg-slate-700/50 rounded w-2/5"></div>
                        <div className="h-3 bg-slate-700/50 rounded w-1/4"></div>
                    </div>
                    <div className="h-6 bg-slate-700/50 rounded-full w-16"></div>
                </div>
            ))}
        </>
    );
}

/**
 * Error banner with retry action.
 */
export function ErrorBanner({ message = 'Terjadi kesalahan saat memuat data.', onRetry }) {
    return (
        <div className="flex flex-col items-center justify-center py-12 px-4">
            <div className="glass-panel rounded-2xl p-8 max-w-md w-full flex flex-col items-center gap-4 border border-red-500/20">
                <div className="w-14 h-14 rounded-full bg-red-500/10 flex items-center justify-center">
                    <span className="material-symbols-outlined text-3xl text-red-400">error</span>
                </div>
                <div className="text-center">
                    <h3 className="text-white font-bold text-lg mb-1">Gagal Memuat</h3>
                    <p className="text-slate-400 text-sm">{message}</p>
                </div>
                {onRetry && (
                    <button
                        onClick={onRetry}
                        className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary hover:bg-blue-600 text-white text-sm font-bold transition-all active:scale-95 shadow-lg shadow-primary/20"
                    >
                        <span className="material-symbols-outlined text-lg">refresh</span>
                        Coba Lagi
                    </button>
                )}
            </div>
        </div>
    );
}

/**
 * Empty state for when no data is returned.
 */
export function EmptyState({ icon = 'inbox', title = 'Belum ada data', description = 'Data akan muncul di sini setelah ditambahkan.' }) {
    return (
        <div className="flex flex-col items-center justify-center py-16 px-4">
            <div className="w-16 h-16 rounded-2xl bg-slate-800 flex items-center justify-center mb-4">
                <span className="material-symbols-outlined text-4xl text-slate-500">{icon}</span>
            </div>
            <h3 className="text-white font-bold text-lg mb-1">{title}</h3>
            <p className="text-slate-400 text-sm text-center max-w-xs">{description}</p>
        </div>
    );
}

import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

// Maps role to its default landing page
const ROLE_HOME = {
    admin: '/dashboard',
    kasir: '/mulai-shift',
    kitchen: '/dapur',
};

// Maps role to allowed route prefixes
const ROLE_ROUTES = {
    admin: null, // admin can access everything
    kasir: ['/kasir', '/mulai-shift', '/tutup-shift'],
    kitchen: ['/dapur'],
};

/**
 * Returns the home page for a given role.
 */
export function getHomeForRole(role) {
    return ROLE_HOME[role] || '/dashboard';
}

/**
 * Protects routes that require authentication.
 * Redirects to /login if not authenticated.
 * Redirects to role-appropriate page if user tries to access unauthorized routes.
 */
export function AuthGuard({ children, allowedRoles }) {
    const { isAuthenticated, isPending, user } = useAuth();
    const location = useLocation();

    if (isPending) {
        return (
            <div className="h-screen w-screen flex items-center justify-center bg-[#0f172a]">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
                    <p className="text-slate-400 text-sm font-medium">Memverifikasi sesi...</p>
                </div>
            </div>
        );
    }

    if (!isAuthenticated) {
        return <Navigate to="/login" state={{ from: location.pathname }} replace />;
    }

    const role = user?.role || 'kasir';

    // Check if this route is allowed for the user's role
    if (allowedRoles && !allowedRoles.includes(role)) {
        return <Navigate to={getHomeForRole(role)} replace />;
    }

    // Check route-level access using ROLE_ROUTES
    const allowedPrefixes = ROLE_ROUTES[role];
    if (allowedPrefixes !== null) {
        const isAllowed = allowedPrefixes.some(prefix => location.pathname.startsWith(prefix));
        if (!isAllowed) {
            return <Navigate to={getHomeForRole(role)} replace />;
        }
    }

    return children;
}

/**
 * Protects guest-only routes (e.g. /login).
 * Redirects authenticated users to their role-appropriate home page.
 */
export function GuestGuard({ children }) {
    const { isAuthenticated, isPending, user } = useAuth();

    if (isPending) {
        return (
            <div className="h-screen w-screen flex items-center justify-center bg-[#0f172a]">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
                    <p className="text-slate-400 text-sm font-medium">Memuat...</p>
                </div>
            </div>
        );
    }

    if (isAuthenticated) {
        const role = user?.role || 'kasir';
        return <Navigate to={getHomeForRole(role)} replace />;
    }

    return children;
}

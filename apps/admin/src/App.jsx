import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthGuard, GuestGuard } from './components/AuthGuard';
import { getHomeForRole } from './lib/auth-routes';
import { useAuth } from './hooks/useAuth';

const Layout = lazy(() => import('./components/Layout'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Transaksi = lazy(() => import('./pages/Transaksi'));
const Pengeluaran = lazy(() => import('./pages/Pengeluaran'));
const Inventaris = lazy(() => import('./pages/Inventaris'));
const Staf = lazy(() => import('./pages/Staf'));
const Produk = lazy(() => import('./pages/Produk'));
const Pengaturan = lazy(() => import('./pages/Pengaturan'));
const Cabang = lazy(() => import('./pages/Cabang'));
const Laporan = lazy(() => import('./pages/Laporan'));
const Profil = lazy(() => import('./pages/Profil'));
const Login = lazy(() => import('./pages/Login'));
const Kasir = lazy(() => import('./pages/Kasir'));
const MulaiShift = lazy(() => import('./pages/MulaiShift'));
const TutupShift = lazy(() => import('./pages/TutupShift'));
const Dapur = lazy(() => import('./pages/Dapur'));

function RouteLoader() {
  return (
    <div className="h-screen w-screen flex items-center justify-center bg-[#0f172a]">
      <div className="flex flex-col items-center gap-4">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        <p className="text-slate-400 text-sm font-medium">Memuat...</p>
      </div>
    </div>
  );
}

/**
 * Smart redirect component — sends authenticated users to their role-based home.
 * Sends unauthenticated users to /login.
 */
function RoleRedirect() {
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

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  const role = user?.role || 'kasir';
  return <Navigate to={getHomeForRole(role)} replace />;
}

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<RouteLoader />}>
        <Routes>
          {/* Smart default redirect based on role */}
          <Route path="/" element={<RoleRedirect />} />

          {/* Guest-only route */}
          <Route path="/login" element={<GuestGuard><Login /></GuestGuard>} />

          {/* Kasir-only standalone pages */}
          <Route path="/mulai-shift" element={<AuthGuard><MulaiShift /></AuthGuard>} />
          <Route path="/kasir" element={<AuthGuard><Kasir /></AuthGuard>} />
          <Route path="/tutup-shift" element={<AuthGuard><TutupShift /></AuthGuard>} />

          {/* Kitchen-only page */}
          <Route path="/dapur" element={<AuthGuard><Dapur /></AuthGuard>} />

          {/* Admin pages with sidebar layout */}
          <Route element={<AuthGuard><Layout /></AuthGuard>}>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/transaksi" element={<Transaksi />} />
            <Route path="/pengeluaran" element={<Pengeluaran />} />
            <Route path="/inventaris" element={<Inventaris />} />
            <Route path="/staf" element={<Staf />} />
            <Route path="/produk" element={<Produk />} />
            <Route path="/cabang" element={<Cabang />} />
            <Route path="/laporan" element={<Laporan />} />
            <Route path="/pengaturan" element={<Pengaturan />} />
            <Route path="/profil" element={<Profil />} />
          </Route>
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}

export default App;

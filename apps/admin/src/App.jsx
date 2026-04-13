import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthGuard, GuestGuard, getHomeForRole } from './components/AuthGuard';
import { useAuth } from './hooks/useAuth';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Transaksi from './pages/Transaksi';
import Pengeluaran from './pages/Pengeluaran';
import Inventaris from './pages/Inventaris';
import Staf from './pages/Staf';
import Produk from './pages/Produk';
import Pengaturan from './pages/Pengaturan';
import Cabang from './pages/Cabang';
import Laporan from './pages/Laporan';
import Login from './pages/Login';
import Kasir from './pages/Kasir';
import MulaiShift from './pages/MulaiShift';
import TutupShift from './pages/TutupShift';
import Dapur from './pages/Dapur';

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
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;

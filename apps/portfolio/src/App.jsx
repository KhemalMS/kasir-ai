import { useEffect, useRef, useState } from 'react'

/* ───────────────── scroll-into-view observer ───────────────── */
function useScrollAnimation() {
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('visible')
          }
        })
      },
      { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
    )

    document.querySelectorAll('.animate-on-scroll').forEach((el) => observer.observe(el))
    return () => observer.disconnect()
  }, [])
}

/* ───────────────── Navbar ───────────────── */
function Navbar() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <nav className={`navbar ${scrolled ? 'scrolled' : ''}`}>
      <div className="container navbar-inner">
        <a href="#" className="navbar-logo">
          <div className="navbar-logo-icon">
            <span className="material-symbols-outlined">restaurant_menu</span>
          </div>
          <span>Kasir-AI</span>
        </a>

        <ul className="navbar-links">
          <li><a href="#tech">Tech Stack</a></li>
          <li><a href="#features">Fitur</a></li>
          <li><a href="#showcase">Demo</a></li>
          <li><a href="#architecture">Arsitektur</a></li>
        </ul>

        <a
          href="https://github.com/"
          target="_blank"
          rel="noopener noreferrer"
          className="navbar-cta"
        >
          <span>Lihat GitHub</span>
        </a>

        <button className="navbar-mobile-toggle" aria-label="Menu">
          <span className="material-symbols-outlined">menu</span>
        </button>
      </div>
    </nav>
  )
}

/* ───────────────── Hero ───────────────── */
function Hero() {
  return (
    <section className="hero" id="hero">
      {/* background decorations */}
      <div className="hero-bg">
        <div className="hero-bg-gradient hero-bg-gradient-1" />
        <div className="hero-bg-gradient hero-bg-gradient-2" />
        <div className="hero-bg-gradient hero-bg-gradient-3" />
        <div className="hero-grid" />
      </div>

      <div className="container hero-content">
        {/* left — text */}
        <div className="hero-text">
          <div className="hero-badge">
            <span className="material-symbols-outlined">auto_awesome</span>
            Full-Stack Portfolio Project
          </div>

          <h1 className="hero-title">
            Sistem POS Cerdas<br />
            <span className="gradient-text">Berbasis AI</span>
          </h1>

          <p className="hero-subtitle">
            Kasir-AI adalah aplikasi Point of Sale modern untuk restoran &amp; kafe,
            dibangun dengan arsitektur full-stack — REST API, Admin Dashboard,
            dan Aplikasi Mobile Android.
          </p>

          <div className="hero-actions">
            <a href="#showcase" className="btn-primary">
              <span className="material-symbols-outlined" style={{ fontSize: 20 }}>play_circle</span>
              Lihat Demo
            </a>
            <a href="#tech" className="btn-secondary">
              <span className="material-symbols-outlined">code</span>
              Tech Stack
            </a>
          </div>

          <div className="hero-stats">
            <div className="hero-stat">
              <div className="hero-stat-value gradient-text">3</div>
              <div className="hero-stat-label">Platform Apps</div>
            </div>
            <div className="hero-stat">
              <div className="hero-stat-value gradient-text">14</div>
              <div className="hero-stat-label">API Routes</div>
            </div>
            <div className="hero-stat">
              <div className="hero-stat-value gradient-text">20+</div>
              <div className="hero-stat-label">DB Tables</div>
            </div>
            <div className="hero-stat">
              <div className="hero-stat-value gradient-text">8</div>
              <div className="hero-stat-label">Mobile Screens</div>
            </div>
          </div>
        </div>

        {/* right — visual */}
        <div className="hero-visual">
          <div className="hero-image-wrapper">
            <img src="/images/dashboard.png" alt="Kasir-AI Admin Dashboard" loading="eager" />
          </div>

          {/* floating cards */}
          <div className="hero-float-card hero-float-card-1">
            <div className="float-card-label">Transaksi Hari Ini</div>
            <div className="float-card-value">
              Rp <span className="accent">2.450.000</span>
            </div>
          </div>
          <div className="hero-float-card hero-float-card-2">
            <div className="float-card-label">Pesanan Aktif</div>
            <div className="float-card-value">
              <span className="accent">12</span> pesanan
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ───────────────── Tech Stack ───────────────── */
const techCards = [
  {
    icon: 'dns',
    title: 'Backend API',
    desc: 'REST API yang robust dengan autentikasi, validasi, dan ORM modern untuk pengelolaan data bisnis.',
    tags: ['Express.js', 'TypeScript', 'Drizzle ORM', 'MySQL', 'Better Auth', 'Zod'],
    color: '#22d3ee',
  },
  {
    icon: 'dashboard',
    title: 'Admin Dashboard',
    desc: 'Panel admin berbasis web dengan manajemen produk, staf, inventaris, laporan, dan multi-cabang.',
    tags: ['React', 'Vite', 'React Router', 'Recharts', 'TailwindCSS'],
    color: '#3b82f6',
  },
  {
    icon: 'phone_android',
    title: 'Mobile App',
    desc: 'Aplikasi kasir Android dengan UI modern, manajemen shift, kitchen display, dan admin dashboard.',
    tags: ['Flutter', 'Dart', 'Provider', 'Material 3', 'SharedPreferences'],
    color: '#a78bfa',
  },
]

function TechStack() {
  return (
    <section className="section tech-section" id="tech">
      <div className="container">
        <div className="tech-header animate-on-scroll">
          <div className="section-label">
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>code</span>
            Tech Stack
          </div>
          <h2 className="section-title">
            Dibangun dengan <span className="gradient-text">Teknologi Modern</span>
          </h2>
          <p className="section-desc">
            Monorepo full-stack yang mengintegrasikan tiga platform dalam satu ekosistem terpadu.
          </p>
        </div>

        <div className="tech-grid">
          {techCards.map((card, i) => (
            <div className={`tech-card animate-on-scroll delay-${i + 1}`} key={card.title}>
              <div
                className="tech-card-icon"
                style={{ background: `${card.color}15`, color: card.color }}
              >
                <span className="material-symbols-outlined">{card.icon}</span>
              </div>
              <h3 className="tech-card-title">{card.title}</h3>
              <p className="tech-card-desc">{card.desc}</p>
              <div className="tech-tags">
                {card.tags.map((tag) => (
                  <span className="tech-tag" key={tag}>{tag}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ───────────────── Features ───────────────── */
const features = [
  {
    icon: 'point_of_sale',
    title: 'Point of Sale',
    desc: 'Interface kasir lengkap dengan keranjang belanja, pencarian produk, dan proses pembayaran cepat.',
    color: '#22d3ee',
  },
  {
    icon: 'inventory_2',
    title: 'Manajemen Inventaris',
    desc: 'Tracking stok real-time, penyesuaian stok, peringatan stok kritis, dan bahan baku produk.',
    color: '#34d399',
  },
  {
    icon: 'group',
    title: 'Manajemen Staf',
    desc: 'Role-based access control untuk Admin, Kasir, dan Dapur dengan autentikasi aman.',
    color: '#3b82f6',
  },
  {
    icon: 'restaurant',
    title: 'Kitchen Display',
    desc: 'Tampilan dapur real-time untuk memproses pesanan masuk dengan status tracking.',
    color: '#fbbf24',
  },
  {
    icon: 'bar_chart',
    title: 'Laporan & Analitik',
    desc: 'Laporan penjualan harian, produk terlaris, grafik revenue, dan rekapitulasi shift.',
    color: '#a78bfa',
  },
  {
    icon: 'store',
    title: 'Multi-Cabang',
    desc: 'Dukungan operasional multi-cabang dengan manajemen produk dan staf per lokasi.',
    color: '#fb7185',
  },
  {
    icon: 'schedule',
    title: 'Manajemen Shift',
    desc: 'Buka & tutup shift kasir dengan modal awal, perhitungan selisih, dan rekap otomatis.',
    color: '#22d3ee',
  },
  {
    icon: 'receipt_long',
    title: 'Struk & Transaksi',
    desc: 'Generate struk pembayaran, riwayat transaksi lengkap, dan manajemen pengeluaran.',
    color: '#34d399',
  },
  {
    icon: 'auto_awesome',
    title: 'AI Insights',
    desc: 'Wawasan bisnis berbasis AI untuk membantu pengambilan keputusan dan optimasi operasional.',
    color: '#a78bfa',
  },
]

function Features() {
  return (
    <section className="section" id="features">
      <div className="container">
        <div className="features-header animate-on-scroll">
          <div className="section-label">
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>widgets</span>
            Fitur
          </div>
          <h2 className="section-title">
            Fitur <span className="gradient-text">Lengkap & Terintegrasi</span>
          </h2>
          <p className="section-desc">
            Semua yang dibutuhkan bisnis F&B modern, dari kasir hingga analitik, dalam satu platform.
          </p>
        </div>

        <div className="features-grid">
          {features.map((f, i) => (
            <div className={`feature-card animate-on-scroll delay-${(i % 3) + 1}`} key={f.title}>
              <div
                className="feature-icon"
                style={{ background: `${f.color}15`, color: f.color }}
              >
                <span className="material-symbols-outlined">{f.icon}</span>
              </div>
              <h3 className="feature-title">{f.title}</h3>
              <p className="feature-desc">{f.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ───────────────── Showcase ───────────────── */
const showcaseTabs = [
  { id: 'dashboard', label: 'Admin Dashboard', image: '/images/dashboard.png' },
  { id: 'mobile', label: 'Mobile App', image: '/images/mobile.png' },
  { id: 'api', label: 'API Architecture', image: '/images/api.png' },
]

function Showcase() {
  const [activeTab, setActiveTab] = useState('dashboard')
  const activeImage = showcaseTabs.find((t) => t.id === activeTab)?.image

  return (
    <section className="section showcase-section" id="showcase">
      <div className="container">
        <div className="showcase-header animate-on-scroll">
          <div className="section-label">
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>monitor</span>
            Demo
          </div>
          <h2 className="section-title">
            Lihat <span className="gradient-text">Dalam Aksi</span>
          </h2>
          <p className="section-desc">
            Eksplorasi tampilan setiap platform — dari admin dashboard hingga mobile cashier.
          </p>
        </div>

        <div className="showcase-tabs animate-on-scroll delay-1">
          {showcaseTabs.map((tab) => (
            <button
              key={tab.id}
              className={`showcase-tab ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="showcase-content animate-on-scroll delay-2">
          <div className="showcase-image-wrapper">
            <img
              src={activeImage}
              alt={`Kasir-AI ${activeTab} screenshot`}
              key={activeTab}
              style={{ animation: 'fade-in-up 0.4s ease-out' }}
            />
          </div>
        </div>
      </div>
    </section>
  )
}

/* ───────────────── Architecture ───────────────── */
function Architecture() {
  return (
    <section className="section" id="architecture">
      <div className="container">
        <div className="features-header animate-on-scroll">
          <div className="section-label">
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>hub</span>
            Arsitektur
          </div>
          <h2 className="section-title">
            Arsitektur <span className="gradient-text">Sistem</span>
          </h2>
          <p className="section-desc">
            Didesain dengan arsitektur yang bersih, modular, dan scalable.
          </p>
        </div>

        <div className="arch-content">
          <div className="arch-visual animate-on-scroll">
            <div className="code-window">
              <div className="code-window-header">
                <div className="code-window-dot red" />
                <div className="code-window-dot yellow" />
                <div className="code-window-dot green" />
              </div>
              <div className="code-window-body">
                <pre>{`kasir-ai/
├── apps/
│   ├── `}<span className="type">api/</span>{`              `}<span className="comment">// Express + TypeScript</span>{`
│   │   ├── src/
│   │   │   ├── `}<span className="func">routes/</span>{`     `}<span className="comment">// 14 route modules</span>{`
│   │   │   ├── `}<span className="func">db/schema/</span>{`  `}<span className="comment">// 20 Drizzle tables</span>{`
│   │   │   ├── `}<span className="func">services/</span>{`   `}<span className="comment">// Business logic</span>{`
│   │   │   └── `}<span className="func">middleware/</span>{` `}<span className="comment">// Auth, CORS, etc.</span>{`
│   │   └── drizzle.config.ts
│   │
│   ├── `}<span className="keyword">admin/</span>{`            `}<span className="comment">// React + Vite</span>{`
│   │   └── src/
│   │       ├── `}<span className="string">pages/</span>{`      `}<span className="comment">// 14 page components</span>{`
│   │       ├── `}<span className="string">components/</span>{` `}<span className="comment">// 9 shared components</span>{`
│   │       ├── `}<span className="string">hooks/</span>{`      `}<span className="comment">// Custom React hooks</span>{`
│   │       └── `}<span className="string">services/</span>{`   `}<span className="comment">// API service layer</span>{`
│   │
│   └── `}<span className="number">mobile/</span>{`           `}<span className="comment">// Flutter + Dart</span>{`
│       └── lib/
│           ├── `}<span className="number">screens/</span>{`    `}<span className="comment">// 8 app screens</span>{`
│           ├── `}<span className="number">providers/</span>{`  `}<span className="comment">// State management</span>{`
│           ├── `}<span className="number">services/</span>{`   `}<span className="comment">// API integration</span>{`
│           └── `}<span className="number">config/</span>{`     `}<span className="comment">// Theme & settings</span>{`
│
└── package.json          `}<span className="comment">// Monorepo workspace</span></pre>
              </div>
            </div>
          </div>

          <div className="arch-info animate-on-scroll delay-2">
            <h3>Clean Monorepo<br /><span className="gradient-text">Architecture</span></h3>
            <p>
              Proyek menggunakan npm workspaces untuk mengelola tiga aplikasi dalam satu repository.
              Setiap layer didesain terpisah namun terintegrasi melalui REST API.
            </p>

            <ul className="arch-list">
              <li>
                <div className="arch-list-icon" style={{ background: 'rgba(34,211,238,0.15)', color: 'var(--accent-cyan)' }}>
                  <span className="material-symbols-outlined" style={{ fontSize: 18 }}>security</span>
                </div>
                <div className="arch-list-text">
                  <strong>Auth & Security</strong>
                  <span>Better Auth + Helmet + CORS untuk keamanan berlapis</span>
                </div>
              </li>
              <li>
                <div className="arch-list-icon" style={{ background: 'rgba(59,130,246,0.15)', color: 'var(--accent-blue)' }}>
                  <span className="material-symbols-outlined" style={{ fontSize: 18 }}>database</span>
                </div>
                <div className="arch-list-text">
                  <strong>Type-Safe Database</strong>
                  <span>Drizzle ORM dengan 20 tabel relasional di MySQL</span>
                </div>
              </li>
              <li>
                <div className="arch-list-icon" style={{ background: 'rgba(167,139,250,0.15)', color: 'var(--accent-purple)' }}>
                  <span className="material-symbols-outlined" style={{ fontSize: 18 }}>verified</span>
                </div>
                <div className="arch-list-text">
                  <strong>Validasi End-to-End</strong>
                  <span>Zod schema validation di API + form validation di client</span>
                </div>
              </li>
              <li>
                <div className="arch-list-icon" style={{ background: 'rgba(52,211,153,0.15)', color: 'var(--accent-emerald)' }}>
                  <span className="material-symbols-outlined" style={{ fontSize: 18 }}>sync</span>
                </div>
                <div className="arch-list-text">
                  <strong>Multi-Role System</strong>
                  <span>3 role berbeda: Admin, Kasir, Dapur — masing-masing dengan UI sendiri</span>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ───────────────── Stats ───────────────── */
const stats = [
  { value: '14', label: 'API Route Modules', color: 'var(--accent-cyan)' },
  { value: '20+', label: 'Database Tables', color: 'var(--accent-blue)' },
  { value: '36', label: 'Page & Screen', color: 'var(--accent-purple)' },
  { value: '3', label: 'Platform Terintegrasi', color: 'var(--accent-emerald)' },
]

function Stats() {
  return (
    <section className="stats-section">
      <div className="container">
        <div className="stats-grid">
          {stats.map((s, i) => (
            <div className={`stat-card animate-on-scroll delay-${i + 1}`} key={s.label}>
              <div className="stat-value" style={{ color: s.color }}>{s.value}</div>
              <div className="stat-label">{s.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ───────────────── CTA ───────────────── */
function CTA() {
  return (
    <section className="cta-section">
      <div className="container cta-content animate-on-scroll">
        <h2 className="cta-title">
          Tertarik dengan <span className="gradient-text">proyek ini?</span>
        </h2>
        <p className="cta-desc">
          Lihat source code lengkap di GitHub atau hubungi saya untuk kolaborasi dan diskusi lebih lanjut.
        </p>
        <div className="cta-actions">
          <a href="https://github.com/" target="_blank" rel="noopener noreferrer" className="btn-primary">
            <span className="material-symbols-outlined" style={{ fontSize: 20 }}>code</span>
            Source Code
          </a>
          <a href="mailto:your@email.com" className="btn-secondary">
            <span className="material-symbols-outlined" style={{ fontSize: 20 }}>mail</span>
            Hubungi Saya
          </a>
        </div>
      </div>
    </section>
  )
}

/* ───────────────── Footer ───────────────── */
function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-inner">
        <div className="footer-brand">
          <div className="footer-brand-icon">
            <span className="material-symbols-outlined" style={{ fontSize: 18, color: '#fff' }}>restaurant_menu</span>
          </div>
          <span className="footer-brand-name">Kasir-AI</span>
        </div>

        <span className="footer-copy">© 2026 Kasir-AI — Portfolio Project</span>

        <div className="footer-links">
          <a href="https://github.com/" target="_blank" rel="noopener noreferrer">GitHub</a>
          <a href="https://linkedin.com/" target="_blank" rel="noopener noreferrer">LinkedIn</a>
          <a href="mailto:your@email.com">Email</a>
        </div>
      </div>
    </footer>
  )
}

/* ───────────────── App ───────────────── */
export default function App() {
  useScrollAnimation()

  return (
    <>
      <Navbar />
      <Hero />
      <TechStack />
      <Features />
      <Showcase />
      <Architecture />
      <Stats />
      <CTA />
      <Footer />
    </>
  )
}

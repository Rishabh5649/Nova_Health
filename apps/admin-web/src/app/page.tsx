'use client';

import Link from "next/link";
import { useState } from "react";

export default function LandingPage() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', overflowX: 'hidden' }}>

      {/* Navigation */}
      <nav className="glass" style={{ position: 'sticky', top: 0, zIndex: 50, padding: '1rem 0' }}>
        <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <img src="/logo.png" alt="Nova Health" style={{ height: '40px', objectFit: 'contain' }} />
            <span style={{ fontSize: '1.5rem', fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--text-main)' }}>Nova Health</span>
          </Link>

          {/* Desktop Menu */}
          <div className="hidden-mobile" style={{ display: 'flex', gap: '2.5rem', alignItems: 'center' }}>
            <a href="#features" className="nav-item-public" style={{ fontWeight: 500, color: 'var(--text-muted)' }}>Features</a>
            <a href="#how-it-works" className="nav-item-public" style={{ fontWeight: 500, color: 'var(--text-muted)' }}>How it Works</a>
            <a href="#testimonials" className="nav-item-public" style={{ fontWeight: 500, color: 'var(--text-muted)' }}>Success Stories</a>
            <Link href="/login" className="btn btn-outline" style={{ padding: '0.6rem 1.5rem' }}>Sign In</Link>
            <Link href="/register" className="btn btn-primary" style={{ padding: '0.6rem 1.5rem' }}>Register</Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <header style={{
        paddingTop: '8rem',
        paddingBottom: '8rem',
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
        background: 'radial-gradient(circle at 50% 50%, rgba(59, 130, 246, 0.05) 0%, transparent 50%)'
      }}>
        <div className="container" style={{ position: 'relative', zIndex: 10, textAlign: 'center' }}>
          <div className="animate-fade-in" style={{ maxWidth: '900px', margin: '0 auto' }}>
            <span className="badge badge-primary" style={{ marginBottom: '1.5rem', padding: '0.5rem 1rem', fontSize: '0.85rem' }}>
              🚀 The Future of Hospital Management
            </span>
            <h1 className="title-gradient" style={{
              fontSize: '4.5rem',
              fontWeight: 800,
              lineHeight: 1.1,
              marginBottom: '1.5rem',
              letterSpacing: '-0.04em'
            }}>
              Healthcare Operations, <br /> Simplified.
            </h1>
            <p style={{
              fontSize: '1.25rem',
              color: 'var(--text-muted)',
              marginBottom: '3rem',
              lineHeight: 1.6,
              maxWidth: '700px',
              marginLeft: 'auto',
              marginRight: 'auto'
            }}>
              Nova Health empowers clinics and hospitals with a unified platform for appointments, staff management, and patient care.
              Beautiful, efficient, and built for modern healthcare.
            </p>
            <div style={{ display: 'flex', gap: '1.25rem', justifyContent: 'center', alignItems: 'center' }}>
              <Link href="/register" className="btn btn-primary" style={{ padding: '1rem 2.5rem', fontSize: '1.1rem' }}>
                Register Organization
              </Link>
              <Link href="/login" className="btn btn-outline" style={{ padding: '1rem 2.5rem', fontSize: '1.1rem', background: 'transparent' }}>
                Sign In
              </Link>
            </div>

            <div style={{ marginTop: '4rem', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
              <p>Trusted by leading healthcare providers</p>
              <div style={{ display: 'flex', gap: '3rem', justifyContent: 'center', marginTop: '1.5rem', opacity: 0.6, fontSize: '1.5rem', fontWeight: 700, filter: 'grayscale(100%)' }}>
                <span>CITY HOSPITAL</span>
                <span>APOLLO CLINIC</span>
                <span>MEDICARE+</span>
                <span>HEALTHHUB</span>
              </div>
            </div>
          </div>
        </div>

        {/* Decorative Blobs */}
        <div style={{ position: 'absolute', top: '-10%', left: '-5%', width: '600px', height: '600px', background: 'radial-gradient(circle, rgba(59, 130, 246, 0.08) 0%, rgba(0,0,0,0) 70%)', borderRadius: '50%', zIndex: 0 }} />
        <div style={{ position: 'absolute', bottom: '-10%', right: '-5%', width: '500px', height: '500px', background: 'radial-gradient(circle, rgba(16, 185, 129, 0.08) 0%, rgba(0,0,0,0) 70%)', borderRadius: '50%', zIndex: 0 }} />
      </header>

      {/* Features Section */}
      <section id="features" style={{ padding: '6rem 0' }}>
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '5rem' }}>
            <h2 className="title-gradient" style={{ fontSize: '3rem', fontWeight: 800, marginBottom: '1rem' }}>Everything you need</h2>
            <p style={{ fontSize: '1.25rem', color: 'var(--text-muted)' }}>Powerful features to streamline your entire organization.</p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '2.5rem' }}>
            {/* Feature 1 */}
            <div className="glass-card" style={{ padding: '2.5rem', borderRadius: '1.5rem' }}>
              <div style={{ width: '60px', height: '60px', borderRadius: '16px', background: 'rgba(59, 130, 246, 0.1)', color: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', marginBottom: '1.5rem' }}>
                📅
              </div>
              <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1rem' }}>Smart Scheduling</h3>
              <p style={{ color: 'var(--text-muted)', lineHeight: 1.6 }}>
                Efficiently manage appointments with our intuitive calendar. Reduce no-shows with automated reminders.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="glass-card" style={{ padding: '2.5rem', borderRadius: '1.5rem' }}>
              <div style={{ width: '60px', height: '60px', borderRadius: '16px', background: 'rgba(16, 185, 129, 0.1)', color: 'var(--success)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', marginBottom: '1.5rem' }}>
                👥
              </div>
              <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1rem' }}>Staff Management</h3>
              <p style={{ color: 'var(--text-muted)', lineHeight: 1.6 }}>
                Handle shifts, roles, and permissions with ease. Empower your doctors and receptionists with the right tools.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="glass-card" style={{ padding: '2.5rem', borderRadius: '1.5rem' }}>
              <div style={{ width: '60px', height: '60px', borderRadius: '16px', background: 'rgba(245, 158, 11, 0.1)', color: 'var(--warning)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', marginBottom: '1.5rem' }}>
                🌐
              </div>
              <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1rem' }}>Public Presence</h3>
              <p style={{ color: 'var(--text-muted)', lineHeight: 1.6 }}>
                Get a beautiful, automatically generated public website for your organization that showcases your doctors.
              </p>
            </div>

            {/* Feature 4 */}
            <div className="glass-card" style={{ padding: '2.5rem', borderRadius: '1.5rem' }}>
              <div style={{ width: '60px', height: '60px', borderRadius: '16px', background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', marginBottom: '1.5rem' }}>
                📊
              </div>
              <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1rem' }}>Analytics</h3>
              <p style={{ color: 'var(--text-muted)', lineHeight: 1.6 }}>
                Gain actionable insights into your clinic's performance with detailed reports and visualizations.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" style={{ padding: '6rem 0', background: 'var(--bg-secondary)' }}>
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '5rem' }}>
            <h2 style={{ fontSize: '3rem', fontWeight: 800, marginBottom: '1rem' }}>How it works</h2>
            <p style={{ fontSize: '1.25rem', color: 'var(--text-muted)' }}>Get up and running in minutes, not months.</p>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '2rem', position: 'relative' }}>
            {/* Step 1 */}
            <div style={{ textAlign: 'center' }}>
              <div style={{ width: '80px', height: '80px', background: 'white', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', fontWeight: 'bold', margin: '0 auto 1.5rem', boxShadow: 'var(--shadow-lg)', border: '4px solid var(--primary-light)' }}>
                1
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Register Organization</h3>
              <p style={{ color: 'var(--text-muted)' }}>Sign up and set up your hospital profile.</p>
            </div>

            {/* Step 2 */}
            <div style={{ textAlign: 'center' }}>
              <div style={{ width: '80px', height: '80px', background: 'white', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', fontWeight: 'bold', margin: '0 auto 1.5rem', boxShadow: 'var(--shadow-lg)', border: '4px solid var(--primary-light)' }}>
                2
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Add Staff</h3>
              <p style={{ color: 'var(--text-muted)' }}>Invite your doctors and receptionists.</p>
            </div>

            {/* Step 3 */}
            <div style={{ textAlign: 'center' }}>
              <div style={{ width: '80px', height: '80px', background: 'white', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', fontWeight: 'bold', margin: '0 auto 1.5rem', boxShadow: 'var(--shadow-lg)', border: '4px solid var(--primary-light)' }}>
                3
              </div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Go Live</h3>
              <p style={{ color: 'var(--text-muted)' }}>Start managing appointments and patients.</p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA / Contact */}
      <section id="contact" style={{ padding: '8rem 0' }}>
        <div className="container">
          <div className="glass-card" style={{
            background: 'linear-gradient(135deg, #1e293b 0%, #0f172a 100%)',
            borderRadius: '2rem',
            padding: '4rem',
            textAlign: 'center',
            color: 'white',
            border: '1px solid rgba(255,255,255,0.1)'
          }}>
            <h2 style={{ fontSize: '3rem', fontWeight: 800, marginBottom: '1.5rem' }}>Ready to transform your practice?</h2>
            <p style={{ fontSize: '1.25rem', color: '#94a3b8', marginBottom: '3rem', maxWidth: '600px', margin: '0 auto 3rem' }}>
              Join hundreds of forward-thinking healthcare providers who trust Nova Health.
            </p>

            <div style={{ maxWidth: '500px', margin: '0 auto', display: 'flex', gap: '1rem' }}>
              <input type="email" placeholder="Enter your work email" style={{ flex: 1, padding: '1rem 1.5rem', borderRadius: '9999px', border: 'none', background: 'rgba(255,255,255,0.1)', color: 'white' }} />
              <button className="btn btn-primary" style={{ padding: '1rem 2rem' }}>Get Started</button>
            </div>
            <p style={{ fontSize: '0.875rem', color: '#64748b', marginTop: '1rem' }}>No credit card required for demo.</p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer style={{ background: 'var(--bg-sidebar)', color: 'white', padding: '4rem 0' }}>
        <div className="container">
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '3rem', marginBottom: '3rem' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                <div style={{ width: '32px', height: '32px', background: 'var(--primary-gradient)', borderRadius: '8px' }}></div>
                <span style={{ fontSize: '1.25rem', fontWeight: 'bold' }}>Nova Health</span>
              </div>
              <p style={{ color: '#94a3b8', lineHeight: 1.6 }}>
                The complete operating system for modern healthcare organizations.
              </p>
            </div>

            <div>
              <h4 style={{ fontWeight: 'bold', marginBottom: '1rem' }}>Product</h4>
              <ul style={{ listStyle: 'none', padding: 0, color: '#94a3b8', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <li><a href="#">Features</a></li>
                <li><a href="#">Pricing</a></li>
                <li><a href="#">Security</a></li>
                <li><a href="#">Changelog</a></li>
              </ul>
            </div>

            <div>
              <h4 style={{ fontWeight: 'bold', marginBottom: '1rem' }}>Company</h4>
              <ul style={{ listStyle: 'none', padding: 0, color: '#94a3b8', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <li><a href="#">About Us</a></li>
                <li><a href="#">Careers</a></li>
                <li><a href="#">Blog</a></li>
                <li><a href="#">Contact</a></li>
              </ul>
            </div>

            <div>
              <h4 style={{ fontWeight: 'bold', marginBottom: '1rem' }}>Legal</h4>
              <ul style={{ listStyle: 'none', padding: 0, color: '#94a3b8', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <li><a href="#">Privacy Policy</a></li>
                <li><a href="#">Terms of Service</a></li>
              </ul>
            </div>
          </div>

          <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '2rem', textAlign: 'center', color: '#64748b' }}>
            © {new Date().getFullYear()} Nova Health Inc. All rights reserved.
          </div>
        </div>
      </footer>

    </div>
  );
}

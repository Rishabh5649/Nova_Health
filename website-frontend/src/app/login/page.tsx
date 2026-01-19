'use client';

import { useState } from 'react';
import Link from "next/link";
import { useRouter } from 'next/navigation';
import { login } from '@/lib/api';

export default function LoginPage() {
    const router = useRouter();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const data = await login(email, password);
            // Store token (in a real app, use httpOnly cookies or a more secure method)
            localStorage.setItem('token', data.token);
            localStorage.setItem('user', JSON.stringify(data.user));

            // Check role
            if (data.user.role === 'ADMIN') {
                router.push('/super-admin');
            } else if (['ORG_ADMIN', 'RECEPTIONIST'].includes(data.user.role) ||
                (data.user.memberships && data.user.memberships.length > 0)) {
                router.push('/dashboard');
            } else {
                setError('Access denied. Portal is for staff only.');
                localStorage.removeItem('token');
            }
        } catch (err: any) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)'
        }}>
            <div className="glass-card" style={{ width: '100%', maxWidth: '420px', padding: '2.5rem' }}>
                <div style={{ marginBottom: '2rem', textAlign: 'center' }}>
                    <Link href="/" style={{ display: 'inline-block', marginBottom: '1rem' }}>
                        <img src="/logo.png" alt="Nova Health" style={{ height: '50px', objectFit: 'contain' }} />
                    </Link>
                    <h1 className="title-gradient" style={{ fontSize: '1.75rem', fontWeight: 'bold' }}>Portal Login</h1>
                    <p style={{ color: 'var(--text-muted)', marginTop: '0.5rem' }}>Access your organization dashboard</p>
                </div>

                <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                    {error && (
                        <div className="badge-error" style={{ padding: '0.75rem', borderRadius: 'var(--radius)', textAlign: 'center' }}>
                            {error}
                        </div>
                    )}

                    <div style={{ textAlign: 'left' }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-main)' }}>Email Address</label>
                        <input
                            type="email"
                            className="input"
                            placeholder="admin@hospital.com"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>

                    <div style={{ textAlign: 'left' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                            <label style={{ fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-main)' }}>Password</label>
                            <Link href="#" style={{ fontSize: '0.875rem', color: 'var(--primary)', fontWeight: 500 }}>Forgot password?</Link>
                        </div>
                        <input
                            type="password"
                            className="input"
                            placeholder="••••••••"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        className="btn btn-primary"
                        style={{ marginTop: '0.5rem', width: '100%' }}
                        disabled={loading}
                    >
                        {loading ? 'Authenticating...' : 'Sign In'}
                    </button>
                </form>

                <div style={{ marginTop: '2rem', borderTop: '1px solid var(--border-color)', paddingTop: '1.5rem', textAlign: 'center' }}>
                    <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                        New organization? <Link href="/register" style={{ color: 'var(--primary)', fontWeight: 600 }}>Register Now</Link>
                    </p>
                </div>
            </div>
        </div>
    );
}

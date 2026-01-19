'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter, usePathname } from 'next/navigation';

export default function SuperAdminLayout({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const [user, setUser] = useState<any>(null);

    useEffect(() => {
        const token = localStorage.getItem('token');
        const userData = localStorage.getItem('user');

        if (!token || !userData) {
            router.push('/login');
            return;
        }

        try {
            const parsedUser = JSON.parse(userData);
            if (parsedUser.role !== 'ADMIN') {
                router.push('/dashboard'); // Not a super admin
                return;
            }
            setUser(parsedUser);
        } catch (e) {
            router.push('/login');
        }
    }, [router]);

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        router.push('/login');
    };

    if (!user) return null;

    return (
        <div className="layout-grid">
            {/* Sidebar */}
            <aside className="sidebar">
                <div style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div style={{ width: '32px', height: '32px', background: 'var(--primary-gradient)', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold' }}>S</div>
                    <span style={{ fontSize: '1.25rem', fontWeight: 'bold' }}>Super Admin</span>
                </div>

                <nav style={{ flex: 1 }}>
                    <Link href="/super-admin" className={`nav-item ${pathname === '/super-admin' ? 'active' : ''}`}>
                        🏢 Organizations
                    </Link>
                    <Link href="/super-admin/patients" className={`nav-item ${pathname === '/super-admin/patients' ? 'active' : ''}`}>
                        👥 Patients
                    </Link>
                    <Link href="/super-admin/settings" className={`nav-item ${pathname === '/super-admin/settings' ? 'active' : ''}`}>
                        ⚙️ Settings
                    </Link>
                </nav>

                <div style={{ paddingTop: '1rem', borderTop: '1px solid rgba(255,255,255,0.1)' }}>
                    <div style={{ marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            {user.name.charAt(0)}
                        </div>
                        <div style={{ overflow: 'hidden' }}>
                            <div style={{ fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user.name}</div>
                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Super Admin</div>
                        </div>
                    </div>
                    <button onClick={handleLogout} className="btn btn-outline" style={{ width: '100%', justifyContent: 'center', borderColor: 'rgba(239, 68, 68, 0.5)', color: 'var(--danger)' }}>
                        Sign Out
                    </button>
                </div>
            </aside>

            {/* Main Content */}
            <main className="main-content">
                {children}
            </main>
        </div>
    );
}

'use client';

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    const router = useRouter();
    const pathname = usePathname();
    const [user, setUser] = useState<any>(null);
    const [role, setRole] = useState<string>('');

    useEffect(() => {
        const userStr = localStorage.getItem('user');
        if (!userStr) {
            router.push('/');
            return;
        }
        try {
            const userData = JSON.parse(userStr);
            setUser(userData);
            setRole(userData.memberships?.[0]?.role || '');
        } catch (e) {
            console.error('Error parsing user data', e);
        }
    }, [router]);

    const isAdmin = role === 'ORG_ADMIN';

    return (
        <div className="layout-grid">
            {/* Sidebar */}
            <aside className="sidebar">
                <div style={{ marginBottom: '2rem', paddingLeft: '1rem' }}>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 'bold' }}>HMS {isAdmin ? 'Admin' : 'Portal'}</h2>
                    <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>City Hospital</p>
                </div>

                <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                    <Link href="/dashboard" className={`nav-item ${pathname === '/dashboard' ? 'active' : ''}`}>
                        <span>Dashboard</span>
                    </Link>
                    <Link href="/dashboard/appointments" className={`nav-item ${pathname?.includes('/appointments') ? 'active' : ''}`}>
                        <span>Appointments</span>
                    </Link>
                    <Link href="/dashboard/calendar" className={`nav-item ${pathname?.includes('/calendar') ? 'active' : ''}`}>
                        <span>Calendar</span>
                    </Link>
                    <Link href="/dashboard/patients" className={`nav-item ${pathname?.includes('/patients') ? 'active' : ''}`}>
                        <span>Patients</span>
                    </Link>
                    <Link href="/dashboard/doctors" className={`nav-item ${pathname?.includes('/doctors') ? 'active' : ''}`}>
                        <span>Doctors</span>
                    </Link>
                    <Link href="/dashboard/reschedule-requests" className={`nav-item ${pathname?.includes('/reschedule-requests') ? 'active' : ''}`}>
                        <span>📅 Reschedule Requests</span>
                    </Link>

                    {isAdmin && (
                        <>
                            <Link href="/dashboard/staff" className={`nav-item ${pathname?.includes('/staff') ? 'active' : ''}`}>
                                <span>👥 Staff Management</span>
                            </Link>
                            <Link href="/dashboard/settings/organization" className={`nav-item ${pathname?.includes('/settings/organization') ? 'active' : ''}`}>
                                <span>⚙️ Organization</span>
                            </Link>
                            <Link href="/dashboard/settings" className={`nav-item ${pathname === '/dashboard/settings' ? 'active' : ''}`}>
                                <span>Settings</span>
                            </Link>
                        </>
                    )}
                </nav>

                <div style={{ marginTop: 'auto', borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '1rem' }}>
                    <div className="nav-item" onClick={() => {
                        localStorage.removeItem('token');
                        localStorage.removeItem('user');
                        router.push('/');
                    }} style={{ cursor: 'pointer' }}>
                        <span>Sign Out</span>
                    </div>
                </div>
            </aside>

            {/* Main Content */}
            <main className="main-content">
                <header className="header">
                    <h1 style={{ fontSize: '1.5rem', fontWeight: 600 }}>Overview</h1>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                        <div style={{ textAlign: 'right' }}>
                            <p style={{ fontSize: '0.875rem', fontWeight: 500 }}>{user?.name || 'User'}</p>
                            <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{role.replace('ORG_', '')}</p>
                        </div>
                        <div style={{ width: '40px', height: '40px', borderRadius: '50%', backgroundColor: 'var(--primary-light)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold' }}>
                            {user?.name?.[0] || 'U'}
                        </div>
                    </div>
                </header>
                {children}
            </main>
        </div>
    );
}

'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAppointments, getPendingStaff } from '@/lib/api';

export default function DashboardPage() {
    const router = useRouter();
    const [appointments, setAppointments] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [pendingStaff, setPendingStaff] = useState(0);
    const [stats, setStats] = useState({
        today: 0,
        pending: 0,
        completed: 0,
    });
    const [role, setRole] = useState('');

    useEffect(() => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');

        if (!token || !userStr) {
            router.push('/');
            return;
        }

        const user = JSON.parse(userStr);
        const orgId = user.memberships?.[0]?.organizationId;
        const userRole = user.memberships?.[0]?.role;
        setRole(userRole);

        // Fetch appointments
        getAppointments(token, orgId)
            .then((data) => {
                setAppointments(data.slice(0, 5)); // Show latest 5

                // Calculate stats
                const now = new Date();
                const today = data.filter((a: any) => {
                    const apptDate = new Date(a.scheduledAt);
                    return apptDate.toDateString() === now.toDateString();
                }).length;

                const pending = data.filter((a: any) => a.status === 'PENDING').length;
                const completed = data.filter((a: any) => a.status === 'COMPLETED').length;

                setStats({ today, pending, completed });
            })
            .catch((err) => {
                console.error('Failed to load appointments:', err);
            });

        // Fetch pending staff count ONLY if admin
        if (orgId && userRole === 'ORG_ADMIN') {
            getPendingStaff(token, orgId)
                .then((data) => {
                    setPendingStaff(data.length);
                })
                .catch((err) => {
                    console.error('Failed to load pending staff:', err);
                })
                .finally(() => {
                    setLoading(false);
                });
        } else {
            setLoading(false);
        }
    }, [router]);

    if (loading) {
        return (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
                <div>Loading...</div>
            </div>
        );
    }

    const isAdmin = role === 'ORG_ADMIN';

    return (
        <div>
            {/* Stats Row */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
                <div className="card">
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Appointments Today</p>
                    <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--primary)' }}>{stats.today}</h3>
                    <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: '0.5rem' }}>Scheduled for today</p>
                </div>
                <div className="card">
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Pending Requests</p>
                    <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--warning)' }}>{stats.pending}</h3>
                    <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: '0.5rem' }}>Requires attention</p>
                </div>
                <div className="card">
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Completed</p>
                    <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--success)' }}>{stats.completed}</h3>
                    <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: '0.5rem' }}>All time</p>
                </div>

                {isAdmin && (
                    <div className="card" style={{ cursor: pendingStaff > 0 ? 'pointer' : 'default' }} onClick={() => pendingStaff > 0 && router.push('/dashboard/staff')}>
                        <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Pending Staff</p>
                        <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: pendingStaff > 0 ? 'var(--error)' : 'var(--text-main)' }}>
                            {pendingStaff}
                        </h3>
                        <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginTop: '0.5rem' }}>
                            Awaiting approval
                        </p>
                    </div>
                )}
            </div>

            {/* Recent Appointments */}
            <div className="card">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Recent Appointments</h3>
                    <button className="btn btn-outline" onClick={() => router.push('/dashboard/appointments')}>View All</button>
                </div>

                <div className="table-container">
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                            <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left' }}>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Patient</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Doctor</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Date & Time</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Status</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {appointments.length === 0 ? (
                                <tr>
                                    <td colSpan={5} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                        No appointments found
                                    </td>
                                </tr>
                            ) : (
                                appointments.map((appt: any) => (
                                    <tr key={appt.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <div style={{ fontWeight: 500 }}>{appt.patient?.name || 'Unknown'}</div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{appt.patient?.email}</div>
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>{appt.doctor?.name || 'Unassigned'}</td>
                                        <td style={{ padding: '1rem 0.75rem', fontSize: '0.875rem' }}>
                                            {new Date(appt.scheduledAt).toLocaleDateString()} at{' '}
                                            {new Date(appt.scheduledAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <span className={`badge ${appt.status === 'CONFIRMED' ? 'badge-success' :
                                                appt.status === 'PENDING' ? 'badge-warning' :
                                                    appt.status === 'COMPLETED' ? 'badge-success' :
                                                        'badge-default'
                                                }`}>
                                                {appt.status}
                                            </span>
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <button
                                                onClick={() => router.push(`/dashboard/appointments/${appt.id}`)}
                                                style={{
                                                    padding: '0.25rem 0.75rem',
                                                    fontSize: '0.75rem',
                                                    borderRadius: 'var(--radius)',
                                                    background: 'transparent',
                                                    color: 'var(--primary)',
                                                    border: '1px solid var(--primary)',
                                                    cursor: 'pointer',
                                                }}
                                            >
                                                View
                                            </button>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

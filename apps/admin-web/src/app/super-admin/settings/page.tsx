'use client';

import { useState } from 'react';

export default function SettingsPage() {
    const [maintenanceMode, setMaintenanceMode] = useState(false);
    const [allowRegistration, setAllowRegistration] = useState(true);

    // Mock data for audit logs
    const auditLogs = [
        { id: 1, action: 'Organization Approved', details: 'City Hospital approved by Super Admin', date: '2 mins ago', user: 'Rishabh Singh' },
        { id: 2, action: 'System Backup', details: 'Automated daily backup completed', date: '1 hour ago', user: 'System' },
        { id: 3, action: 'User Login', details: 'Admin logged in from new IP', date: '3 hours ago', user: 'Jane Doe' },
        { id: 4, action: 'Settings Updated', details: 'Changed default fee structure', date: 'Yesterday', user: 'Rishabh Singh' },
    ];

    return (
        <div className="animate-fade-in">
            <div className="header" style={{ marginBottom: '2rem' }}>
                <div>
                    <h1 className="title-gradient" style={{ fontSize: '2rem', fontWeight: 'bold' }}>Settings</h1>
                    <p style={{ color: 'var(--text-muted)' }}>Manage system configurations and monitor activity.</p>
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
                {/* System Health Cards */}
                <div className="card">
                    <h3 style={{ fontSize: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>System Status</h3>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: 'var(--success)' }}></div>
                        <span style={{ fontSize: '1.5rem', fontWeight: 600 }}>All Systems Operational</span>
                    </div>
                </div>
                <div className="card">
                    <h3 style={{ fontSize: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>Active Users</h3>
                    <div style={{ fontSize: '1.5rem', fontWeight: 600 }}>1,248</div>
                    <div style={{ fontSize: '0.875rem', color: 'var(--success)' }}>+12% from last week</div>
                </div>
                <div className="card">
                    <h3 style={{ fontSize: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>Server Load</h3>
                    <div style={{ fontSize: '1.5rem', fontWeight: 600 }}>24%</div>
                    <div style={{ width: '100%', height: '4px', background: 'var(--bg-secondary)', borderRadius: '2px', marginTop: '0.5rem' }}>
                        <div style={{ width: '24%', height: '100%', background: 'var(--primary)', borderRadius: '2px' }}></div>
                    </div>
                </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', alignItems: 'start' }}>
                {/* General Settings */}
                <div className="card">
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 600, marginBottom: '1.5rem' }}>General Configuration</h3>

                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem 0', borderBottom: '1px solid var(--border-color)' }}>
                        <div>
                            <div style={{ fontWeight: 500 }}>Maintenance Mode</div>
                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Disable access for all non-admin users</div>
                        </div>
                        <label className="toggle">
                            <input type="checkbox" checked={maintenanceMode} onChange={() => setMaintenanceMode(!maintenanceMode)} />
                            <span className="slider"></span>
                        </label>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem 0', borderBottom: '1px solid var(--border-color)' }}>
                        <div>
                            <div style={{ fontWeight: 500 }}>Allow New Registrations</div>
                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Enable or disable new organization signups</div>
                        </div>
                        <label className="toggle">
                            <input type="checkbox" checked={allowRegistration} onChange={() => setAllowRegistration(!allowRegistration)} />
                            <span className="slider"></span>
                        </label>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem 0' }}>
                        <div>
                            <div style={{ fontWeight: 500 }}>Data Backup</div>
                            <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Last backup: 2 hours ago</div>
                        </div>
                        <button className="btn btn-outline" style={{ fontSize: '0.875rem' }}>Trigger Backup</button>
                    </div>
                </div>

                {/* Audit Logs */}
                <div className="card">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                        <h3 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Recent Activity</h3>
                        <button className="btn btn-outline" style={{ fontSize: '0.75rem', padding: '0.25rem 0.75rem' }}>View All</button>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        {auditLogs.map((log) => (
                            <div key={log.id} style={{ display: 'flex', gap: '1rem', paddingBottom: '1rem', borderBottom: '1px solid var(--border-color)' }}>
                                <div style={{
                                    width: '36px', height: '36px', borderRadius: '50%',
                                    background: 'var(--bg-secondary)', color: 'var(--text-muted)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.875rem'
                                }}>
                                    {log.user.charAt(0)}
                                </div>
                                <div style={{ flex: 1 }}>
                                    <div style={{ fontSize: '0.9rem', fontWeight: 500 }}>{log.action}</div>
                                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{log.details}</div>
                                </div>
                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                                    {log.date}
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            <div className="card" style={{ marginTop: '2rem' }}>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 600, marginBottom: '1rem' }}>Admin Profile</h3>
                <div style={{ display: 'flex', gap: '2rem' }}>
                    <div style={{ flex: 1 }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Name</label>
                        <input className="input" defaultValue="Rishabh Singh" disabled style={{ background: 'var(--bg-secondary)' }} />
                    </div>
                    <div style={{ flex: 1 }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Email</label>
                        <input className="input" defaultValue="rishabhsingh30705@gmail.com" disabled style={{ background: 'var(--bg-secondary)' }} />
                    </div>
                </div>
            </div>
        </div>
    );
}

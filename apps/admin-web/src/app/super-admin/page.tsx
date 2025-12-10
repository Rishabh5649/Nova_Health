'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { getOrganizations, updateOrganizationStatus } from '@/lib/api';

export default function SuperAdminDashboard() {
    const [orgs, setOrgs] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('ALL'); // ALL, PENDING, APPROVED, REJECTED

    const fetchOrgs = async () => {
        setLoading(true);
        try {
            // Fetch all to allow client-side filtering for better UX
            const token = localStorage.getItem('token') || '';
            const data = await getOrganizations(token);
            setOrgs(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchOrgs();
    }, []);

    const handleStatusUpdate = async (id: string, newStatus: 'APPROVED' | 'REJECTED') => {
        if (!confirm(`Are you sure you want to ${newStatus.toLowerCase()} this organization?`)) return;

        try {
            const token = localStorage.getItem('token') || '';
            await updateOrganizationStatus(token, id, newStatus);
            // Refresh list
            fetchOrgs();
        } catch (e) {
            alert('Failed to update status');
            console.error(e);
        }
    };

    const filteredOrgs = orgs.filter(org => {
        if (statusFilter === 'ALL') return true;
        return org.status === statusFilter;
    });

    const pendingCount = orgs.filter(o => o.status === 'PENDING').length;

    return (
        <div>
            <div className="header">
                <div>
                    <h1 className="title-gradient" style={{ fontSize: '2rem', fontWeight: 'bold' }}>Organization Management</h1>
                    <p style={{ color: 'var(--text-muted)' }}>Manage and approve healthcare providers.</p>
                </div>
                <div style={{ display: 'flex', gap: '1rem' }}>
                    <button className="btn btn-outline" onClick={fetchOrgs}>Refresh List</button>
                    {/* <button className="btn btn-primary">+ Add Organization</button> */}
                </div>
            </div>

            {/* Stats / Filters */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1.5rem', marginBottom: '2rem' }}>
                <div
                    className={`card ${statusFilter === 'PENDING' ? 'ring-2 ring-primary' : ''}`}
                    style={{ cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
                    onClick={() => setStatusFilter('PENDING')}
                >
                    <div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>Pending Requests</div>
                        <div style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--warning)' }}>{pendingCount}</div>
                    </div>
                    <div style={{ fontSize: '1.5rem' }}>⏳</div>
                </div>

                <div
                    className={`card ${statusFilter === 'APPROVED' ? 'ring-2 ring-primary' : ''}`}
                    style={{ cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
                    onClick={() => setStatusFilter('APPROVED')}
                >
                    <div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>Active Organizations</div>
                        <div style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--success)' }}>
                            {orgs.filter(o => o.status === 'APPROVED').length}
                        </div>
                    </div>
                    <div style={{ fontSize: '1.5rem' }}>✅</div>
                </div>

                <div
                    className={`card ${statusFilter === 'REJECTED' ? 'ring-2 ring-primary' : ''}`}
                    style={{ cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
                    onClick={() => setStatusFilter('REJECTED')}
                >
                    <div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>Rejected</div>
                        <div style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--danger)' }}>
                            {orgs.filter(o => o.status === 'REJECTED').length}
                        </div>
                    </div>
                    <div style={{ fontSize: '1.5rem' }}>❌</div>
                </div>

                <div
                    className={`card ${statusFilter === 'ALL' ? 'ring-2 ring-primary' : ''}`}
                    style={{ cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
                    onClick={() => setStatusFilter('ALL')}
                >
                    <div>
                        <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>Total Organizations</div>
                        <div style={{ fontSize: '2rem', fontWeight: 'bold' }}>{orgs.length}</div>
                    </div>
                    <div style={{ fontSize: '1.5rem' }}>🏥</div>
                </div>
            </div>

            {/* List */}
            {/* Organization Cards */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.5rem' }}>
                {loading ? (
                    <div style={{ gridColumn: '1 / -1', padding: '3rem', textAlign: 'center' }}>Loading organizations...</div>
                ) : filteredOrgs.length === 0 ? (
                    <div style={{ gridColumn: '1 / -1', padding: '3rem', textAlign: 'center', color: 'var(--text-muted)' }}>No organizations found.</div>
                ) : (
                    filteredOrgs.map((org) => (
                        <div key={org.id} className="card" style={{ display: 'flex', flexDirection: 'column' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                                <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                                    <div style={{
                                        width: '48px', height: '48px',
                                        background: 'var(--bg-secondary)', borderRadius: '12px',
                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        fontSize: '1.5rem', fontWeight: 'bold', color: 'var(--primary)'
                                    }}>
                                        {org.name.charAt(0)}
                                    </div>
                                    <div>
                                        <h3 style={{ fontSize: '1.1rem', fontWeight: 600, margin: 0 }}>{org.name}</h3>
                                        <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{org.type} • Est. {org.yearEstablished || 'N/A'}</span>
                                    </div>
                                </div>
                                <span className={`badge ${org.status === 'APPROVED' ? 'badge-success' : org.status === 'REJECTED' ? 'badge-error' : 'badge-warning'}`}>
                                    {org.status || 'PENDING'}
                                </span>
                            </div>

                            <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '1rem', flex: 1 }}>
                                📍 {org.address || 'No address provided'}
                            </p>

                            <div style={{ display: 'flex', gap: '0.5rem', marginTop: 'auto', borderTop: '1px solid var(--border-color)', paddingTop: '1rem' }}>
                                <Link href={`/org/${org.id}`} target="_blank" className="btn btn-outline" style={{ flex: 1, justifyContent: 'center' }}>
                                    Profile
                                </Link>

                                {org.status === 'PENDING' && (
                                    <>
                                        <button onClick={() => handleStatusUpdate(org.id, 'APPROVED')} className="btn btn-success" style={{ flex: 1, justifyContent: 'center' }}>
                                            Approve
                                        </button>
                                        <button onClick={() => handleStatusUpdate(org.id, 'REJECTED')} className="btn btn-outline" style={{ flex: 1, justifyContent: 'center', color: 'var(--danger)', borderColor: 'var(--danger)' }}>
                                            Reject
                                        </button>
                                    </>
                                )}
                                {org.status === 'APPROVED' && (
                                    <button onClick={() => handleStatusUpdate(org.id, 'REJECTED')} className="btn btn-outline" style={{ flex: 1, justifyContent: 'center', color: 'var(--danger)', borderColor: 'var(--danger)' }}>
                                        Suspend
                                    </button>
                                )}
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}

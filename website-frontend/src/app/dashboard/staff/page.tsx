'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAllStaff, getPendingStaff, updateStaffStatus, removeStaff } from '@/lib/api';

interface StaffMember {
    id: string;
    role: string;
    status: string;
    createdAt: string;
    approvedAt?: string;
    user: {
        id: string;
        name: string;
        email: string;
        phone?: string;
        role: string;
        doctorProfile?: any;
    };
    approver?: {
        id: string;
        name: string;
        email: string;
    };
}

export default function StaffManagementPage() {
    const router = useRouter();
    const [staff, setStaff] = useState<StaffMember[]>([]);
    const [pendingCount, setPendingCount] = useState(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [processing, setProcessing] = useState<string | null>(null);

    useEffect(() => {
        loadStaff();
    }, [statusFilter]);

    async function loadStaff() {
        try {
            const token = localStorage.getItem('token');
            const userStr = localStorage.getItem('user');

            if (!token || !userStr) {
                router.push('/');
                return;
            }

            const user = JSON.parse(userStr);
            const orgId = user.memberships?.[0]?.organizationId;

            if (!orgId) {
                setError('No organization found');
                setLoading(false);
                return;
            }

            // Load all staff
            const staffData = await getAllStaff(token, orgId, statusFilter || undefined);
            setStaff(staffData);

            // Load pending count
            const pendingData = await getPendingStaff(token, orgId);
            setPendingCount(pendingData.length);

            setLoading(false);
        } catch (err: any) {
            console.error('Error loading staff:', err);
            setError(err.message || 'Failed to load staff');
            setLoading(false);
        }
    }

    async function handleApprove(membershipId: string) {
        try {
            setProcessing(membershipId);
            const token = localStorage.getItem('token');
            const userStr = localStorage.getItem('user');
            const user = JSON.parse(userStr!);
            const orgId = user.memberships?.[0]?.organizationId;

            await updateStaffStatus(token!, orgId, membershipId, 'APPROVED');

            // Reload staff
            await loadStaff();
            setProcessing(null);
        } catch (err: any) {
            console.error('Error approving staff:', err);
            alert(err.message || 'Failed to approve staff member');
            setProcessing(null);
        }
    }

    async function handleReject(membershipId: string) {
        if (!confirm('Are you sure you want to reject this staff member?')) return;

        try {
            setProcessing(membershipId);
            const token = localStorage.getItem('token');
            const userStr = localStorage.getItem('user');
            const user = JSON.parse(userStr!);
            const orgId = user.memberships?.[0]?.organizationId;

            await updateStaffStatus(token!, orgId, membershipId, 'REJECTED');

            // Reload staff
            await loadStaff();
            setProcessing(null);
        } catch (err: any) {
            console.error('Error rejecting staff:', err);
            alert(err.message || 'Failed to reject staff member');
            setProcessing(null);
        }
    }

    async function handleRemove(membershipId: string, memberName: string) {
        if (!confirm(`Are you sure you want to remove ${memberName} from the organization?`)) return;

        try {
            setProcessing(membershipId);
            const token = localStorage.getItem('token');
            const userStr = localStorage.getItem('user');
            const user = JSON.parse(userStr!);
            const orgId = user.memberships?.[0]?.organizationId;

            await removeStaff(token!, orgId, membershipId);

            // Reload staff
            await loadStaff();
            setProcessing(null);
        } catch (err: any) {
            console.error('Error removing staff:', err);
            alert(err.message || 'Failed to remove staff member');
            setProcessing(null);
        }
    }

    if (loading) {
        return (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
                <div>Loading staff...</div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="card">
                <p style={{ color: 'var(--error)', textAlign: 'center' }}>{error}</p>
            </div>
        );
    }

    return (
        <div>
            <div style={{ marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.75rem', fontWeight: 'bold', marginBottom: '0.5rem' }}>Staff Management</h1>
                <p style={{ color: 'var(--text-muted)' }}>Manage your organization's staff members and approvals</p>
            </div>

            {/* Stats */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
                <div className="card">
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Total Staff</p>
                    <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--primary)' }}>{staff.length}</h3>
                </div>
                <div className="card">
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Pending Approval</p>
                    <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--warning)' }}>{pendingCount}</h3>
                </div>
                <div className="card">
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Approved</p>
                    <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--success)' }}>
                        {staff.filter(s => s.status === 'APPROVED').length}
                    </h3>
                </div>
            </div>

            {/* Filters */}
            <div className="card" style={{ marginBottom: '1rem' }}>
                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                    <button
                        className={`btn ${statusFilter === '' ? 'btn-primary' : 'btn-outline'}`}
                        onClick={() => setStatusFilter('')}
                    >
                        All
                    </button>
                    <button
                        className={`btn ${statusFilter === 'PENDING' ? 'btn-primary' : 'btn-outline'}`}
                        onClick={() => setStatusFilter('PENDING')}
                    >
                        Pending ({pendingCount})
                    </button>
                    <button
                        className={`btn ${statusFilter === 'APPROVED' ? 'btn-primary' : 'btn-outline'}`}
                        onClick={() => setStatusFilter('APPROVED')}
                    >
                        Approved
                    </button>
                    <button
                        className={`btn ${statusFilter === 'REJECTED' ? 'btn-primary' : 'btn-outline'}`}
                        onClick={() => setStatusFilter('REJECTED')}
                    >
                        Rejected
                    </button>
                </div>
            </div>

            {/* Staff Table */}
            <div className="card">
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '1.5rem' }}>
                    {statusFilter ? `${statusFilter} Staff` : 'All Staff Members'}
                </h3>

                {staff.length === 0 ? (
                    <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                        No staff members found
                    </p>
                ) : (
                    <div style={{ overflowX: 'auto' }}>
                        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                            <thead>
                                <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left' }}>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Name</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Role</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Status</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Email</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Phone</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Joined</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {staff.map((member) => (
                                    <tr key={member.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <div style={{ fontWeight: 500 }}>{member.user.name}</div>
                                            {member.approver && (
                                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                                                    Approved by: {member.approver.name}
                                                </div>
                                            )}
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <span className={`badge ${member.role === 'ORG_ADMIN' ? 'badge-error' :
                                                    member.role === 'DOCTOR' ? 'badge-primary' :
                                                        'badge-warning'
                                                }`}>
                                                {member.role.replace('ORG_ADMIN', 'ADMIN')}
                                            </span>
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <span className={`badge ${member.status === 'APPROVED' ? 'badge-success' :
                                                    member.status === 'PENDING' ? 'badge-warning' :
                                                        'badge-default'
                                                }`}>
                                                {member.status}
                                            </span>
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem', fontSize: '0.875rem' }}>{member.user.email}</td>
                                        <td style={{ padding: '1rem 0.75rem', fontSize: '0.875rem' }}>{member.user.phone || '-'}</td>
                                        <td style={{ padding: '1rem 0.75rem', fontSize: '0.875rem' }}>
                                            {new Date(member.createdAt).toLocaleDateString()}
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <div style={{ display: 'flex', gap: '0.5rem' }}>
                                                {member.status === 'PENDING' && (
                                                    <>
                                                        <button
                                                            className="btn btn-sm btn-success"
                                                            onClick={() => handleApprove(member.id)}
                                                            disabled={processing === member.id}
                                                        >
                                                            {processing === member.id ? '...' : '✓ Approve'}
                                                        </button>
                                                        <button
                                                            className="btn btn-sm btn-outline"
                                                            onClick={() => handleReject(member.id)}
                                                            disabled={processing === member.id}
                                                        >
                                                            ✗ Reject
                                                        </button>
                                                    </>
                                                )}
                                                {member.status === 'APPROVED' && member.role !== 'ORG_ADMIN' && (
                                                    <button
                                                        className="btn btn-sm btn-outline"
                                                        onClick={() => handleRemove(member.id, member.user.name)}
                                                        disabled={processing === member.id}
                                                        style={{ color: 'var(--error)' }}
                                                    >
                                                        {processing === member.id ? '...' : 'Remove'}
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
}

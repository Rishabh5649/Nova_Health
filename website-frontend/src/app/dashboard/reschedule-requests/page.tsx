'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getRescheduleRequests, approveRescheduleRequest, rejectRescheduleRequest } from '@/lib/api';
import { format, parseISO } from 'date-fns';

export default function RescheduleRequestsPage() {
    const router = useRouter();
    const [requests, setRequests] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState<'all' | 'PENDING' | 'APPROVED' | 'REJECTED'>('PENDING');
    const [processing, setProcessing] = useState<string | null>(null);

    useEffect(() => {
        loadRequests();
    }, [filter]);

    const loadRequests = async () => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');
        const user = JSON.parse(userStr || '{}');
        const orgId = user.memberships?.[0]?.organizationId;

        if (!token) {
            router.push('/');
            return;
        }

        setLoading(true);
        try {
            const status = filter === 'all' ? undefined : filter;
            const data = await getRescheduleRequests(token, orgId, status);
            setRequests(data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (requestId: string) => {
        const token = localStorage.getItem('token');
        if (!token) return;

        setProcessing(requestId);
        try {
            await approveRescheduleRequest(token, requestId);
            alert('Reschedule request approved');
            loadRequests();
        } catch (err) {
            console.error(err);
            alert('Failed to approve request');
        } finally {
            setProcessing(null);
        }
    };

    const handleReject = async (requestId: string) => {
        const token = localStorage.getItem('token');
        if (!token) return;

        if (!confirm('Are you sure you want to reject this request?')) return;

        setProcessing(requestId);
        try {
            await rejectRescheduleRequest(token, requestId);
            alert('Reschedule request rejected');
            loadRequests();
        } catch (err) {
            console.error(err);
            alert('Failed to reject request');
        } finally {
            setProcessing(null);
        }
    };

    if (loading) return <div>Loading...</div>;

    return (
        <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.5rem', fontWeight: 600 }}>Reschedule Requests</h1>
                <button onClick={() => router.back()} className="btn btn-outline">← Back</button>
            </div>

            {/* Filter Tabs */}
            <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', borderBottom: '2px solid var(--border-color)' }}>
                {['PENDING', 'APPROVED', 'REJECTED', 'all'].map((status) => (
                    <button
                        key={status}
                        onClick={() => setFilter(status as any)}
                        style={{
                            padding: '0.75rem 1rem',
                            border: 'none',
                            background: 'none',
                            borderBottom: filter === status ? '2px solid var(--primary)' : 'none',
                            color: filter === status ? 'var(--primary)' : 'var(--text-muted)',
                            fontWeight: filter === status ? 600 : 400,
                            cursor: 'pointer',
                            marginBottom: '-2px',
                            textTransform: 'capitalize',
                        }}
                    >
                        {status}
                    </button>
                ))}
            </div>

            {/* Requests List */}
            {requests.length === 0 ? (
                <div className="card" style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                    No {filter !== 'all' ? filter.toLowerCase() : ''} reschedule requests found
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {requests.map((request) => (
                        <div key={request.id} className="card">
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: '2rem', alignItems: 'start' }}>
                                <div>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
                                        <h3 style={{ fontSize: '1.125rem', fontWeight: 600 }}>
                                            {request.appointment.patient.name}
                                        </h3>
                                        <span
                                            style={{
                                                padding: '0.25rem 0.75rem',
                                                borderRadius: 'var(--radius)',
                                                fontSize: '0.75rem',
                                                fontWeight: 600,
                                                background:
                                                    request.status === 'PENDING'
                                                        ? '#FEF3C7'
                                                        : request.status === 'APPROVED'
                                                            ? '#D1FAE5'
                                                            : '#FEE2E2',
                                                color:
                                                    request.status === 'PENDING'
                                                        ? '#92400E'
                                                        : request.status === 'APPROVED'
                                                            ? '#065F46'
                                                            : '#991B1B',
                                            }}
                                        >
                                            {request.status}
                                        </span>
                                    </div>

                                    <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
                                        <div><strong>Doctor:</strong> {request.appointment.doctor.name}</div>
                                        <div><strong>Current Time:</strong> {format(parseISO(request.appointment.scheduledAt), 'PPp')}</div>
                                        <div><strong>Requested Time:</strong> {format(parseISO(request.requestedDateTime), 'PPp')}</div>
                                        <div><strong>Requested By:</strong> {request.requestedBy.name} ({request.requestedBy.role})</div>
                                        {request.reason && <div><strong>Reason:</strong> {request.reason}</div>}
                                        <div><strong>Requested On:</strong> {format(parseISO(request.createdAt), 'PPp')}</div>
                                    </div>
                                </div>

                                {request.status === 'PENDING' && (
                                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                                        <button
                                            className="btn btn-primary"
                                            onClick={() => handleApprove(request.id)}
                                            disabled={processing === request.id}
                                            style={{ minWidth: '100px' }}
                                        >
                                            {processing === request.id ? 'Processing...' : 'Approve'}
                                        </button>
                                        <button
                                            className="btn btn-outline"
                                            onClick={() => handleReject(request.id)}
                                            disabled={processing === request.id}
                                            style={{ minWidth: '100px' }}
                                        >
                                            Reject
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

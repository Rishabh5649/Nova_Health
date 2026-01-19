'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAppointments, updateAppointmentStatus, directReschedule, cancelAppointmentAsAdmin, getRescheduleRequests, approveRescheduleRequest, rejectRescheduleRequest } from '@/lib/api';

export default function AppointmentsPage() {
    const router = useRouter();
    const [appointments, setAppointments] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState<'all' | 'pending' | 'confirmed' | 'completed' | 'reschedule_requests'>('all');
    const [rescheduleRequests, setRescheduleRequests] = useState<any[]>([]);
    const [processing, setProcessing] = useState<string | null>(null);
    const [cancelModalOpen, setCancelModalOpen] = useState(false);
    const [cancelReason, setCancelReason] = useState('');
    const [selectedAppointmentId, setSelectedAppointmentId] = useState<string | null>(null);

    useEffect(() => {
        if (filter === 'reschedule_requests') {
            loadRescheduleRequests();
        } else {
            loadAppointments();
        }
    }, [filter]);

    const loadAppointments = async () => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');

        if (!token || !userStr) {
            router.push('/');
            return;
        }

        const user = JSON.parse(userStr);
        const orgId = user.memberships?.[0]?.organizationId;

        setLoading(true);
        try {
            const statusFilter = filter === 'all' ? undefined : filter.toUpperCase();
            const data = await getAppointments(token, orgId, statusFilter);
            setAppointments(data);
        } catch (err) {
            console.error('Failed to load appointments:', err);
        } finally {
            setLoading(false);
        }
    };

    const loadRescheduleRequests = async () => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');
        if (!token || !userStr) return;
        const user = JSON.parse(userStr);
        const orgId = user.memberships?.[0]?.organizationId;

        setLoading(true);
        try {
            const data = await getRescheduleRequests(token, orgId, 'PENDING');
            setRescheduleRequests(data || []);
        } catch (err) {
            console.error('Failed to load reschedule requests:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleRescheduleAction = async (requestId: string, action: 'approve' | 'reject') => {
        const token = localStorage.getItem('token');
        if (!token) return;

        setProcessing(requestId);
        try {
            if (action === 'approve') {
                await approveRescheduleRequest(token, requestId);
            } else {
                await rejectRescheduleRequest(token, requestId);
            }
            await loadRescheduleRequests();
        } catch (err: any) {
            alert(`Error: ${err.message}`);
        } finally {
            setProcessing(null);
        }
    };

    const handleAction = async (appointmentId: string, action: 'confirm' | 'reject' | 'complete') => {
        const token = localStorage.getItem('token');
        if (!token) return;

        setProcessing(appointmentId);
        try {
            await updateAppointmentStatus(token, appointmentId, action);
            await loadAppointments(); // Reload
        } catch (err: any) {
            alert('Error: ' + err.message);
        } finally {
            setProcessing(null);
        }
    };

    const handleReschedule = async (appointmentId: string, newDateTime: string) => {
        const token = localStorage.getItem('token');
        if (!token) return;

        try {
            await directReschedule(token, appointmentId, new Date(newDateTime).toISOString());
            alert('Appointment rescheduled successfully');
            await loadAppointments(); // Reload
        } catch (err: any) {
            alert('Error rescheduling: ' + err.message);
        }
    };

    const handleCancelClick = (appointmentId: string) => {
        setSelectedAppointmentId(appointmentId);
        setCancelReason('');
        setCancelModalOpen(true);
    };

    const submitCancel = async () => {
        if (!selectedAppointmentId) return;
        const token = localStorage.getItem('token');
        if (!token) return;

        if (cancelReason.trim().length < 10) {
            alert('Cancellation reason must be at least 10 characters.');
            return;
        }

        try {
            await cancelAppointmentAsAdmin(token, selectedAppointmentId, cancelReason);
            alert('Appointment cancelled successfully');
            setCancelModalOpen(false);
            loadAppointments();
        } catch (err: any) {
            alert('Error cancelling: ' + err.message);
        }
    };

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h2 style={{ fontSize: '1.5rem', fontWeight: 600 }}>Appointments</h2>
                <button
                    className="btn btn-primary"
                    onClick={() => router.push('/dashboard/appointments/new')}
                >
                    + New Appointment
                </button>
            </div>

            <div className="card">
                <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '1rem' }}>
                    <button
                        onClick={() => setFilter('all')}
                        style={{
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            background: filter === 'all' ? 'var(--primary)' : 'transparent',
                            color: filter === 'all' ? 'white' : 'var(--text-muted)',
                            border: 'none',
                            cursor: 'pointer'
                        }}
                    >
                        All
                    </button>
                    <button
                        onClick={() => setFilter('pending')}
                        style={{
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            background: filter === 'pending' ? 'var(--primary)' : 'transparent',
                            color: filter === 'pending' ? 'white' : 'var(--text-muted)',
                            border: 'none',
                            cursor: 'pointer'
                        }}
                    >
                        Pending
                    </button>
                    <button
                        onClick={() => setFilter('confirmed')}
                        style={{
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            background: filter === 'confirmed' ? 'var(--primary)' : 'transparent',
                            color: filter === 'confirmed' ? 'white' : 'var(--text-muted)',
                            border: 'none',
                            cursor: 'pointer'
                        }}
                    >
                        Confirmed
                    </button>
                    <button
                        onClick={() => setFilter('completed')}
                        style={{
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            background: filter === 'completed' ? 'var(--primary)' : 'transparent',
                            color: filter === 'completed' ? 'white' : 'var(--text-muted)',
                            border: 'none',
                            cursor: 'pointer'
                        }}
                    >
                        Completed
                    </button>
                    <button
                        onClick={() => setFilter('reschedule_requests')}
                        style={{
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            background: filter === 'reschedule_requests' ? 'var(--primary)' : 'transparent',
                            color: filter === 'reschedule_requests' ? 'white' : 'var(--text-muted)',
                            border: 'none',
                            cursor: 'pointer'
                        }}
                    >
                        Reschedule Requests
                    </button>
                </div>

                {loading ? (
                    <div style={{ textAlign: 'center', padding: '3rem' }}>Loading...</div>
                ) : filter === 'reschedule_requests' ? (
                    rescheduleRequests.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
                            No pending reschedule requests
                        </div>
                    ) : (
                        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                            <thead>
                                <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left' }}>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Patient</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Current Time</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Requested Time</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Reason</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {rescheduleRequests.map((req) => (
                                    <tr key={req.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <div style={{ fontWeight: 500 }}>{req.appointment?.patient?.name || 'Unknown'}</div>
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                            {req.appointment?.scheduledAt ? new Date(req.appointment.scheduledAt).toLocaleString() : '-'}
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--primary)' }}>
                                            {new Date(req.requestedDateTime).toLocaleString()}
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>{req.reason || '-'}</td>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            <div style={{ display: 'flex', gap: '0.5rem' }}>
                                                <button
                                                    onClick={() => handleRescheduleAction(req.id, 'approve')}
                                                    disabled={processing === req.id}
                                                    style={{
                                                        padding: '0.25rem 0.75rem',
                                                        fontSize: '0.75rem',
                                                        borderRadius: 'var(--radius)',
                                                        background: 'var(--success)',
                                                        color: 'white',
                                                        border: 'none',
                                                        cursor: processing === req.id ? 'not-allowed' : 'pointer',
                                                        opacity: processing === req.id ? 0.6 : 1,
                                                    }}
                                                >
                                                    Approve
                                                </button>
                                                <button
                                                    onClick={() => handleRescheduleAction(req.id, 'reject')}
                                                    disabled={processing === req.id}
                                                    style={{
                                                        padding: '0.25rem 0.75rem',
                                                        fontSize: '0.75rem',
                                                        borderRadius: 'var(--radius)',
                                                        background: 'var(--danger)',
                                                        color: 'white',
                                                        border: 'none',
                                                        cursor: processing === req.id ? 'not-allowed' : 'pointer',
                                                        opacity: processing === req.id ? 0.6 : 1,
                                                    }}
                                                >
                                                    Reject
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )
                ) : appointments.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
                        No appointments found
                    </div>
                ) : (
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                            <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left' }}>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Patient</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Doctor</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Scheduled</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Reason</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Status</th>
                                <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {appointments.map((appt) => (
                                <tr key={appt.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                                    <td style={{ padding: '1rem 0.75rem' }}>
                                        <div style={{ fontWeight: 500 }}>{appt.patient?.name || 'Unknown'}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{appt.patient?.email}</div>
                                    </td>
                                    <td style={{ padding: '1rem 0.75rem' }}>{appt.doctor?.name || 'Unknown'}</td>
                                    <td style={{ padding: '1rem 0.75rem', fontSize: '0.875rem' }}>
                                        {new Date(appt.scheduledAt).toLocaleString()}
                                    </td>
                                    <td style={{ padding: '1rem 0.75rem' }}>{appt.reason || '-'}</td>
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
                                        <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
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
                                            {appt.status === 'PENDING' && (
                                                <>
                                                    <button
                                                        onClick={() => handleAction(appt.id, 'confirm')}
                                                        disabled={processing === appt.id}
                                                        style={{
                                                            padding: '0.25rem 0.75rem',
                                                            fontSize: '0.75rem',
                                                            borderRadius: 'var(--radius)',
                                                            background: 'var(--success)',
                                                            color: 'white',
                                                            border: 'none',
                                                            cursor: processing === appt.id ? 'not-allowed' : 'pointer',
                                                            opacity: processing === appt.id ? 0.6 : 1,
                                                        }}
                                                    >
                                                        Accept
                                                    </button>
                                                    <button
                                                        onClick={() => handleAction(appt.id, 'reject')}
                                                        disabled={processing === appt.id}
                                                        style={{
                                                            padding: '0.25rem 0.75rem',
                                                            fontSize: '0.75rem',
                                                            borderRadius: 'var(--radius)',
                                                            background: 'var(--danger)',
                                                            color: 'white',
                                                            border: 'none',
                                                            cursor: processing === appt.id ? 'not-allowed' : 'pointer',
                                                            opacity: processing === appt.id ? 0.6 : 1,
                                                        }}
                                                    >
                                                        Reject
                                                    </button>
                                                </>
                                            )}
                                            {appt.status === 'CONFIRMED' && (
                                                <button
                                                    onClick={() => handleAction(appt.id, 'complete')}
                                                    disabled={processing === appt.id}
                                                    style={{
                                                        padding: '0.25rem 0.75rem',
                                                        fontSize: '0.75rem',
                                                        borderRadius: 'var(--radius)',
                                                        background: 'var(--primary)',
                                                        color: 'white',
                                                        border: 'none',
                                                        cursor: processing === appt.id ? 'not-allowed' : 'pointer',
                                                        opacity: processing === appt.id ? 0.6 : 1,
                                                    }}
                                                >
                                                    Complete
                                                </button>
                                            )}
                                            {(appt.status === 'CONFIRMED' || appt.status === 'PENDING') && (
                                                <>
                                                    <button
                                                        onClick={() => router.push(`/dashboard/calendar?appointmentId=${appt.id}&action=reschedule`)}
                                                        style={{
                                                            padding: '0.25rem 0.75rem',
                                                            fontSize: '0.75rem',
                                                            borderRadius: 'var(--radius)',
                                                            background: 'transparent',
                                                            color: '#F59E0B',
                                                            border: '1px solid #F59E0B',
                                                            cursor: 'pointer',
                                                        }}
                                                    >
                                                        Reschedule
                                                    </button>
                                                    <button
                                                        onClick={() => handleCancelClick(appt.id)}
                                                        style={{
                                                            padding: '0.25rem 0.75rem',
                                                            fontSize: '0.75rem',
                                                            borderRadius: 'var(--radius)',
                                                            background: 'transparent',
                                                            color: '#EF4444',
                                                            border: '1px solid #EF4444',
                                                            cursor: 'pointer',
                                                        }}
                                                    >
                                                        Cancel
                                                    </button>
                                                </>
                                            )}
                                            {appt.status === 'COMPLETED' && (
                                                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>✓ Done</span>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

            {cancelModalOpen && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    backgroundColor: 'rgba(0,0,0,0.5)',
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    zIndex: 1000
                }}>
                    <div style={{
                        background: 'var(--card-bg)',
                        padding: '2rem',
                        borderRadius: 'var(--radius)',
                        width: '400px',
                        maxWidth: '90%'
                    }}>
                        <h3 style={{ marginTop: 0 }}>Cancel Appointment</h3>
                        <p style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                            Please provide a reason for cancellation. This will be visible to the patient.
                        </p>
                        <textarea
                            value={cancelReason}
                            onChange={(e) => setCancelReason(e.target.value)}
                            placeholder="Reason for cancellation (min 10 chars)..."
                            style={{
                                width: '100%',
                                minHeight: '100px',
                                padding: '0.5rem',
                                borderRadius: 'var(--radius)',
                                border: '1px solid var(--border-color)',
                                background: 'var(--bg-color)',
                                color: 'var(--text-color)',
                                marginBottom: '1rem'
                            }}
                        />
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
                            <button
                                onClick={() => setCancelModalOpen(false)}
                                style={{
                                    padding: '0.5rem 1rem',
                                    borderRadius: 'var(--radius)',
                                    border: '1px solid var(--border-color)',
                                    background: 'transparent',
                                    color: 'var(--text-color)',
                                    cursor: 'pointer'
                                }}
                            >
                                Close
                            </button>
                            <button
                                onClick={submitCancel}
                                style={{
                                    padding: '0.5rem 1rem',
                                    borderRadius: 'var(--radius)',
                                    border: 'none',
                                    background: '#EF4444',
                                    color: 'white',
                                    cursor: 'pointer'
                                }}
                            >
                                Confirm Cancel
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { getAppointments } from '@/lib/api';

export default function PatientDetailsPage() {
    const router = useRouter();
    const params = useParams();
    const patientId = params.id as string;
    const [appointments, setAppointments] = useState<any[]>([]);
    const [patient, setPatient] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadData();
    }, [patientId]);

    const loadData = async () => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');

        if (!token || !userStr) {
            router.push('/');
            return;
        }

        const user = JSON.parse(userStr);
        const orgId = user.memberships?.[0]?.organizationId;

        if (orgId) {
            setLoading(true);
            try {
                // Fetch appointments for this patient in this org
                const appts = await getAppointments(token, orgId, undefined, patientId);
                setAppointments(appts);

                if (appts.length > 0) {
                    // Extract patient info from the first appointment
                    setPatient(appts[0].patient);
                }
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        }
    };

    if (loading) return <div>Loading...</div>;

    if (!patient && appointments.length === 0) {
        return (
            <div>
                <button onClick={() => router.back()} className="btn btn-outline" style={{ marginBottom: '1rem' }}>← Back</button>
                <div className="card" style={{ padding: '2rem', textAlign: 'center' }}>
                    Patient details not found or no appointments in this organization.
                </div>
            </div>
        );
    }

    return (
        <div>
            <div style={{ marginBottom: '2rem' }}>
                <button onClick={() => router.back()} className="btn btn-outline" style={{ marginBottom: '1rem' }}>← Back</button>
                <h1 style={{ fontSize: '1.5rem', fontWeight: 600 }}>{patient?.name || 'Unknown Patient'}</h1>
                <p style={{ color: 'var(--text-muted)' }}>{patient?.email}</p>
            </div>

            <div className="card">
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '1rem' }}>Appointment History</h3>
                {appointments.length === 0 ? (
                    <p>No appointments found.</p>
                ) : (
                    <div className="table-container">
                        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                            <thead>
                                <tr style={{ borderBottom: '1px solid var(--border-color)', textAlign: 'left' }}>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Date</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Doctor</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Reason</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Status</th>
                                    <th style={{ padding: '0.75rem', fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: 500 }}>Prescription</th>
                                </tr>
                            </thead>
                            <tbody>
                                {appointments.map((appt) => (
                                    <tr key={appt.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                                        <td style={{ padding: '1rem 0.75rem' }}>
                                            {new Date(appt.scheduledAt).toLocaleDateString()} at {new Date(appt.scheduledAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                        </td>
                                        <td style={{ padding: '1rem 0.75rem' }}>{appt.doctor?.name || 'Unassigned'}</td>
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
                                            {appt.prescription ? (
                                                <button className="btn btn-sm btn-outline">View</button>
                                            ) : '-'}
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

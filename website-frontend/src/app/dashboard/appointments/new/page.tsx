'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getDoctors, getOrganizationPatients, createAppointment, checkEligibility } from '@/lib/api';

export default function NewAppointmentPage() {
    const router = useRouter();
    const [patients, setPatients] = useState<any[]>([]);
    const [doctors, setDoctors] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    const [selectedPatient, setSelectedPatient] = useState('');
    const [selectedDoctor, setSelectedDoctor] = useState('');
    const [scheduledAt, setScheduledAt] = useState('');
    const [reason, setReason] = useState('');

    const [feeDetails, setFeeDetails] = useState<any>(null);
    const [checkingFee, setCheckingFee] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        if (selectedPatient && selectedDoctor) {
            checkFee();
        } else {
            setFeeDetails(null);
        }
    }, [selectedPatient, selectedDoctor]);

    const loadData = async () => {
        const token = localStorage.getItem('token');
        if (!token) {
            router.push('/');
            return;
        }

        const userStr = localStorage.getItem('user');
        const user = JSON.parse(userStr || '{}');
        const orgId = user.memberships?.[0]?.organizationId;

        try {
            const [pats, docs] = await Promise.all([
                getOrganizationPatients(token, orgId),
                getDoctors(token)
            ]);
            setPatients(pats);
            setDoctors(docs);
        } catch (err) {
            console.error('Error loading data:', err);
        } finally {
            setLoading(false);
        }
    };

    const checkFee = async () => {
        const token = localStorage.getItem('token');
        if (!token) return;

        setCheckingFee(true);
        try {
            const details = await checkEligibility(token, selectedPatient, selectedDoctor);
            setFeeDetails(details);
        } catch (err) {
            console.error('Error checking fee:', err);
        } finally {
            setCheckingFee(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedPatient || !selectedDoctor || !scheduledAt) return;

        const token = localStorage.getItem('token');
        if (!token) return;

        setSubmitting(true);
        try {
            await createAppointment(token, {
                patientId: selectedPatient, // Note: API expects doctorUserId, patient is inferred from token usually. 
                // Wait, the current API `request` endpoint infers patient from token.
                // Admin needs a different endpoint or `request` needs to accept patientId if admin.
                // Let's check the API again.
                doctorUserId: selectedDoctor,
                scheduledAt: new Date(scheduledAt).toISOString(),
                reason,
                // We might need to handle "Admin booking for patient" scenario in backend.
                // The current `request` endpoint uses `@CurrentUser() user` as patient.
                // I need to update the backend to allow Admin to specify patientId.
            });
            router.push('/dashboard/appointments');
        } catch (err: any) {
            alert('Error creating appointment: ' + err.message);
        } finally {
            setSubmitting(false);
        }
    };

    if (loading) return <div style={{ padding: '2rem' }}>Loading...</div>;

    return (
        <div style={{ maxWidth: '800px', margin: '0 auto' }}>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: '2rem' }}>New Appointment</h2>

            <div className="card">
                <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>

                    {/* Patient Selection */}
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Patient</label>
                        <select
                            value={selectedPatient}
                            onChange={(e) => setSelectedPatient(e.target.value)}
                            style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid var(--border-color)', background: 'var(--background)' }}
                            required
                        >
                            <option value="">Select Patient</option>
                            {patients.map(p => (
                                <option key={p.id} value={p.id}>{p.name} ({p.email})</option>
                            ))}
                        </select>
                    </div>

                    {/* Doctor Selection */}
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Doctor</label>
                        <select
                            value={selectedDoctor}
                            onChange={(e) => setSelectedDoctor(e.target.value)}
                            style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid var(--border-color)', background: 'var(--background)' }}
                            required
                        >
                            <option value="">Select Doctor</option>
                            {doctors.map(d => (
                                <option key={d.userId} value={d.userId}>{d.name} - {d.specialties.join(', ')}</option>
                            ))}
                        </select>
                    </div>

                    {/* Fee Preview */}
                    {checkingFee ? (
                        <div style={{ padding: '1rem', background: 'var(--background-muted)', borderRadius: 'var(--radius)' }}>
                            Checking fee...
                        </div>
                    ) : feeDetails && (
                        <div style={{
                            padding: '1.5rem',
                            background: feeDetails.isFollowUp ? 'rgba(22, 163, 74, 0.1)' : 'rgba(37, 99, 235, 0.1)',
                            borderRadius: 'var(--radius)',
                            border: `1px solid ${feeDetails.isFollowUp ? '#16A34A' : '#2563EB'}`
                        }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                                <span style={{ fontWeight: 600, color: feeDetails.isFollowUp ? '#16A34A' : '#2563EB' }}>
                                    {feeDetails.isFollowUp ? 'Follow-up Appointment' : 'Standard Consultation'}
                                </span>
                                <span style={{ fontSize: '1.25rem', fontWeight: 700, color: feeDetails.isFollowUp ? '#16A34A' : '#2563EB' }}>
                                    ₹{feeDetails.chargedFee}
                                </span>
                            </div>
                            {feeDetails.isFollowUp && (
                                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                    Original Fee: <span style={{ textDecoration: 'line-through' }}>₹{feeDetails.originalFee}</span>
                                </div>
                            )}
                        </div>
                    )}

                    {/* Date & Time */}
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Date & Time</label>
                        <input
                            type="datetime-local"
                            value={scheduledAt}
                            onChange={(e) => setScheduledAt(e.target.value)}
                            style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid var(--border-color)', background: 'var(--background)', color: 'white' }}
                            required
                        />
                    </div>

                    {/* Reason */}
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Reason</label>
                        <textarea
                            value={reason}
                            onChange={(e) => setReason(e.target.value)}
                            rows={3}
                            style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid var(--border-color)', background: 'var(--background)', color: 'white' }}
                        />
                    </div>

                    <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                        <button
                            type="button"
                            onClick={() => router.back()}
                            style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid var(--border-color)', background: 'transparent', color: 'white', cursor: 'pointer' }}
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={submitting}
                            className="btn btn-primary"
                            style={{ flex: 2, opacity: submitting ? 0.7 : 1 }}
                        >
                            {submitting ? 'Booking...' : 'Confirm Booking'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

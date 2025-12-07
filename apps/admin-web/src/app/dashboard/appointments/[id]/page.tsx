'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { getAppointment, updateAppointmentStatus } from '@/lib/api';

export default function AppointmentDetailPage() {
    const router = useRouter();
    const params = useParams();
    const id = params.id as string;

    const [appointment, setAppointment] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadData();
    }, [id]);

    const loadData = async () => {
        const token = localStorage.getItem('token');
        if (!token) {
            router.push('/');
            return;
        }

        try {
            const data = await getAppointment(token, id);
            setAppointment(data);
        } catch (err) {
            console.error('Error loading data:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleAccept = () => {
        // Redirect to calendar to schedule
        router.push(`/dashboard/calendar?appointmentId=${id}&action=schedule`);
    };

    const handleReject = async () => {
        if (!confirm('Are you sure you want to reject this appointment?')) return;
        const token = localStorage.getItem('token');
        try {
            await updateAppointmentStatus(token!, id, 'reject');
            loadData();
        } catch (err) {
            console.error(err);
            alert('Failed to reject appointment');
        }
    };

    if (loading) return <div className="p-8">Loading...</div>;
    if (!appointment) return <div className="p-8">Appointment not found</div>;

    return (
        <div className="min-h-screen p-8" style={{ backgroundColor: '#111827' }}>
            <div className="max-w-6xl mx-auto">
                {/* Header */}
                <div className="mb-8">
                    <Link href="/dashboard/appointments" style={{ color: '#60A5FA' }} className="text-sm font-medium hover:underline">
                        ← Back to Appointments
                    </Link>
                </div>

                <div className="flex justify-between items-center mb-8">
                    <h1 className="text-3xl font-bold text-white">Appointment Details</h1>

                    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                        {appointment.status === 'PENDING' && (
                            <>
                                <button
                                    onClick={handleAccept}
                                    style={{ backgroundColor: '#16A34A', color: 'white', padding: '0.5rem 1rem', borderRadius: '0.5rem', fontWeight: 600 }}
                                >
                                    Accept & Schedule
                                </button>
                                <button
                                    onClick={handleReject}
                                    style={{ backgroundColor: '#DC2626', color: 'white', padding: '0.5rem 1rem', borderRadius: '0.5rem', fontWeight: 600 }}
                                >
                                    Reject
                                </button>
                            </>
                        )}
                        {appointment.status === 'COMPLETED' && (
                            <span
                                style={{ backgroundColor: '#16A34A', color: 'white', padding: '0.5rem 1rem', borderRadius: '0.5rem', fontWeight: 600 }}
                            >
                                COMPLETED
                            </span>
                        )}
                        {appointment.status === 'CONFIRMED' && (
                            <span style={{ backgroundColor: 'rgba(59, 130, 246, 0.2)', color: '#60A5FA' }} className="px-4 py-2 rounded-lg text-sm font-semibold">
                                {appointment.status}
                            </span>
                        )}
                    </div>
                </div>

                {/* General Information */}
                <div style={{ backgroundColor: '#1F2937', borderColor: '#374151' }} className="rounded-lg border overflow-hidden mb-8">
                    <div className="px-6 py-4" style={{ borderBottom: '1px solid #374151' }}>
                        <h2 className="text-xl font-bold text-white">General Information</h2>
                    </div>
                    <div style={{ lineHeight: '1.5' }}>
                        <div className="px-6 py-5 flex" style={{ borderBottom: '1px solid #374151' }}>
                            <span style={{ color: '#9CA3AF' }} className="w-40">Date & Time:</span>
                            <span className="text-white font-medium">{new Date(appointment.scheduledAt).toLocaleString()}</span>
                        </div>
                        <div className="px-6 py-5 flex" style={{ borderBottom: '1px solid #374151' }}>
                            <span style={{ color: '#9CA3AF' }} className="w-40">Doctor:</span>
                            <span className="text-white font-medium">{appointment.doctor?.name || 'Unknown'}</span>
                        </div>
                        <div className="px-6 py-5 flex" style={{ borderBottom: '1px solid #374151' }}>
                            <span style={{ color: '#9CA3AF' }} className="w-40">Patient:</span>
                            <span className="text-white font-medium">{appointment.patient?.name || 'Unknown'}</span>
                        </div>
                        <div className="px-6 py-5 flex">
                            <span style={{ color: '#9CA3AF' }} className="w-40">Reason:</span>
                            <span className="text-white font-medium">{appointment.reason || 'No reason provided'}</span>
                        </div>
                    </div>
                </div>

                {/* Prescription Section - Only show if appointment is COMPLETED */}
                {appointment.status === 'COMPLETED' && (
                    <div className="flex justify-center">
                        <Link
                            href={`/dashboard/appointments/${id}/prescription`}
                            style={{ backgroundColor: '#EA580C' }}
                            className="px-8 py-3 text-white rounded-lg font-medium hover:opacity-90 transition-opacity"
                        >
                            View Prescription
                        </Link>
                    </div>
                )}
            </div>
        </div>
    );
}

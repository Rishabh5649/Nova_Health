'use client';
export const dynamic = 'force-dynamic';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { format, addDays, startOfWeek, addWeeks, subWeeks, isSameDay, parseISO } from 'date-fns';
import { getDoctorAvailability, directReschedule, getDoctorTimeOff } from '@/lib/api';

import { Suspense } from 'react';

function CalendarContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const appointmentIdToSchedule = searchParams.get('appointmentId');
    const action = searchParams.get('action'); // 'schedule' or 'reschedule'
    const [currentWeek, setCurrentWeek] = useState(new Date());
    const [selectedDoctor, setSelectedDoctor] = useState<string>('');
    const [doctors, setDoctors] = useState<any[]>([]);
    const [appointments, setAppointments] = useState<any[]>([]);
    const [pendingAppointments, setPendingAppointments] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [showAssignModal, setShowAssignModal] = useState(false);
    const [selectedSlot, setSelectedSlot] = useState<{ date: Date; time: string } | null>(null);
    const [assigning, setAssigning] = useState(false);
    const [doctorWorkHours, setDoctorWorkHours] = useState<any[]>([]);
    const [doctorTimeOff, setDoctorTimeOff] = useState<any[]>([]);

    const weekStart = startOfWeek(currentWeek, { weekStartsOn: 1 }); // Monday
    const weekDays = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));

    const timeSlots = Array.from({ length: 18 }, (_, i) => {
        const hour = i + 6; // 6 AM to 11 PM
        return `${hour.toString().padStart(2, '0')}:00`;
    });

    useEffect(() => {
        loadDoctors();
    }, []);

    useEffect(() => {
        if (selectedDoctor) {
            loadAppointments();
            loadPendingAppointments();
            loadDoctorWorkHours();
            loadDoctorTimeOff();
        }
    }, [selectedDoctor, currentWeek]);

    const loadDoctorTimeOff = async () => {
        const token = localStorage.getItem('token');
        if (!token || !selectedDoctor) return;

        try {
            // Fetch for slightly more than the current week to be safe
            const start = subWeeks(weekStart, 1).toISOString();
            const end = addWeeks(weekStart, 2).toISOString();
            const timeOff = await getDoctorTimeOff(token, selectedDoctor, start, end);
            setDoctorTimeOff(timeOff || []);
        } catch (err) {
            console.error('Failed to load doctor time off:', err);
            setDoctorTimeOff([]);
        }
    };

    const loadDoctorWorkHours = async () => {
        const token = localStorage.getItem('token');
        if (!token || !selectedDoctor) return;

        try {
            const workHours = await getDoctorAvailability(token, selectedDoctor);
            setDoctorWorkHours(workHours || []);
        } catch (err) {
            console.error('Failed to load doctor work hours:', err);
            setDoctorWorkHours([]);
        }
    };

    const loadDoctors = async () => {
        const token = localStorage.getItem('token');
        if (!token) {
            router.push('/');
            return;
        }

        try {
            const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:3000'}/doctors`, {
                headers: { 'Authorization': `Bearer ${token}` },
            });
            const data = await res.json();
            setDoctors(data.items || []);
            if (data.items && data.items.length > 0) {
                setSelectedDoctor(data.items[0].userId);
            }
        } catch (err) {
            console.error('Failed to load doctors:', err);
        } finally {
            setLoading(false);
        }
    };

    const loadAppointments = async () => {
        const token = localStorage.getItem('token');
        if (!token || !selectedDoctor) return;

        try {
            const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:3000'}/appointments?doctorId=${selectedDoctor}`, {
                headers: { 'Authorization': `Bearer ${token}` },
            });
            const data = await res.json();
            setAppointments(data || []);
        } catch (err) {
            console.error('Failed to load appointments:', err);
        }
    };

    const loadPendingAppointments = async () => {
        const token = localStorage.getItem('token');
        if (!token || !selectedDoctor) return;

        try {
            const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:3000'}/appointments?doctorId=${selectedDoctor}&status=PENDING`, {
                headers: { 'Authorization': `Bearer ${token}` },
            });
            const data = await res.json();
            setPendingAppointments(data || []);
        } catch (err) {
            console.error('Failed to load pending appointments:', err);
        }
    };

    const handleSlotClick = async (day: Date, time: string) => {
        setSelectedSlot({ date: day, time });

        if (appointmentIdToSchedule && action === 'schedule') {
            if (confirm(`Schedule appointment for ${format(day, 'MMM d')} at ${time}?`)) {
                assignAppointment(appointmentIdToSchedule, day, time);
            }
        } else if (appointmentIdToSchedule && action === 'reschedule') {
            if (confirm(`Reschedule appointment to ${format(day, 'MMM d')} at ${time}?`)) {
                await rescheduleAppointment(appointmentIdToSchedule, day, time);
            }
        } else {
            setShowAssignModal(true);
        }
    };

    const rescheduleAppointment = async (appointmentId: string, day: Date, time: string) => {
        const token = localStorage.getItem('token');
        if (!token) return;

        try {
            const [hour] = time.split(':');
            const scheduledAt = new Date(day);
            scheduledAt.setHours(parseInt(hour), 0, 0, 0);

            await directReschedule(token, appointmentId, scheduledAt.toISOString());
            alert('Appointment rescheduled successfully!');
            router.push('/dashboard/appointments');
        } catch (err: any) {
            alert('Error rescheduling: ' + err.message);
        }
    };

    const assignAppointment = async (appointmentId: string, day?: Date, time?: string) => {
        const targetDate = day || selectedSlot?.date;
        const targetTime = time || selectedSlot?.time;

        if (!targetDate || !targetTime) return;

        const token = localStorage.getItem('token');
        if (!token) return;

        setAssigning(true);
        try {
            const [hour] = targetTime.split(':');
            const scheduledAt = new Date(targetDate);
            scheduledAt.setHours(parseInt(hour), 0, 0, 0);

            await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:3000'}/appointments/${appointmentId}/confirm`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ scheduledAt: scheduledAt.toISOString() }),
            });

            setShowAssignModal(false);
            setSelectedSlot(null);
            loadAppointments();
            loadPendingAppointments();

            if (appointmentIdToSchedule) {
                router.push('/dashboard/appointments');
                alert('Appointment scheduled successfully');
            }
        } catch (err: any) {
            alert(err.message || 'Failed to assign appointment');
        } finally {
            setAssigning(false);
        }
    };

    const getAppointmentsForSlot = (day: Date, time: string) => {
        const [hour] = time.split(':');
        return appointments.filter(appt => {
            const apptDate = parseISO(appt.scheduledAt);
            return isSameDay(apptDate, day) && apptDate.getHours() === parseInt(hour);
        });
    };

    const isSlotAvailable = (day: Date, time: string): boolean => {
        const weekday = day.getDay(); // 0=Sunday, 6=Saturday
        const [hourStr] = time.split(':');
        const hour = parseInt(hourStr);

        // Check if doctor has work hours set for this day
        const dayWorkHours = doctorWorkHours.find(wh => wh.weekday === weekday);
        if (!dayWorkHours) return false; // Doctor doesn't work on this day

        // Check if hour is within work hours
        if (hour < dayWorkHours.startHour || hour >= dayWorkHours.endHour) return false;

        // Check if slot is within time off
        const slotDate = new Date(day);
        slotDate.setHours(hour, 0, 0, 0);

        const isTimeOff = doctorTimeOff.some(off => {
            const start = new Date(off.startTime);
            const end = new Date(off.endTime);
            return slotDate >= start && slotDate < end;
        });

        return !isTimeOff;
    };

    const nextWeek = () => setCurrentWeek(addWeeks(currentWeek, 1));
    const prevWeek = () => setCurrentWeek(subWeeks(currentWeek, 1));
    const today = () => setCurrentWeek(new Date());

    if (loading) {
        return (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
                <div>Loading...</div>
            </div>
        );
    }

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h2 style={{ fontSize: '1.5rem', fontWeight: 600 }}>Doctor Schedule</h2>
                <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                    <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                        {pendingAppointments.length} pending requests
                    </div>
                    <select
                        value={selectedDoctor}
                        onChange={(e) => setSelectedDoctor(e.target.value)}
                        className="input"
                        style={{ width: '200px' }}
                    >
                        {doctors.map(doc => (
                            <option key={doc.userId} value={doc.userId}>
                                {doc.name}
                            </option>
                        ))}
                    </select>
                </div>
            </div>

            <div className="card" style={{ padding: '1.5rem' }}>
                {/* Week Navigation */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                    <button onClick={prevWeek} className="btn" style={{ padding: '0.5rem 1rem' }}>
                        ← Previous Week
                    </button>
                    <div style={{ display: 'flex', gap: '1rem' }}>
                        <button onClick={today} className="btn btn-primary">
                            Today
                        </button>
                        <span style={{ fontSize: '1.1rem', fontWeight: 600 }}>
                            {format(weekStart, 'MMM d')} - {format(addDays(weekStart, 6), 'MMM d, yyyy')}
                        </span>
                    </div>
                    <button onClick={nextWeek} className="btn" style={{ padding: '0.5rem 1rem' }}>
                        Next Week →
                    </button>
                </div>

                {/* Calendar Grid */}
                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '900px' }}>
                        <thead>
                            <tr>
                                <th style={{
                                    padding: '0.75rem',
                                    borderBottom: '2px solid var(--border-color)',
                                    textAlign: 'left',
                                    width: '80px',
                                    position: 'sticky',
                                    left: 0,
                                    background: 'var(--bg-main)',
                                    zIndex: 10
                                }}>
                                    Time
                                </th>
                                {weekDays.map(day => (
                                    <th key={day.toISOString()} style={{
                                        padding: '0.75rem',
                                        borderBottom: '2px solid var(--border-color)',
                                        textAlign: 'center',
                                        background: isSameDay(day, new Date()) ? 'var(--primary-light)' : 'transparent'
                                    }}>
                                        <div style={{ fontWeight: 600 }}>{format(day, 'EEE')}</div>
                                        <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>{format(day, 'MMM d')}</div>
                                    </th>
                                ))}
                            </tr>
                        </thead>
                        <tbody>
                            {timeSlots.map(time => (
                                <tr key={time}>
                                    <td style={{
                                        padding: '0.5rem',
                                        borderBottom: '1px solid var(--border-color)',
                                        fontSize: '0.875rem',
                                        color: 'var(--text-muted)',
                                        position: 'sticky',
                                        left: 0,
                                        background: 'var(--bg-main)',
                                        zIndex: 9
                                    }}>
                                        {time}
                                    </td>
                                    {weekDays.map(day => {
                                        const slotAppointments = getAppointmentsForSlot(day, time);
                                        const hasAppointment = slotAppointments.length > 0;
                                        const isAvailable = isSlotAvailable(day, time);
                                        const isClickable = !hasAppointment && isAvailable;

                                        return (
                                            <td
                                                key={`${day.toISOString()}-${time}`}
                                                onClick={() => isClickable && handleSlotClick(day, time)}
                                                style={{
                                                    padding: '0.25rem',
                                                    borderBottom: '1px solid var(--border-color)',
                                                    borderRight: '1px solid var(--border-color)',
                                                    height: '60px',
                                                    verticalAlign: 'top',
                                                    background: !isAvailable ? '#f5f5f5' : isSameDay(day, new Date()) ? 'rgba(99, 102, 241, 0.05)' : 'transparent',
                                                    cursor: isClickable ? 'pointer' : 'not-allowed',
                                                    transition: 'background 0.2s',
                                                    opacity: !isAvailable ? 0.5 : 1
                                                }}
                                                onMouseEnter={(e) => {
                                                    if (isClickable) {
                                                        e.currentTarget.style.background = 'rgba(99, 102, 241, 0.1)';
                                                    }
                                                }}
                                                onMouseLeave={(e) => {
                                                    if (isClickable) {
                                                        e.currentTarget.style.background = isSameDay(day, new Date()) ? 'rgba(99, 102, 241, 0.05)' : 'transparent';
                                                    }
                                                }}
                                            >
                                                {hasAppointment ? (
                                                    <div style={{
                                                        background: 'var(--primary)',
                                                        color: 'white',
                                                        padding: '0.25rem 0.5rem',
                                                        borderRadius: 'var(--radius)',
                                                        fontSize: '0.75rem',
                                                        overflow: 'hidden',
                                                        textOverflow: 'ellipsis',
                                                        whiteSpace: 'nowrap'
                                                    }}>
                                                        {slotAppointments[0].patient?.name || 'Patient'}
                                                    </div>
                                                ) : !isAvailable ? (
                                                    <div style={{
                                                        fontSize: '0.75rem',
                                                        color: 'var(--text-muted)',
                                                        textAlign: 'center',
                                                        padding: '0.25rem'
                                                    }}>
                                                        -
                                                    </div>
                                                ) : (
                                                    <div style={{
                                                        fontSize: '0.75rem',
                                                        color: 'var(--text-muted)',
                                                        textAlign: 'center',
                                                        opacity: 0
                                                    }}
                                                        onMouseEnter={(e) => e.currentTarget.style.opacity = '1'}
                                                        onMouseLeave={(e) => e.currentTarget.style.opacity = '0'}
                                                    >
                                                        Click to assign
                                                    </div>
                                                )}
                                            </td>
                                        );
                                    })}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                {/* Legend */}
                <div style={{ marginTop: '1.5rem', display: 'flex', gap: '2rem', fontSize: '0.875rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <div style={{ width: '16px', height: '16px', background: 'var(--primary)', borderRadius: '4px' }}></div>
                        <span>Booked</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <div style={{ width: '16px', height: '16px', background: 'rgba(99, 102, 241, 0.1)', borderRadius: '4px', border: '1px solid var(--border-color)' }}></div>
                        <span>Available (Click to assign)</span>
                    </div>
                </div>
            </div>

            {/* Assign Appointment Modal */}
            {showAssignModal && selectedSlot && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    background: 'rgba(0,0,0,0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 1000
                }}
                    onClick={() => setShowAssignModal(false)}
                >
                    <div className="card" style={{ maxWidth: '500px', width: '90%', padding: '2rem' }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <h3 style={{ marginBottom: '1rem' }}>Assign Appointment</h3>
                        <p style={{ marginBottom: '1.5rem', color: 'var(--text-muted)' }}>
                            {format(selectedSlot.date, 'EEEE, MMMM d, yyyy')} at {selectedSlot.time}
                        </p>

                        {pendingAppointments.length === 0 ? (
                            <p style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                                No pending appointments for this doctor
                            </p>
                        ) : (
                            <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
                                {pendingAppointments.map(appt => (
                                    <div key={appt.id} style={{
                                        padding: '1rem',
                                        border: '1px solid var(--border-color)',
                                        borderRadius: 'var(--radius)',
                                        marginBottom: '0.5rem',
                                        display: 'flex',
                                        justifyContent: 'space-between',
                                        alignItems: 'center'
                                    }}>
                                        <div>
                                            <div style={{ fontWeight: 500 }}>{appt.patient?.name || 'Unknown Patient'}</div>
                                            <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                                {appt.reason || 'No reason provided'}
                                            </div>
                                        </div>
                                        <button
                                            onClick={() => assignAppointment(appt.id)}
                                            disabled={assigning}
                                            className="btn btn-primary"
                                            style={{ padding: '0.5rem 1rem' }}
                                        >
                                            {assigning ? 'Assigning...' : 'Assign'}
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )}

                        <button
                            onClick={() => setShowAssignModal(false)}
                            className="btn"
                            style={{ marginTop: '1rem', width: '100%' }}
                        >
                            Cancel
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}

export default function CalendarPage() {
    return (
        <Suspense fallback={<div>Loading calendar...</div>}>
            <CalendarContent />
        </Suspense>
    );
}

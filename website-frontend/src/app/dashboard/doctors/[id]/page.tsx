'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { getDoctorProfile, updateDoctorProfile, getDoctorAvailability, setDoctorAvailability } from '@/lib/api';

const DAYS_OF_WEEK = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

interface WorkHours {
    weekday: number;
    startHour: number;
    endHour: number;
}

export default function EditDoctorPage() {
    const router = useRouter();
    const params = useParams();
    const userId = params.id as string;
    const [doctor, setDoctor] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [activeTab, setActiveTab] = useState<'profile' | 'hours'>('profile');

    const [formData, setFormData] = useState({
        specialties: '',
        qualifications: '',
        yearsExperience: 0,
        bio: '',
        baseFee: 0,
        followUpFee: 0,
        followUpDays: 0,
    });

    const [workHours, setWorkHours] = useState<WorkHours[]>([]);

    useEffect(() => {
        loadData();
    }, [userId]);

    const loadData = async () => {
        const token = localStorage.getItem('token');
        if (!token) {
            router.push('/');
            return;
        }

        try {
            // Load doctor profile
            const data = await getDoctorProfile(token, userId);
            setDoctor(data);
            const profile = data.doctorProfile || {};
            setFormData({
                specialties: profile.specialties?.join(', ') || '',
                qualifications: profile.qualifications?.join(', ') || '',
                yearsExperience: profile.yearsExperience || 0,
                bio: profile.bio || '',
                baseFee: profile.baseFee || 0,
                followUpFee: profile.followUpFee || 0,
                followUpDays: profile.followUpDays || 0,
            });

            // Load work hours
            const availability = await getDoctorAvailability(token, userId);
            setWorkHours(availability || []);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true);
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');
        const user = JSON.parse(userStr || '{}');
        const orgId = user.memberships?.[0]?.organizationId;

        if (!token || !orgId) return;

        try {
            const payload = {
                ...formData,
                specialties: formData.specialties.split(',').map(s => s.trim()).filter(s => s),
                qualifications: formData.qualifications.split(',').map(s => s.trim()).filter(s => s),
                yearsExperience: Number(formData.yearsExperience),
                baseFee: Number(formData.baseFee),
                followUpFee: Number(formData.followUpFee),
                followUpDays: Number(formData.followUpDays),
            };

            await updateDoctorProfile(token, orgId, userId, payload);
            alert('Doctor profile updated successfully');
            router.push('/dashboard/doctors');
        } catch (err) {
            console.error(err);
            alert('Failed to update profile');
        } finally {
            setSaving(false);
        }
    };

    const handleSaveWorkHours = async () => {
        const token = localStorage.getItem('token');
        if (!token) return;

        setSaving(true);
        try {
            await setDoctorAvailability(token, userId, workHours);
            alert('Work hours updated successfully');
        } catch (err) {
            console.error(err);
            alert('Failed to update work hours');
        } finally {
            setSaving(false);
        }
    };

    const toggleDay = (weekday: number) => {
        const existing = workHours.find(wh => wh.weekday === weekday);
        if (existing) {
            // Remove this day
            setWorkHours(workHours.filter(wh => wh.weekday !== weekday));
        } else {
            // Add this day with default hours (9 AM - 5 PM)
            setWorkHours([...workHours, { weekday, startHour: 9, endHour: 17 }]);
        }
    };

    const updateDayHours = (weekday: number, field: 'startHour' | 'endHour', value: number) => {
        setWorkHours(workHours.map(wh =>
            wh.weekday === weekday ? { ...wh, [field]: value } : wh
        ));
    };

    if (loading) return <div>Loading...</div>;
    if (!doctor) return <div>Doctor not found</div>;

    return (
        <div style={{ maxWidth: '900px', margin: '0 auto' }}>
            <button onClick={() => router.back()} className="btn btn-outline" style={{ marginBottom: '1rem' }}>← Back</button>

            <div className="card">
                <h1 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: '1.5rem' }}>Edit Doctor: {doctor.name}</h1>

                {/* Tabs */}
                <div style={{ display: 'flex', gap: '1rem', borderBottom: '2px solid var(--border-color)', marginBottom: '2rem' }}>
                    <button
                        onClick={() => setActiveTab('profile')}
                        style={{
                            padding: '0.75rem 1rem',
                            border: 'none',
                            background: 'none',
                            borderBottom: activeTab === 'profile' ? '2px solid var(--primary)' : 'none',
                            color: activeTab === 'profile' ? 'var(--primary)' : 'var(--text-muted)',
                            fontWeight: activeTab === 'profile' ? 600 : 400,
                            cursor: 'pointer',
                            marginBottom: '-2px',
                        }}
                    >
                        Profile Details
                    </button>
                    <button
                        onClick={() => setActiveTab('hours')}
                        style={{
                            padding: '0.75rem 1rem',
                            border: 'none',
                            background: 'none',
                            borderBottom: activeTab === 'hours' ? '2px solid var(--primary)' : 'none',
                            color: activeTab === 'hours' ? 'var(--primary)' : 'var(--text-muted)',
                            fontWeight: activeTab === 'hours' ? 600 : 400,
                            cursor: 'pointer',
                            marginBottom: '-2px',
                        }}
                    >
                        Work Hours
                    </button>
                </div>

                {/* Profile Tab */}
                {activeTab === 'profile' && (
                    <form onSubmit={handleSubmit}>
                        <div className="form-group">
                            <label>Specialties (comma separated)</label>
                            <input
                                type="text"
                                className="input"
                                value={formData.specialties}
                                onChange={(e) => setFormData({ ...formData, specialties: e.target.value })}
                            />
                        </div>

                        <div className="form-group">
                            <label>Qualifications (comma separated)</label>
                            <input
                                type="text"
                                className="input"
                                value={formData.qualifications}
                                onChange={(e) => setFormData({ ...formData, qualifications: e.target.value })}
                            />
                        </div>

                        <div className="form-group">
                            <label>Years of Experience</label>
                            <input
                                type="number"
                                className="input"
                                value={formData.yearsExperience}
                                onChange={(e) => setFormData({ ...formData, yearsExperience: Number(e.target.value) })}
                            />
                        </div>

                        <div className="form-group">
                            <label>Bio</label>
                            <textarea
                                className="input"
                                rows={4}
                                value={formData.bio}
                                onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
                            />
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
                            <div className="form-group">
                                <label>Base Fee</label>
                                <input
                                    type="number"
                                    className="input"
                                    value={formData.baseFee}
                                    onChange={(e) => setFormData({ ...formData, baseFee: Number(e.target.value) })}
                                />
                            </div>
                            <div className="form-group">
                                <label>Follow-up Fee</label>
                                <input
                                    type="number"
                                    className="input"
                                    value={formData.followUpFee}
                                    onChange={(e) => setFormData({ ...formData, followUpFee: Number(e.target.value) })}
                                />
                            </div>
                            <div className="form-group">
                                <label>Follow-up Days</label>
                                <input
                                    type="number"
                                    className="input"
                                    value={formData.followUpDays}
                                    onChange={(e) => setFormData({ ...formData, followUpDays: Number(e.target.value) })}
                                />
                            </div>
                        </div>

                        <div style={{ marginTop: '2rem', display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
                            <button type="button" className="btn btn-outline" onClick={() => router.back()}>Cancel</button>
                            <button type="submit" className="btn btn-primary" disabled={saving}>
                                {saving ? 'Saving...' : 'Save Changes'}
                            </button>
                        </div>
                    </form>
                )}

                {/* Work Hours Tab */}
                {activeTab === 'hours' && (
                    <div>
                        <p style={{ marginBottom: '1.5rem', color: 'var(--text-muted)' }}>
                            Set the doctor's weekly work schedule. Click on a day to enable/disable it.
                        </p>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                            {DAYS_OF_WEEK.map((day, index) => {
                                const dayHours = workHours.find(wh => wh.weekday === index);
                                const isEnabled = !!dayHours;

                                return (
                                    <div key={index} style={{ display: 'flex', alignItems: 'center', gap: '1rem', padding: '1rem', border: '1px solid var(--border-color)', borderRadius: 'var(--radius)', background: isEnabled ? 'rgba(99, 102, 241, 0.05)' : 'transparent' }}>
                                        <input
                                            type="checkbox"
                                            checked={isEnabled}
                                            onChange={() => toggleDay(index)}
                                            style={{ width: '20px', height: '20px' }}
                                        />
                                        <div style={{ minWidth: '100px', fontWeight: 500 }}>{day}</div>

                                        {isEnabled && (
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flex: 1 }}>
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                                    <label style={{ fontSize: '0.875rem' }}>Start:</label>
                                                    <select
                                                        value={dayHours.startHour}
                                                        onChange={(e) => updateDayHours(index, 'startHour', Number(e.target.value))}
                                                        className="input"
                                                        style={{ width: '100px' }}
                                                    >
                                                        {Array.from({ length: 24 }, (_, i) => (
                                                            <option key={i} value={i}>
                                                                {i.toString().padStart(2, '0')}:00
                                                            </option>
                                                        ))}
                                                    </select>
                                                </div>

                                                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                                    <label style={{ fontSize: '0.875rem' }}>End:</label>
                                                    <select
                                                        value={dayHours.endHour}
                                                        onChange={(e) => updateDayHours(index, 'endHour', Number(e.target.value))}
                                                        className="input"
                                                        style={{ width: '100px' }}
                                                    >
                                                        {Array.from({ length: 24 }, (_, i) => (
                                                            <option key={i} value={i}>
                                                                {i.toString().padStart(2, '0')}:00
                                                            </option>
                                                        ))}
                                                    </select>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                );
                            })}
                        </div>

                        <div style={{ marginTop: '2rem', display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
                            <button type="button" className="btn btn-outline" onClick={() => router.back()}>Cancel</button>
                            <button type="button" className="btn btn-primary" onClick={handleSaveWorkHours} disabled={saving}>
                                {saving ? 'Saving...' : 'Save Work Hours'}
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

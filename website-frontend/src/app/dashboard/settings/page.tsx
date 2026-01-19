'use client';

import { useEffect, useState } from 'react';
import { getOrganizations, updateOrganization } from '@/lib/api';

export default function SettingsPage() {
    const [loading, setLoading] = useState(true);
    const [org, setOrg] = useState<any>(null);
    const [formData, setFormData] = useState({
        name: '',
        type: 'Hospital',
        address: '',
        contactEmail: '',
        contactPhone: '',
        feeControlMode: 'doctor_controlled'
    });
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        loadOrg();
    }, []);

    const loadOrg = async () => {
        const token = localStorage.getItem('token');
        if (!token) return;

        try {
            const orgs = await getOrganizations(token);
            if (orgs && orgs.length > 0) {
                const o = orgs[0];
                setOrg(o);
                setFormData({
                    name: o.name || '',
                    type: o.type || 'Hospital',
                    address: o.address || '',
                    contactEmail: o.contactEmail || '',
                    contactPhone: o.contactPhone || '',
                    feeControlMode: o.feeControlMode || 'doctor_controlled'
                });
            }
        } catch (err) {
            console.error('Failed to load organization', err);
        } finally {
            setLoading(false);
        }
    };

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSave = async () => {
        if (!org) return;
        const token = localStorage.getItem('token');
        if (!token) return;

        setSaving(true);
        try {
            await updateOrganization(token, org.id, formData);
            alert('Settings saved successfully!');
        } catch (err: any) {
            alert('Failed to save settings: ' + err.message);
        } finally {
            setSaving(false);
        }
    };

    if (loading) return <div>Loading...</div>;

    return (
        <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: '2rem' }}>Organization Settings</h2>

            <div className="card" style={{ marginBottom: '1.5rem' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '1rem' }}>General Information</h3>
                <div style={{ display: 'grid', gap: '1rem' }}>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>
                            Organization Name
                        </label>
                        <input
                            type="text"
                            name="name"
                            value={formData.name}
                            onChange={handleChange}
                            className="input"
                            placeholder="City Hospital"
                        />
                    </div>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>
                            Type
                        </label>
                        <select
                            name="type"
                            value={formData.type}
                            onChange={handleChange}
                            className="input"
                        >
                            <option value="Hospital">Hospital</option>
                            <option value="Clinic">Clinic</option>
                        </select>
                    </div>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>
                            Address
                        </label>
                        <textarea
                            name="address"
                            value={formData.address}
                            onChange={handleChange}
                            className="input"
                            rows={3}
                            placeholder="123 Health St, Wellness City"
                        ></textarea>
                    </div>
                </div>
            </div>

            <div className="card" style={{ marginBottom: '1.5rem' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '1rem' }}>Contact Information</h3>
                <div style={{ display: 'grid', gap: '1rem' }}>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>
                            Email
                        </label>
                        <input
                            type="email"
                            name="contactEmail"
                            value={formData.contactEmail}
                            onChange={handleChange}
                            className="input"
                            placeholder="admin@hospital.com"
                        />
                    </div>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>
                            Phone
                        </label>
                        <input
                            type="tel"
                            name="contactPhone"
                            value={formData.contactPhone}
                            onChange={handleChange}
                            className="input"
                            placeholder="+1234567890"
                        />
                    </div>
                </div>
            </div>

            <div className="card" style={{ marginBottom: '1.5rem' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '1rem' }}>Fee Control</h3>
                <div style={{ display: 'grid', gap: '1rem' }}>
                    <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                        Determine who controls the consultation fees.
                    </p>
                    <div style={{ display: 'flex', gap: '2rem' }}>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer' }}>
                            <input
                                type="radio"
                                name="feeControlMode"
                                value="doctor_controlled"
                                checked={formData.feeControlMode === 'doctor_controlled'}
                                onChange={handleChange}
                            />
                            <span>Doctor Controlled</span>
                        </label>
                        <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer' }}>
                            <input
                                type="radio"
                                name="feeControlMode"
                                value="organization_controlled"
                                checked={formData.feeControlMode === 'organization_controlled'}
                                onChange={handleChange}
                            />
                            <span>Organization Controlled</span>
                        </label>
                    </div>
                    <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                        * In Organization Controlled mode, doctors cannot change their fees.
                    </p>
                </div>
            </div>

            <div className="card">
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '1rem' }}>Prescription Policy</h3>
                <div style={{ display: 'grid', gap: '1rem' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <input type="checkbox" />
                        <span>Require doctor signature for all prescriptions</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <input type="checkbox" />
                        <span>Allow receptionists to issue prescriptions directly</span>
                    </label>
                </div>
            </div>

            <div style={{ marginTop: '2rem' }}>
                <button
                    className="btn btn-primary"
                    onClick={handleSave}
                    disabled={saving}
                >
                    {saving ? 'Saving...' : 'Save Changes'}
                </button>
            </div>
        </div>
    );
}

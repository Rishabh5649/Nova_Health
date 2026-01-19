'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getOrganizationSettings, updateOrganizationSettings, getOrganization } from '@/lib/api';

interface OrgSettings {
    id: string;
    organizationId: string;
    enableReceptionists: boolean;
    allowPatientBooking: boolean;
    requireApprovalForDoctors: boolean;
    requireApprovalForReceptionists: boolean;
    autoApproveFollowUps: boolean;
}

export default function OrganizationSettingsPage() {
    const router = useRouter();
    const [settings, setSettings] = useState<OrgSettings | null>(null);
    const [org, setOrg] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');

    useEffect(() => {
        loadSettings();
    }, []);

    async function loadSettings() {
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

            const data = await getOrganizationSettings(token, orgId);
            setSettings(data);

            try {
                const orgData = await getOrganization(token, orgId);
                setOrg(orgData);
            } catch (e) {
                console.error('Failed to load org details', e);
            }

            setLoading(false);
        } catch (err: any) {
            console.error('Error loading settings:', err);
            setError(err.message || 'Failed to load settings');
            setLoading(false);
        }
    }

    async function handleSave() {
        if (!settings) return;

        try {
            setSaving(true);
            setError('');
            setSuccess('');

            const token = localStorage.getItem('token');
            const userStr = localStorage.getItem('user');
            const user = JSON.parse(userStr!);
            const orgId = user.memberships?.[0]?.organizationId;

            await updateOrganizationSettings(token!, orgId, {
                enableReceptionists: settings.enableReceptionists,
                allowPatientBooking: settings.allowPatientBooking,
                requireApprovalForDoctors: settings.requireApprovalForDoctors,
                requireApprovalForReceptionists: settings.requireApprovalForReceptionists,
                autoApproveFollowUps: settings.autoApproveFollowUps,
            });

            setSuccess('Settings saved successfully!');
            setTimeout(() => setSuccess(''), 3000);
            setSaving(false);
        } catch (err: any) {
            console.error('Error saving settings:', err);
            setError(err.message || 'Failed to save settings');
            setSaving(false);
        }
    }

    function handleToggle(key: keyof OrgSettings) {
        if (!settings) return;
        setSettings({
            ...settings,
            [key]: !settings[key],
        });
    }

    if (loading) {
        return (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
                <div>Loading settings...</div>
            </div>
        );
    }

    if (error && !settings) {
        return (
            <div className="card">
                <p style={{ color: 'var(--error)', textAlign: 'center' }}>{error}</p>
            </div>
        );
    }

    return (
        <div>
            <div style={{ marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.75rem', fontWeight: 'bold', marginBottom: '0.5rem' }}>Organization Settings</h1>
                <p style={{ color: 'var(--text-muted)' }}>Configure your organization's preferences and features</p>
            </div>

            {/* Success/Error Messages */}
            {success && (
                <div className="card" style={{ marginBottom: '1rem', padding: '1rem', backgroundColor: 'var(--success-bg)', border: '1px solid var(--success)' }}>
                    <p style={{ color: 'var(--success)', margin: 0 }}>✓ {success}</p>
                </div>
            )}
            {error && (
                <div className="card" style={{ marginBottom: '1rem', padding: '1rem', backgroundColor: 'var(--error-bg)', border: '1px solid var(--error)' }}>
                    <p style={{ color: 'var(--error)', margin: 0 }}>✗ {error}</p>
                </div>
            )}

            {/* Settings Form */}
            <div className="card">
                <h3 style={{ fontSize: '1.1rem', fontWeight: 600, marginBottom: '1.5rem' }}>General Settings</h3>

                {/* Location Map */}
                {org && org.address && (
                    <div style={{ marginBottom: '2rem' }}>
                        <h4 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '1rem', color: 'var(--text-main)' }}>
                            Location
                        </h4>
                        <div style={{ marginBottom: '1rem', color: 'var(--text-muted)', fontSize: '0.875rem' }}>
                            {org.address}
                        </div>
                        <div style={{ borderRadius: '8px', overflow: 'hidden', border: '1px solid var(--border-color)' }}>
                            <iframe
                                width="100%"
                                height="300"
                                style={{ border: 0 }}
                                loading="lazy"
                                allowFullScreen
                                src={`https://maps.google.com/maps?q=${encodeURIComponent(org.address)}&t=&z=15&ie=UTF8&iwloc=&output=embed`}
                            ></iframe>
                        </div>
                    </div>
                )}

                {/* Staff Management */}
                <div style={{ marginBottom: '2rem' }}>
                    <h4 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '1rem', color: 'var(--text-main)' }}>
                        Staff Management
                    </h4>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        {/* Enable Receptionists */}
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: '8px' }}>
                            <div>
                                <div style={{ fontWeight: 500, marginBottom: '0.25rem' }}>Enable Receptionists</div>
                                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                    Allow receptionist role to manage appointments and patient data
                                </div>
                            </div>
                            <label className="toggle">
                                <input
                                    type="checkbox"
                                    checked={settings?.enableReceptionists}
                                    onChange={() => handleToggle('enableReceptionists')}
                                />
                                <span className="slider"></span>
                            </label>
                        </div>

                        {/* Require Approval for Doctors */}
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: '8px' }}>
                            <div>
                                <div style={{ fontWeight: 500, marginBottom: '0.25rem' }}>Require Approval for Doctors</div>
                                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                    New doctors must be approved by admin before accessing the system
                                </div>
                            </div>
                            <label className="toggle">
                                <input
                                    type="checkbox"
                                    checked={settings?.requireApprovalForDoctors}
                                    onChange={() => handleToggle('requireApprovalForDoctors')}
                                />
                                <span className="slider"></span>
                            </label>
                        </div>

                        {/* Require Approval for Receptionists */}
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: '8px' }}>
                            <div>
                                <div style={{ fontWeight: 500, marginBottom: '0.25rem' }}>Require Approval for Receptionists</div>
                                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                    New receptionists must be approved by admin before accessing the system
                                </div>
                            </div>
                            <label className="toggle">
                                <input
                                    type="checkbox"
                                    checked={settings?.requireApprovalForReceptionists}
                                    onChange={() => handleToggle('requireApprovalForReceptionists')}
                                />
                                <span className="slider"></span>
                            </label>
                        </div>
                    </div>
                </div>

                {/* Booking Settings */}
                <div style={{ marginBottom: '2rem' }}>
                    <h4 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '1rem', color: 'var(--text-main)' }}>
                        Booking Settings
                    </h4>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        {/* Allow Patient Booking */}
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: '8px' }}>
                            <div>
                                <div style={{ fontWeight: 500, marginBottom: '0.25rem' }}>Allow Patient Booking</div>
                                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                    Patients can book appointments directly through the system
                                </div>
                            </div>
                            <label className="toggle">
                                <input
                                    type="checkbox"
                                    checked={settings?.allowPatientBooking}
                                    onChange={() => handleToggle('allowPatientBooking')}
                                />
                                <span className="slider"></span>
                            </label>
                        </div>

                        {/* Auto Approve Follow-ups */}
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: '8px' }}>
                            <div>
                                <div style={{ fontWeight: 500, marginBottom: '0.25rem' }}>Auto Approve Follow-ups</div>
                                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                    Automatically approve follow-up appointments without manual confirmation
                                </div>
                            </div>
                            <label className="toggle">
                                <input
                                    type="checkbox"
                                    checked={settings?.autoApproveFollowUps}
                                    onChange={() => handleToggle('autoApproveFollowUps')}
                                />
                                <span className="slider"></span>
                            </label>
                        </div>
                    </div>
                </div>

                {/* Save Button */}
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', paddingTop: '1rem', borderTop: '1px solid var(--border-color)' }}>
                    <button
                        className="btn btn-outline"
                        onClick={loadSettings}
                        disabled={saving}
                    >
                        Reset
                    </button>
                    <button
                        className="btn btn-primary"
                        onClick={handleSave}
                        disabled={saving}
                    >
                        {saving ? 'Saving...' : 'Save Settings'}
                    </button>
                </div>
            </div>
        </div>
    );
}

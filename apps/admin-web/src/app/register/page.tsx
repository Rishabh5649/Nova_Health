'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { registerOrganization } from '@/lib/api';

export default function RegisterPage() {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        // Admin User Details
        adminName: '',
        adminEmail: '',
        adminPassword: '',
        adminPhone: '',

        // Organization Details
        name: '',
        type: 'Clinic', // Default
        address: '',
        contactEmail: '',
        contactPhone: '',
        feeControlMode: 'doctor_controlled',
        yearEstablished: '',
        latitude: '',
        longitude: '',
        branches: '', // Comma separated
    });

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            // Transform data for API
            const payload = {
                name: formData.name,
                type: formData.type,
                address: formData.address,
                contactEmail: formData.contactEmail || undefined,
                contactPhone: formData.contactPhone || undefined,
                feeControlMode: formData.feeControlMode,
                yearEstablished: formData.yearEstablished ? parseInt(formData.yearEstablished) : undefined,
                latitude: formData.latitude ? parseFloat(formData.latitude) : undefined,
                longitude: formData.longitude ? parseFloat(formData.longitude) : undefined,
                branches: formData.branches ? formData.branches.split(',').map(b => b.trim()) : [],
                adminUser: {
                    name: formData.adminName,
                    email: formData.adminEmail,
                    password: formData.adminPassword,
                    phone: formData.adminPhone || undefined,
                }
            };

            await registerOrganization(payload);

            // Redirect to success / login page
            // Maybe show a success message first?
            alert('Registration successful! Please login once your account is approved.');
            router.push('/login');

        } catch (err: any) {
            console.error(err);
            setError(err.message || 'Registration failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
            {/* Navbar */}
            <nav className="glass" style={{ padding: '1rem 0' }}>
                <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        {/* Logo */}
                        <img src="/logo.png" alt="Nova Health" style={{ height: '40px', objectFit: 'contain' }} />
                        <span style={{ fontSize: '1.5rem', fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--text-main)' }}>Nova Health</span>
                    </Link>
                    <div>
                        Already have an account? <Link href="/login" className="btn btn-outline" style={{ padding: '0.5rem 1rem', marginLeft: '1rem' }}>Login</Link>
                    </div>
                </div>
            </nav>

            <div className="container" style={{ flex: 1, display: 'flex', justifyContent: 'center', padding: '4rem 0' }}>
                <div className="glass-card" style={{ maxWidth: '800px', width: '100%', padding: '3rem', borderRadius: '1.5rem' }}>
                    <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
                        <h1 className="title-gradient" style={{ fontSize: '2.5rem', fontWeight: 800, marginBottom: '0.5rem' }}>Register Organization</h1>
                        <p style={{ color: 'var(--text-muted)' }}>Join Nova Health and transform your healthcare operations today.</p>
                    </div>

                    {error && (
                        <div style={{ background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', padding: '1rem', borderRadius: '0.5rem', marginBottom: '2rem', textAlign: 'center' }}>
                            {error}
                        </div>
                    )}

                    <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '2rem' }}>

                        {/* Admin Details Section */}
                        <div>
                            <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '0.5rem' }}>
                                Administrator Details
                            </h3>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Full Name *</label>
                                    <input required name="adminName" value={formData.adminName} onChange={handleChange} className="input" placeholder="e.g. Dr. John Doe" />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Email Address *</label>
                                    <input required type="email" name="adminEmail" value={formData.adminEmail} onChange={handleChange} className="input" placeholder="john@example.com" />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Password *</label>
                                    <input required type="password" name="adminPassword" value={formData.adminPassword} onChange={handleChange} className="input" placeholder="••••••••" />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Phone Number</label>
                                    <input name="adminPhone" value={formData.adminPhone} onChange={handleChange} className="input" placeholder="+1 (555) 000-0000" />
                                </div>
                            </div>
                        </div>

                        {/* Organization Details Section */}
                        <div>
                            <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '0.5rem' }}>
                                Organization Details
                            </h3>
                            <div style={{ display: 'grid', gap: '1.5rem' }}>
                                <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem' }}>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Organization Name *</label>
                                        <input required name="name" value={formData.name} onChange={handleChange} className="input" placeholder="e.g. City General Hospital" />
                                    </div>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Type *</label>
                                        <select name="type" value={formData.type} onChange={handleChange} className="input">
                                            <option value="Clinic">Clinic</option>
                                            <option value="Hospital">Hospital</option>
                                        </select>
                                    </div>
                                </div>

                                <div>
                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Address *</label>
                                    <input required name="address" value={formData.address} onChange={handleChange} className="input" placeholder="123 Medical Drive, Health City" />
                                </div>

                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Contact Email</label>
                                        <input type="email" name="contactEmail" value={formData.contactEmail} onChange={handleChange} className="input" placeholder="info@hospital.com" />
                                    </div>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Contact Phone</label>
                                        <input name="contactPhone" value={formData.contactPhone} onChange={handleChange} className="input" placeholder="+1 (555) 123-4567" />
                                    </div>
                                </div>

                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1.5rem' }}>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Year Established</label>
                                        <input type="number" name="yearEstablished" value={formData.yearEstablished} onChange={handleChange} className="input" placeholder="2005" />
                                    </div>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Latitude</label>
                                        <input type="number" step="any" name="latitude" value={formData.latitude} onChange={handleChange} className="input" placeholder="12.9716" />
                                    </div>
                                    <div>
                                        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Longitude</label>
                                        <input type="number" step="any" name="longitude" value={formData.longitude} onChange={handleChange} className="input" placeholder="77.5946" />
                                    </div>
                                </div>

                                <div>
                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Branches (comma separated)</label>
                                    <input name="branches" value={formData.branches} onChange={handleChange} className="input" placeholder="North Wing, South Wing, Downtown Clinic" />
                                </div>

                                <div>
                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>Fee Control Mode</label>
                                    <select name="feeControlMode" value={formData.feeControlMode} onChange={handleChange} className="input">
                                        <option value="doctor_controlled">Doctor Controlled (Doctors set their own fees)</option>
                                        <option value="organization_controlled">Organization Controlled (Standardized fees)</option>
                                    </select>
                                </div>
                            </div>
                        </div>

                        <div style={{ marginTop: '1rem', display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
                            <button type="button" onClick={() => router.back()} className="btn btn-outline" disabled={loading}>Cancel</button>
                            <button type="submit" className="btn btn-primary" style={{ padding: '0.75rem 3rem' }} disabled={loading}>
                                {loading ? 'Registering...' : 'Submit Application'}
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            {/* Footer */}
            <footer style={{ background: 'var(--bg-sidebar)', color: 'white', padding: '2rem 0', textAlign: 'center', fontSize: '0.875rem' }}>
                &copy; {new Date().getFullYear()} Nova Health. All rights reserved.
            </footer>
        </div>
    );
}

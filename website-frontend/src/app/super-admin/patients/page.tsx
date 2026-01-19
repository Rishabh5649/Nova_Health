'use client';

import { useEffect, useState } from 'react';
import { getUsers } from '@/lib/api';
import Link from 'next/link';

export default function PatientsPage() {
    const [patients, setPatients] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem('token') || '';
        getUsers(token, 'PATIENT')
            .then(setPatients)
            .catch(console.error)
            .finally(() => setLoading(false));
    }, []);

    return (
        <div>
            <div className="header">
                <div>
                    <h1 className="title-gradient" style={{ fontSize: '2rem', fontWeight: 'bold' }}>Global Patients</h1>
                    <p style={{ color: 'var(--text-muted)' }}>View all registered patients across the platform.</p>
                </div>
            </div>

            <div className="card" style={{ padding: 0 }}>
                {loading ? (
                    <div style={{ padding: '3rem', textAlign: 'center' }}>Loading patients...</div>
                ) : patients.length === 0 ? (
                    <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)' }}>No patients found.</div>
                ) : (
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead style={{ background: 'var(--bg-secondary)', color: 'var(--text-muted)', fontSize: '0.875rem', textAlign: 'left' }}>
                            <tr>
                                <th style={{ padding: '1rem 1.5rem' }}>Name</th>
                                <th style={{ padding: '1rem 1.5rem' }}>Email</th>
                                <th style={{ padding: '1rem 1.5rem' }}>Joined</th>
                                <th style={{ padding: '1rem 1.5rem', textAlign: 'right' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {patients.map((patient) => (
                                <tr key={patient.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                                    <td style={{ padding: '1rem 1.5rem' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                                            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: 'var(--primary-light)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)', fontWeight: 'bold' }}>
                                                {patient.name.charAt(0)}
                                            </div>
                                            <div style={{ fontWeight: 500 }}>{patient.name}</div>
                                        </div>
                                    </td>
                                    <td style={{ padding: '1rem 1.5rem', color: 'var(--text-muted)' }}>{patient.email}</td>
                                    <td style={{ padding: '1rem 1.5rem', color: 'var(--text-muted)' }}>
                                        {new Date(patient.createdAt).toLocaleDateString()}
                                    </td>
                                    <td style={{ padding: '1rem 1.5rem', textAlign: 'right' }}>
                                        {/* Link to patient profile? Currently no admin view for patient profile, maybe later */}
                                        <button className="btn btn-outline" style={{ fontSize: '0.8rem', padding: '0.4rem 0.8rem' }} disabled>View Details</button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}

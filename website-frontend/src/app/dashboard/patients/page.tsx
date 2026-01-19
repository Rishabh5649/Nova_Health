'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getOrganizationPatients } from '@/lib/api';

export default function PatientsPage() {
    const router = useRouter();
    const [patients, setPatients] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');

    useEffect(() => {
        loadPatients();
    }, []);

    const loadPatients = async () => {
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
                const data = await getOrganizationPatients(token, orgId, search);
                setPatients(data);
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        }
    };

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        loadPatients();
    };

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.5rem', fontWeight: 600 }}>Patients</h1>
                <form onSubmit={handleSearch} style={{ display: 'flex', gap: '0.5rem' }}>
                    <input
                        type="text"
                        placeholder="Search by name or email..."
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        style={{
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            border: '1px solid var(--border-color)',
                            width: '300px'
                        }}
                    />
                    <button type="submit" className="btn btn-primary">Search</button>
                </form>
            </div>

            {loading ? (
                <div>Loading...</div>
            ) : patients.length === 0 ? (
                <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
                    <p style={{ color: 'var(--text-muted)' }}>No patients found.</p>
                </div>
            ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.5rem' }}>
                    {patients.map((patient) => (
                        <div key={patient.id} className="card" style={{ cursor: 'pointer' }} onClick={() => router.push(`/dashboard/patients/${patient.id}`)}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
                                <div style={{ width: '50px', height: '50px', borderRadius: '50%', backgroundColor: 'var(--primary-light)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold', fontSize: '1.2rem' }}>
                                    {patient.name[0]}
                                </div>
                                <div>
                                    <h3 style={{ fontSize: '1.1rem', fontWeight: 600 }}>{patient.name}</h3>
                                    <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>{patient.email}</p>
                                </div>
                            </div>

                            <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                                <p style={{ marginBottom: '0.25rem' }}>📞 {patient.phone || 'N/A'}</p>
                                <p style={{ marginBottom: '0.25rem' }}>📅 {patient.dateOfBirth ? new Date(patient.dateOfBirth).toLocaleDateString() : 'N/A'}</p>
                                <p style={{ marginBottom: '0.25rem' }}>⚧ {patient.gender || 'N/A'}</p>
                                <p style={{ marginTop: '0.5rem', fontWeight: 500 }}>
                                    {patient._count?.appointments || 0} Appointments
                                </p>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

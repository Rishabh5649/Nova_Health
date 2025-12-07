'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getAllStaff } from '@/lib/api';

export default function DoctorsPage() {
    const router = useRouter();
    const [doctors, setDoctors] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [role, setRole] = useState('');

    useEffect(() => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');

        if (!token || !userStr) {
            router.push('/');
            return;
        }

        const user = JSON.parse(userStr);
        const orgId = user.memberships?.[0]?.organizationId;
        const userRole = user.memberships?.[0]?.role;
        setRole(userRole);

        if (orgId) {
            getAllStaff(token, orgId)
                .then((data) => {
                    // Filter for doctors
                    const docs = data.filter((m: any) => m.role === 'DOCTOR' && m.status === 'APPROVED');
                    setDoctors(docs);
                })
                .catch((err) => console.error(err))
                .finally(() => setLoading(false));
        }
    }, [router]);

    if (loading) return <div>Loading...</div>;

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h1 style={{ fontSize: '1.5rem', fontWeight: 600 }}>Doctors</h1>
                {role === 'ORG_ADMIN' && (
                    <button className="btn btn-primary" onClick={() => router.push('/dashboard/staff')}>
                        Manage Staff
                    </button>
                )}
            </div>

            {doctors.length === 0 ? (
                <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
                    <p style={{ color: 'var(--text-muted)' }}>No doctors found in this organization.</p>
                </div>
            ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.5rem' }}>
                    {doctors.map((doc) => (
                        <div key={doc.id} className="card">
                            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
                                <div style={{ width: '50px', height: '50px', borderRadius: '50%', backgroundColor: 'var(--primary-light)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold', fontSize: '1.2rem' }}>
                                    {doc.user.name[0]}
                                </div>
                                <div>
                                    <h3 style={{ fontSize: '1.1rem', fontWeight: 600 }}>{doc.user.name}</h3>
                                    <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>{doc.user.doctorProfile?.specialties?.[0] || 'General Practitioner'}</p>
                                </div>
                            </div>

                            <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
                                <p style={{ marginBottom: '0.25rem' }}>📧 {doc.user.email}</p>
                                <p style={{ marginBottom: '0.25rem' }}>📞 {doc.user.phone || 'N/A'}</p>
                                <p style={{ marginBottom: '0.25rem' }}>🎓 {doc.user.doctorProfile?.qualifications?.join(', ') || 'N/A'}</p>
                            </div>

                            {role === 'ORG_ADMIN' && (
                                <button
                                    className="btn btn-outline"
                                    style={{ width: '100%' }}
                                    onClick={() => router.push(`/dashboard/doctors/${doc.user.id}`)}
                                >
                                    Edit Profile
                                </button>
                            )}
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

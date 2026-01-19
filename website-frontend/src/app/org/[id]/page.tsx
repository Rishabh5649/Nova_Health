'use client';

import { useEffect, useState, use } from 'react';
import Link from 'next/link';
import { getPublicOrganization } from '@/lib/api';

export default function PublicOrgPage({ params }: { params: Promise<{ id: string }> }) {
    const [org, setOrg] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [selectedDoctor, setSelectedDoctor] = useState<any>(null);

    // Unwrap params
    const resolvedParams = use(params);

    useEffect(() => {
        getPublicOrganization(resolvedParams.id)
            .then(data => {
                setOrg(data);
                setLoading(false);
            })
            .catch(err => {
                console.error(err);
                setError('Failed to load organization details');
                setLoading(false);
            });
    }, [resolvedParams.id]);

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-body">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
        );
    }

    if (error || !org) {
        return (
            <div className="min-h-screen flex flex-col items-center justify-center bg-body p-4">
                <h1 className="text-2xl font-bold text-danger mb-4">Error</h1>
                <p className="text-muted">{error || 'Organization not found'}</p>
                <Link href="/" className="btn btn-primary mt-6">Go Back</Link>
            </div>
        );
    }

    const doctors = org.members?.filter((m: any) => m.role === 'DOCTOR').map((m: any) => ({
        ...m.user,
        specialization: m.user.doctorProfile?.specialties?.[0] || 'General Practitioner',
        experience: m.user.doctorProfile?.yearsExperience || 0,
        baseFee: m.user.doctorProfile?.baseFee || m.user.doctorProfile?.fees || 0,
        qualifications: m.user.doctorProfile?.qualifications || [],
        bio: m.user.doctorProfile?.bio || 'No biography available.',
    })) || [];



    return (
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
            {/* Navbar */}
            <nav className="glass" style={{ position: 'fixed', top: 0, left: 0, right: 0, zIndex: 50, padding: '1rem 0' }}>
                <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: 'var(--primary-gradient)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold' }}>
                            {org.name.substring(0, 2).toUpperCase()}
                        </div>
                        <span style={{ fontSize: '1.25rem', fontWeight: 700, letterSpacing: '-0.025em' }}>{org.name}</span>
                    </div>
                    <div className="hidden-mobile" style={{ display: 'flex', gap: '2rem', alignItems: 'center' }}>
                        <a href="#doctors" className="nav-item-public" style={{ fontWeight: 500, color: 'var(--text-main)', cursor: 'pointer' }}>Doctors</a>
                        <a href="#about" className="nav-item-public" style={{ fontWeight: 500, color: 'var(--text-main)', cursor: 'pointer' }}>About</a>
                        <a href="#contact" className="nav-item-public" style={{ fontWeight: 500, color: 'var(--text-main)', cursor: 'pointer' }}>Contact</a>
                        <Link href="/" className="btn btn-outline" style={{ padding: '0.5rem 1.25rem' }}>Staff Login</Link>
                    </div>
                </div>
            </nav>

            {/* Hero Section */}
            <header style={{
                paddingTop: '8rem',
                paddingBottom: '5rem',
                position: 'relative',
                overflow: 'hidden'
            }}>
                <div className="container" style={{ position: 'relative', zIndex: 10 }}>
                    <div style={{ maxWidth: '800px', margin: '0 auto', textAlign: 'center' }} className="animate-fade-in">
                        <span className="badge badge-primary" style={{ marginBottom: '1.5rem', display: 'inline-block' }}>
                            Premier Healthcare Provider
                        </span>
                        <h1 className="title-gradient" style={{
                            fontSize: '4rem',
                            fontWeight: 800,
                            lineHeight: 1.1,
                            marginBottom: '1.5rem',
                            letterSpacing: '-0.03em'
                        }}>
                            World-Class Care <br /> at {org.name}
                        </h1>
                        <p style={{
                            fontSize: '1.25rem',
                            color: 'var(--text-muted)',
                            marginBottom: '2.5rem',
                            lineHeight: 1.6
                        }}>
                            Experience healthcare reimagined with our team of expert specialists and state-of-the-art facilities. Your health journey starts here.
                        </p>
                        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
                            <a href="#doctors" className="btn btn-primary" style={{ padding: '1rem 2.5rem', fontSize: '1.1rem' }}>
                                Find a Doctor
                            </a>
                            <a href="#contact" className="btn btn-outline" style={{ padding: '1rem 2.5rem', fontSize: '1.1rem', background: 'rgba(255,255,255,0.5)' }}>
                                Contact Us
                            </a>
                        </div>
                    </div>
                </div>

                {/* Decorative Background Elements */}
                <div style={{
                    position: 'absolute',
                    top: '20%',
                    left: '5%',
                    width: '300px',
                    height: '300px',
                    background: 'radial-gradient(circle, rgba(59, 130, 246, 0.1) 0%, rgba(0,0,0,0) 70%)',
                    borderRadius: '50%',
                    zIndex: 0
                }} />
                <div style={{
                    position: 'absolute',
                    bottom: '10%',
                    right: '5%',
                    width: '400px',
                    height: '400px',
                    background: 'radial-gradient(circle, rgba(16, 185, 129, 0.1) 0%, rgba(0,0,0,0) 70%)',
                    borderRadius: '50%',
                    zIndex: 0
                }} />
            </header>

            {/* Stats Section */}
            <section style={{ padding: '0 0 5rem' }}>
                <div className="container">
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '2rem' }}>
                        <div className="glass-card" style={{ padding: '2rem', borderRadius: '1.5rem', textAlign: 'center' }}>
                            <h3 className="title-gradient" style={{ fontSize: '3rem', fontWeight: 800, marginBottom: '0.5rem' }}>{doctors.length}+</h3>
                            <p style={{ fontWeight: 600, color: 'var(--text-muted)' }}>Expert Doctors</p>
                        </div>
                        <div className="glass-card" style={{ padding: '2rem', borderRadius: '1.5rem', textAlign: 'center' }}>
                            <h3 className="title-gradient" style={{ fontSize: '3rem', fontWeight: 800, marginBottom: '0.5rem' }}>24/7</h3>
                            <p style={{ fontWeight: 600, color: 'var(--text-muted)' }}>Emergency Care</p>
                        </div>
                        <div className="glass-card" style={{ padding: '2rem', borderRadius: '1.5rem', textAlign: 'center' }}>
                            <h3 className="title-gradient" style={{ fontSize: '3rem', fontWeight: 800, marginBottom: '0.5rem' }}>10k+</h3>
                            <p style={{ fontWeight: 600, color: 'var(--text-muted)' }}>Happy Patients</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* Doctors Grid */}
            <section id="doctors" style={{ padding: '5rem 0', background: 'var(--bg-secondary)' }}>
                <div className="container">
                    <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
                        <h2 style={{ fontSize: '2.5rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--text-main)' }}>Meet Our Specialists</h2>
                        <p style={{ color: 'var(--text-muted)', fontSize: '1.1rem' }}>Expert care from leading medical professionals</p>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '2rem' }}>
                        {doctors.map((doctor: any) => (
                            <div key={doctor.id} className="card" style={{
                                padding: '0',
                                overflow: 'hidden',
                                border: 'none',
                                transition: 'all 0.3s ease'
                            }}>
                                <div style={{
                                    height: '120px',
                                    background: 'linear-gradient(135deg, #e0e7ff 0%, #fae8ff 100%)',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}>
                                    <div style={{
                                        width: '80px',
                                        height: '80px',
                                        borderRadius: '50%',
                                        background: 'white',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        fontSize: '2rem',
                                        fontWeight: 'bold',
                                        color: 'var(--primary)',
                                        boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                                        transform: 'translateY(40px)'
                                    }}>
                                        {doctor.name.charAt(0)}
                                    </div>
                                </div>
                                <div style={{ padding: '3rem 1.5rem 1.5rem', textAlign: 'center' }}>
                                    <h3 style={{ fontSize: '1.25rem', fontWeight: 600, marginBottom: '0.25rem' }}>
                                        {doctor.name.startsWith('Dr.') ? doctor.name : `Dr. ${doctor.name}`}
                                    </h3>
                                    <p style={{ color: 'var(--primary)', fontSize: '0.9rem', fontWeight: 500, marginBottom: '1rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                                        {doctor.specialization}
                                    </p>
                                    <div style={{ display: 'flex', justifyContent: 'center', gap: '1rem', marginBottom: '1.5rem', fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                                        <span>{doctor.experience} Years Exp.</span>
                                        <span>•</span>
                                        <span>₹{doctor.baseFee} Fees</span>
                                    </div>
                                    <button
                                        className="btn btn-outline"
                                        style={{ width: '100%', borderRadius: 'var(--radius)' }}
                                        onClick={() => setSelectedDoctor(doctor)}
                                    >
                                        View Profile
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* About/Contact */}
            <section id="contact" style={{ padding: '5rem 0' }}>
                <div className="container">
                    <div className="glass" style={{ padding: '3rem', borderRadius: '2rem', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '4rem', alignItems: 'center' }}>
                        <div>
                            <h2 style={{ fontSize: '2.5rem', fontWeight: 700, marginBottom: '1.5rem' }}>Visit Us</h2>
                            <p style={{ fontSize: '1.1rem', color: 'var(--text-muted)', marginBottom: '2rem' }}>
                                We are conveniently located in the heart of the city. Visit us for all your healthcare needs.
                            </p>

                            <div style={{ marginBottom: '2rem' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
                                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'var(--bg-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}>📍</div>
                                    <div>
                                        <div style={{ fontWeight: 600 }}>Address</div>
                                        <div style={{ color: 'var(--text-muted)' }}>{org.address || '123 Health Ave, Medical City'}</div>
                                    </div>
                                </div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
                                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'var(--bg-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}>📞</div>
                                    <div>
                                        <div style={{ fontWeight: 600 }}>Phone</div>
                                        <div style={{ color: 'var(--text-muted)' }}>{org.contactPhone || '+1 (555) 123-4567'}</div>
                                    </div>
                                </div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                    <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'var(--bg-secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}>✉️</div>
                                    <div>
                                        <div style={{ fontWeight: 600 }}>Email</div>
                                        <div style={{ color: 'var(--text-muted)' }}>{org.contactEmail || 'info@hospital.com'}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div style={{ background: 'var(--bg-card)', padding: '2rem', borderRadius: '1.5rem', boxShadow: 'var(--shadow-lg)' }}>
                            <h3 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: '1.5rem' }}>Get in Touch</h3>
                            <form style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                                <input type="text" placeholder="Your Name" className="input" />
                                <input type="email" placeholder="Your Email" className="input" />
                                <textarea placeholder="Message" className="input" style={{ minHeight: '120px', resize: 'vertical' }}></textarea>
                                <button type="button" className="btn btn-primary" style={{ width: '100%' }}>Send Message</button>
                            </form>
                        </div>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer style={{ background: 'var(--secondary)', color: 'white', padding: '3rem 0' }}>
                <div className="container" style={{ textAlign: 'center' }}>
                    <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1rem' }}>{org.name}</h3>
                    <p style={{ color: '#94a3b8', marginBottom: '2rem' }}>Providing excellence in healthcare since 2000.</p>
                    <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '2rem', fontSize: '0.875rem', color: '#64748b' }}>
                        © {new Date().getFullYear()} {org.name}. All rights reserved.
                    </div>
                </div>
            </footer>

            {/* Doctor Profile Modal */}
            {selectedDoctor && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    background: 'rgba(0,0,0,0.6)',
                    backdropFilter: 'blur(4px)',
                    zIndex: 100,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '1rem'
                }} onClick={() => setSelectedDoctor(null)}>
                    <div
                        className="glass-card"
                        style={{
                            width: '100%',
                            maxWidth: '600px',
                            padding: '0',
                            borderRadius: '1.5rem',
                            overflow: 'hidden',
                            position: 'relative'
                        }}
                        onClick={e => e.stopPropagation()}
                    >
                        <button
                            onClick={() => setSelectedDoctor(null)}
                            style={{
                                position: 'absolute',
                                top: '1rem',
                                right: '1rem',
                                background: 'rgba(0,0,0,0.3)',
                                color: 'white',
                                border: 'none',
                                width: '30px',
                                height: '30px',
                                borderRadius: '50%',
                                cursor: 'pointer',
                                zIndex: 10,
                                fontSize: '1.2rem',
                                display: 'flex', alignItems: 'center', justifyContent: 'center'
                            }}
                        >
                            ×
                        </button>

                        <div style={{ height: '150px', background: 'var(--primary-gradient)', position: 'relative' }}>
                            <div style={{
                                position: 'absolute',
                                bottom: '-50px',
                                left: '2rem',
                                width: '100px',
                                height: '100px',
                                borderRadius: '50%',
                                background: 'white',
                                border: '4px solid white',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                fontSize: '2.5rem',
                                fontWeight: 'bold',
                                color: 'var(--primary)',
                                boxShadow: 'var(--shadow-md)'
                            }}>
                                {selectedDoctor.name.charAt(0)}
                            </div>
                        </div>

                        <div style={{ padding: '4rem 2rem 2rem' }}>
                            <h2 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                                {selectedDoctor.name.startsWith('Dr.') ? selectedDoctor.name : `Dr. ${selectedDoctor.name}`}
                            </h2>
                            <p style={{ color: 'var(--primary)', fontWeight: 600, marginBottom: '1.5rem' }}>
                                {selectedDoctor.specialization}
                            </p>

                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '2rem' }}>
                                <div style={{ background: 'var(--bg-secondary)', padding: '1rem', borderRadius: '1rem' }}>
                                    <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>Experience</div>
                                    <div style={{ fontSize: '1.1rem', fontWeight: 600 }}>{selectedDoctor.experience} Years</div>
                                </div>
                                <div style={{ background: 'var(--bg-secondary)', padding: '1rem', borderRadius: '1rem' }}>
                                    <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>Fees</div>
                                    <div style={{ fontSize: '1.1rem', fontWeight: 600 }}>₹{selectedDoctor.baseFee}</div>
                                </div>
                            </div>

                            <div style={{ marginBottom: '2rem' }}>
                                <h4 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.5rem' }}>Biography</h4>
                                <p style={{ color: 'var(--text-muted)', lineHeight: 1.6 }}>
                                    {selectedDoctor.bio}
                                </p>
                            </div>

                            {selectedDoctor.qualifications && selectedDoctor.qualifications.length > 0 && (
                                <div style={{ marginBottom: '2rem' }}>
                                    <h4 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.5rem' }}>Qualifications</h4>
                                    <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                                        {selectedDoctor.qualifications.map((q: string, i: number) => (
                                            <span key={i} className="badge badge-default">{q}</span>
                                        ))}
                                    </div>
                                </div>
                            )}

                            <button className="btn btn-primary" style={{ width: '100%' }} onClick={() => setSelectedDoctor(null)}>
                                Close Profile
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

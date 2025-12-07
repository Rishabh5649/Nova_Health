'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';

export default function PrescriptionPage() {
    const router = useRouter();
    const params = useParams();
    const id = params.id as string;

    const [appointment, setAppointment] = useState<any>(null);
    const [prescription, setPrescription] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const [showForm, setShowForm] = useState(false);
    const [editMode, setEditMode] = useState(false);

    // Form state
    const [diagnosis, setDiagnosis] = useState('');
    const [notes, setNotes] = useState('');
    const [medications, setMedications] = useState([{ name: '', dosage: '', frequency: '', duration: '', instruction: '' }]);

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
            const presRes = await fetch(`http://127.0.0.1:3000/prescriptions/appointment/${id}`, {
                headers: { 'Authorization': `Bearer ${token}` },
            });

            if (presRes.ok) {
                const text = await presRes.text();
                if (text) {
                    try {
                        const presData = JSON.parse(text);
                        setPrescription(presData);
                        setDiagnosis(presData.diagnosis || '');
                        setNotes(presData.notes || '');
                        setMedications(presData.medications && presData.medications.length > 0
                            ? presData.medications
                            : [{ name: '', dosage: '', frequency: '', duration: '', instruction: '' }]);
                    } catch (e) {
                        console.warn('Failed to parse prescription JSON', e);
                    }
                }
            }

            const apptRes = await fetch('http://127.0.0.1:3000/appointments', {
                headers: { 'Authorization': `Bearer ${token}` },
            });

            if (apptRes.ok) {
                const allAppts = await apptRes.json();
                const apptData = allAppts.find((a: any) => a.id === id);
                setAppointment(apptData);
            }

        } catch (err) {
            console.error('Error loading data:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleAddMedication = () => {
        setMedications([...medications, { name: '', dosage: '', frequency: '', duration: '', instruction: '' }]);
    };

    const handleMedicationChange = (index: number, field: string, value: string) => {
        const newMeds = [...medications];
        (newMeds as any)[index][field] = value;
        setMedications(newMeds);
    };

    const handleRemoveMedication = (index: number) => {
        const newMeds = medications.filter((_, i) => i !== index);
        setMedications(newMeds.length > 0 ? newMeds : [{ name: '', dosage: '', frequency: '', duration: '', instruction: '' }]);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!appointment) return;

        setSubmitting(true);
        const token = localStorage.getItem('token');

        try {
            const payload = {
                appointmentId: appointment.id,
                patientId: appointment.patientId,
                diagnosis,
                notes,
                medications: medications.filter(m => m.name.trim() !== '')
            };

            const method = prescription ? 'PUT' : 'POST';
            const url = prescription
                ? `http://127.0.0.1:3000/prescriptions/${prescription.id}`
                : 'http://127.0.0.1:3000/prescriptions';

            const res = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            if (!res.ok) {
                throw new Error('Failed to save prescription');
            }

            alert(prescription ? 'Prescription updated successfully' : 'Prescription created successfully');
            await loadData();
            setShowForm(false);
            setEditMode(false);
        } catch (err) {
            console.error(err);
            alert('Failed to save prescription');
        } finally {
            setSubmitting(false);
        }
    };

    if (loading) return <div className="p-8" style={{ backgroundColor: '#111827', minHeight: '100vh', color: 'white' }}>Loading...</div>;
    if (!appointment) return <div className="p-8" style={{ backgroundColor: '#111827', minHeight: '100vh', color: 'white' }}>Appointment not found</div>;

    return (
        <div className="min-h-screen p-8" style={{ backgroundColor: '#111827' }}>
            <div className="max-w-6xl mx-auto">
                <div className="mb-8">
                    <Link href={`/dashboard/appointments/${id}`} style={{ color: '#60A5FA' }} className="text-sm font-medium hover:underline">
                        ← Back to Appointment
                    </Link>
                </div>

                <div className="mb-8">
                    <h1 className="text-3xl font-bold text-white mb-2">Prescription</h1>
                    <p style={{ color: '#9CA3AF' }}>
                        Patient: {appointment.patient?.name} • {new Date(appointment.scheduledAt).toLocaleDateString()}
                    </p>
                </div>

                {/* Existing Prescription */}
                {!showForm && prescription && (
                    <div className="space-y-6">
                        <div style={{ backgroundColor: '#1F2937', borderColor: '#374151' }} className="rounded-lg border p-6">
                            <h3 className="text-lg font-bold text-white mb-4">Current Prescription</h3>

                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1" style={{ color: '#9CA3AF' }}>Diagnosis</label>
                                    <div style={{ backgroundColor: '#374151' }} className="rounded-lg p-3 text-white">{prescription.diagnosis}</div>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium mb-1" style={{ color: '#9CA3AF' }}>Clinical Notes</label>
                                    <div style={{ backgroundColor: '#374151' }} className="rounded-lg p-3 text-white whitespace-pre-wrap">
                                        {prescription.notes || 'No notes'}
                                    </div>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium mb-1" style={{ color: '#9CA3AF' }}>Prescribed By</label>
                                    <div style={{ backgroundColor: '#374151' }} className="rounded-lg p-3 text-white">
                                        {prescription.doctor?.name || appointment.doctor?.name || 'Unknown Doctor'}
                                    </div>
                                </div>

                                {prescription.medications && prescription.medications.length > 0 && (
                                    <div>
                                        <label className="block text-sm font-medium mb-2" style={{ color: '#9CA3AF' }}>Medications</label>
                                        <div className="space-y-3">
                                            {prescription.medications.map((med: any, i: number) => (
                                                <div key={i} style={{ backgroundColor: '#374151' }} className="rounded-lg p-4">
                                                    <div className="font-semibold text-white mb-2">Medication {i + 1}: {med.name}</div>
                                                    <div className="text-sm space-y-1" style={{ color: '#D1D5DB' }}>
                                                        <p>Dosage: {med.dosage}</p>
                                                        <p>Frequency: {med.frequency}</p>
                                                        <p>Duration: {med.duration}</p>
                                                        {med.instruction && <p>Instructions: {med.instruction}</p>}
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="flex justify-center">
                            <button
                                onClick={() => setShowForm(true)}
                                style={{ backgroundColor: '#2563EB' }}
                                className="px-8 py-3 text-white rounded-lg font-medium hover:opacity-90 transition-opacity"
                            >
                                Edit Prescription
                            </button>
                        </div>
                    </div>
                )}

                {/* No Prescription */}
                {!showForm && !prescription && (
                    <div style={{ backgroundColor: '#1F2937', borderColor: '#374151' }} className="rounded-lg border p-12 text-center">
                        <p style={{ color: '#9CA3AF' }} className="text-lg mb-6">No prescription found</p>
                        <button
                            onClick={() => setShowForm(true)}
                            style={{ backgroundColor: '#9333EA' }}
                            className="px-8 py-3 text-white rounded-lg font-medium hover:opacity-90 transition-opacity"
                        >
                            Create Prescription
                        </button>
                    </div>
                )}

                {/* Form */}
                {showForm && (
                    <form onSubmit={handleSubmit} className="space-y-8">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div style={{ backgroundColor: '#1F2937', borderColor: '#374151' }} className="rounded-lg border p-6">
                                <label className="block text-sm font-semibold text-white mb-3">
                                    Diagnosis <span style={{ color: '#F87171' }}>*</span>
                                </label>
                                <input
                                    type="text"
                                    required
                                    placeholder="Enter diagnosis"
                                    style={{ backgroundColor: '#374151', borderColor: '#4B5563', color: 'white' }}
                                    className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                    value={diagnosis}
                                    onChange={e => setDiagnosis(e.target.value)}
                                />
                            </div>

                            <div style={{ backgroundColor: '#1F2937', borderColor: '#374151' }} className="rounded-lg border p-6">
                                <label className="block text-sm font-semibold text-white mb-3">
                                    Clinical Notes
                                </label>
                                <textarea
                                    placeholder="Add treatment notes..."
                                    style={{ backgroundColor: '#374151', borderColor: '#4B5563', color: 'white' }}
                                    className="w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                                    rows={3}
                                    value={notes}
                                    onChange={e => setNotes(e.target.value)}
                                />
                            </div>
                        </div>

                        <div style={{ backgroundColor: '#1F2937', borderColor: '#374151' }} className="rounded-lg border p-6">
                            <div className="flex items-center justify-between mb-6">
                                <label className="text-lg font-semibold text-white">Medications</label>
                                <div className="flex gap-3">
                                    <button
                                        type="button"
                                        onClick={handleAddMedication}
                                        style={{ backgroundColor: '#16A34A' }}
                                        className="px-5 py-2 text-white rounded-lg font-medium text-sm hover:opacity-90 transition-opacity"
                                    >
                                        + Add Medication
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => setEditMode(!editMode)}
                                        style={{ backgroundColor: '#DC2626' }}
                                        className="px-5 py-2 text-white rounded-lg font-medium text-sm hover:opacity-90 transition-opacity"
                                    >
                                        {editMode ? 'Done Editing' : 'Edit Medications'}
                                    </button>
                                </div>
                            </div>

                            <div className="space-y-5">
                                {medications.map((med, index) => (
                                    <div key={index} style={{ backgroundColor: '#1F2937', borderColor: '#4B5563' }} className="border rounded-lg p-6">
                                        <div className="flex items-center justify-between mb-5">
                                            <span className="text-sm font-bold px-3 py-1.5 rounded" style={{ color: '#D1D5DB', backgroundColor: '#374151' }}>
                                                MEDICATION {index + 1}
                                            </span>
                                            {editMode && medications.length > 1 && (
                                                <button
                                                    type="button"
                                                    onClick={() => handleRemoveMedication(index)}
                                                    style={{ backgroundColor: '#DC2626' }}
                                                    className="px-4 py-1.5 text-white rounded-lg text-sm font-medium hover:opacity-90 transition-opacity"
                                                >
                                                    Delete
                                                </button>
                                            )}
                                        </div>

                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                                            <div>
                                                <label className="block text-xs font-medium mb-2" style={{ color: '#D1D5DB' }}>
                                                    Medicine Name <span style={{ color: '#F87171' }}>*</span>
                                                </label>
                                                <input
                                                    placeholder="e.g., Amoxicillin"
                                                    style={{ backgroundColor: '#374151', borderColor: '#4B5563', color: 'white' }}
                                                    className="w-full px-4 py-3 border rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                                    value={med.name}
                                                    onChange={e => handleMedicationChange(index, 'name', e.target.value)}
                                                    required
                                                />
                                            </div>
                                            <div>
                                                <label className="block text-xs font-medium mb-2" style={{ color: '#D1D5DB' }}>
                                                    Dosage <span style={{ color: '#F87171' }}>*</span>
                                                </label>
                                                <input
                                                    placeholder="e.g., 500mg"
                                                    style={{ backgroundColor: '#374151', borderColor: '#4B5563', color: 'white' }}
                                                    className="w-full px-4 py-3 border rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                                    value={med.dosage}
                                                    onChange={e => handleMedicationChange(index, 'dosage', e.target.value)}
                                                    required
                                                />
                                            </div>
                                            <div>
                                                <label className="block text-xs font-medium mb-2" style={{ color: '#D1D5DB' }}>
                                                    Frequency <span style={{ color: '#F87171' }}>*</span>
                                                </label>
                                                <input
                                                    placeholder="e.g., 2x daily"
                                                    style={{ backgroundColor: '#374151', borderColor: '#4B5563', color: 'white' }}
                                                    className="w-full px-4 py-3 border rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                                    value={med.frequency}
                                                    onChange={e => handleMedicationChange(index, 'frequency', e.target.value)}
                                                    required
                                                />
                                            </div>
                                            <div>
                                                <label className="block text-xs font-medium mb-2" style={{ color: '#D1D5DB' }}>
                                                    Duration <span style={{ color: '#F87171' }}>*</span>
                                                </label>
                                                <input
                                                    placeholder="e.g., 7 days"
                                                    style={{ backgroundColor: '#374151', borderColor: '#4B5563', color: 'white' }}
                                                    className="w-full px-4 py-3 border rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                                    value={med.duration}
                                                    onChange={e => handleMedicationChange(index, 'duration', e.target.value)}
                                                    required
                                                />
                                            </div>
                                            <div className="md:col-span-2">
                                                <label className="block text-xs font-medium mb-2" style={{ color: '#D1D5DB' }}>
                                                    Special Instructions
                                                </label>
                                                <input
                                                    placeholder="e.g., Take after meals"
                                                    style={{ backgroundColor: '#374151', borderColor: '#4B5563', color: 'white' }}
                                                    className="w-full px-4 py-3 border rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                                    value={med.instruction}
                                                    onChange={e => handleMedicationChange(index, 'instruction', e.target.value)}
                                                />
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        <div className="flex gap-4 pt-4">
                            <button
                                type="button"
                                onClick={() => {
                                    setShowForm(false);
                                    setEditMode(false);
                                    if (prescription) {
                                        setDiagnosis(prescription.diagnosis || '');
                                        setNotes(prescription.notes || '');
                                        setMedications(prescription.medications || [{ name: '', dosage: '', frequency: '', duration: '', instruction: '' }]);
                                    }
                                }}
                                style={{ backgroundColor: '#374151' }}
                                className="flex-1 px-6 py-3 text-white rounded-lg font-medium text-center hover:opacity-90 transition-opacity"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                disabled={submitting}
                                style={{ backgroundColor: '#2563EB' }}
                                className="flex-1 px-6 py-3 text-white rounded-lg font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
                            >
                                {submitting ? 'Saving...' : (prescription ? 'Update Prescription' : 'Save Prescription')}
                            </button>
                        </div>
                    </form>
                )}
            </div>
        </div>
    );
}

import { PrismaClient, Role, OrgRole, AppointmentStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    // 0. Create Super Admin
    const superAdminPassword = await bcrypt.hash('ri.shabh5649', 10);
    const superAdmin = await prisma.user.upsert({
        where: { email: 'rishabhsingh30705@gmail.com' },
        update: {},
        create: {
            name: 'Rishabh Singh',
            email: 'rishabhsingh30705@gmail.com',
            password: superAdminPassword,
            role: Role.ADMIN,
        },
    });
    console.log('Created Super Admin:', superAdmin.email);

    // 1. Create Default Organization with Settings
    const org = await prisma.organization.upsert({
        where: { id: '781d5309-e030-4e7e-9087-17573ea1c4d9' }, // Use a fixed ID for the seed org to ensure upsert works reliably or match by unique constraint if one exists (name is not unique usually)
        // Actually, name is not unique in schema usually. Let's assume we want to find by name if possible, but prisma upsert requires unique.
        // Let's check schema first to see if name is unique. If not, we might need findFirst -> update/create.
        // For now, let's try findFirst logic manually or just use a fixed UUID for the seed.
        update: {},
        create: {
            id: '781d5309-e030-4e7e-9087-17573ea1c4d9', // Fixed ID for checking
            name: 'City Hospital',
            type: 'Hospital',
            address: '123 Health St, Wellness City',
            contactEmail: 'admin@cityhospital.com',
            contactPhone: '+1234567890',
            feeControlMode: 'doctor_controlled',
            yearEstablished: 1995,
            latitude: 40.7128,
            longitude: -74.0060,
            branches: ['Downtown Clinic', 'Westside Center'],
            settings: {
                create: {
                    enableReceptionists: true,
                    allowPatientBooking: true,
                    requireApprovalForDoctors: true,
                    requireApprovalForReceptionists: true,
                    autoApproveFollowUps: true,
                },
            },
        },
    });

    console.log('Created Organization:', org.name);

    // 2. Create Org Admin User
    const adminPassword = await bcrypt.hash('admin123', 10);
    const admin = await prisma.user.create({
        data: {
            name: 'Jane Doe',
            email: 'admin@cityhospital.com',
            password: adminPassword,
            role: Role.DOCTOR, // Changed to DOCTOR to act as Org Admin, not Super Admin
        },
    });


    // Create admin's approved membership
    await prisma.organizationMembership.create({
        data: {
            userId: admin.id,
            organizationId: org.id,
            role: OrgRole.ORG_ADMIN,
            status: 'APPROVED',
            approvedBy: admin.id, // Self-approved
            approvedAt: new Date(),
        },
    });

    console.log('Created Admin:', admin.email);

    // 3. Create Doctors
    const docPassword = await bcrypt.hash('doc123', 10);

    const doctor1 = await prisma.user.create({
        data: {
            name: 'Dr. Sarah Smith',
            email: 'sarah@cityhospital.com',
            password: docPassword,
            role: Role.DOCTOR,
            phone: '+1234567891',
            doctorProfile: {
                create: {
                    name: 'Dr. Sarah Smith',
                    specialties: ['Cardiology', 'General Medicine'],
                    qualifications: ['MBBS', 'MD'],
                    yearsExperience: 8,
                    bio: 'Experienced cardiologist specializing in heart disease prevention and treatment.',
                    verificationStatus: 'APPROVED',
                    baseFee: 800,
                    followUpDays: 7,
                    followUpFee: 0,
                    fees: 800,
                },
            },
        },
    });

    // Create approved membership for doctor1
    await prisma.organizationMembership.create({
        data: {
            userId: doctor1.id,
            organizationId: org.id,
            role: OrgRole.DOCTOR,
            status: 'APPROVED',
            approvedBy: admin.id,
            approvedAt: new Date(),
        },
    });

    const doctor2 = await prisma.user.create({
        data: {
            name: 'Dr. Michael Chen',
            email: 'michael@cityhospital.com',
            password: docPassword,
            role: Role.DOCTOR,
            phone: '+1234567892',
            doctorProfile: {
                create: {
                    name: 'Dr. Michael Chen',
                    specialties: ['Pediatrics', 'Family Medicine'],
                    qualifications: ['MBBS', 'DCH'],
                    yearsExperience: 12,
                    bio: 'Pediatric specialist with extensive experience in child healthcare.',
                    verificationStatus: 'APPROVED',
                    baseFee: 600,
                    followUpDays: 14,
                    followUpFee: 200,
                    fees: 600,
                },
            },
        },
    });

    // Create approved membership for doctor2
    await prisma.organizationMembership.create({
        data: {
            userId: doctor2.id,
            organizationId: org.id,
            role: OrgRole.DOCTOR,
            status: 'APPROVED',
            approvedBy: admin.id,
            approvedAt: new Date(),
        },
    });

    console.log('Created Doctors:', doctor1.email, doctor2.email);

    // 4. Create Receptionist (for testing)
    const receptionistPassword = await bcrypt.hash('recep123', 10);
    const receptionist = await prisma.user.create({
        data: {
            name: 'Mary Receptionist',
            email: 'mary@cityhospital.com',
            password: receptionistPassword,
            role: Role.DOCTOR, // Global role must not be ADMIN
            phone: '+1234567896',
        },
    });

    // Create approved membership for receptionist
    await prisma.organizationMembership.create({
        data: {
            userId: receptionist.id,
            organizationId: org.id,
            role: OrgRole.RECEPTIONIST,
            status: 'APPROVED',
            approvedBy: admin.id,
            approvedAt: new Date(),
        },
    });

    console.log('Created Receptionist:', receptionist.email);

    // 5. Create Patients
    const patientPassword = await bcrypt.hash('patient123', 10);

    const patient1 = await prisma.user.create({
        data: {
            name: 'John Patient',
            email: 'john@example.com',
            password: patientPassword,
            role: Role.PATIENT,
            phone: '+1234567893',
            patientProfile: {
                create: {
                    name: 'John Patient',
                    dob: new Date('1990-01-01'),
                    gender: 'Male',
                    bloodGroup: 'O+',
                },
            },
        },
    });

    const patient2 = await prisma.user.create({
        data: {
            name: 'Emily Johnson',
            email: 'emily@example.com',
            password: patientPassword,
            role: Role.PATIENT,
            phone: '+1234567894',
            patientProfile: {
                create: {
                    name: 'Emily Johnson',
                    dob: new Date('1985-05-15'),
                    gender: 'Female',
                    bloodGroup: 'A+',
                },
            },
        },
    });

    const patient3 = await prisma.user.create({
        data: {
            name: 'Robert Williams',
            email: 'robert@example.com',
            password: patientPassword,
            role: Role.PATIENT,
            phone: '+1234567895',
            patientProfile: {
                create: {
                    name: 'Robert Williams',
                    dob: new Date('1978-11-20'),
                    gender: 'Male',
                    bloodGroup: 'B+',
                },
            },
        },
    });

    console.log('Created Patients:', patient1.email, patient2.email, patient3.email);

    // 5. Create Appointments with various statuses
    const now = new Date();

    // Completed appointment with prescription (Parent Appointment)
    const completedAppt = await prisma.appointment.create({
        data: {
            organizationId: org.id,
            doctorId: doctor1.id,
            patientId: patient1.id,
            scheduledAt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
            reason: 'Chest pain and shortness of breath',
            status: AppointmentStatus.COMPLETED,
            chargedFee: 800,    // New field
            isFollowUp: false,  // New field
        },
    });

    // Follow-up appointment linked to the completed one
    const followUpAppt = await prisma.appointment.create({
        data: {
            organizationId: org.id,
            doctorId: doctor1.id,
            patientId: patient1.id,
            scheduledAt: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
            reason: 'Follow-up on chest pain',
            status: AppointmentStatus.COMPLETED,
            chargedFee: 0,              // Free follow-up
            isFollowUp: true,           // It is a follow-up
            followUpParentId: completedAppt.id, // Linked to parent
        },
    });

    // Create prescription for completed appointment
    await prisma.prescription.create({
        data: {
            appointmentId: completedAppt.id,
            patientId: patient1.id,
            doctorId: doctor1.id,
            diagnosis: 'Mild hypertension',
            notes: 'Patient advised to monitor blood pressure regularly and maintain healthy lifestyle.',
            medications: {
                create: [
                    {
                        name: 'Amlodipine',
                        dosage: '5mg',
                        frequency: 'Once daily',
                        duration: '30 days',
                        instruction: 'Take in the morning with food',
                    },
                    {
                        name: 'Aspirin',
                        dosage: '75mg',
                        frequency: 'Once daily',
                        duration: '30 days',
                        instruction: 'Take after dinner',
                    },
                ],
            },
        },
    });

    // Confirmed appointment (upcoming)
    const confirmedAppt = await prisma.appointment.create({
        data: {
            organizationId: org.id,
            doctorId: doctor1.id,
            patientId: patient2.id,
            scheduledAt: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
            reason: 'Regular checkup',
            status: AppointmentStatus.CONFIRMED,
            chargedFee: 800,
            isFollowUp: false,
        },
    });

    // Pending appointment
    const pendingAppt = await prisma.appointment.create({
        data: {
            organizationId: org.id,
            doctorId: doctor2.id,
            patientId: patient3.id,
            scheduledAt: new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000), // 5 days from now
            reason: 'Fever and cough',
            status: AppointmentStatus.PENDING,
            chargedFee: 600,
            isFollowUp: false,
        },
    });

    // Another confirmed appointment for reschedule testing
    const rescheduleAppt = await prisma.appointment.create({
        data: {
            organizationId: org.id,
            doctorId: doctor2.id,
            patientId: patient1.id,
            scheduledAt: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
            reason: 'Follow-up consultation',
            status: AppointmentStatus.CONFIRMED,
            chargedFee: 200, // Dr. Chen charges for follow-ups
            isFollowUp: true, // Manually marked as follow-up for testing
        },
    });

    console.log('Created Appointments:', completedAppt.id, followUpAppt.id, confirmedAppt.id, pendingAppt.id, rescheduleAppt.id);

    // 6. Create Reschedule Request
    await prisma.rescheduleRequest.create({
        data: {
            appointmentId: rescheduleAppt.id,
            requestedById: patient1.id,
            requestedDateTime: new Date(now.getTime() + 4 * 24 * 60 * 60 * 1000), // 4 days from now
            reason: 'Unable to attend due to work commitment',
            status: 'PENDING',
        },
    });

    console.log('Created Reschedule Request');

    // 7. Create Review for completed appointment
    await prisma.review.create({
        data: {
            appointmentId: completedAppt.id,
            patientId: patient1.id,
            doctorId: doctor1.id,
            rating: 5,
            comment: 'Excellent doctor! Very thorough and caring. Highly recommend.',
        },
    });

    console.log('Created Review');

    // 8. Create Medical History
    await prisma.medicalHistory.create({
        data: {
            patientId: patient1.id,
            diagnosis: 'Hypertension',
            details: 'Diagnosed with stage 1 hypertension. Currently on medication.',
            recordedAt: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
        },
    });

    await prisma.medicalHistory.create({
        data: {
            patientId: patient2.id,
            diagnosis: 'Seasonal Allergies',
            details: 'Allergic to pollen. Prescribed antihistamines during spring season.',
            recordedAt: new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000), // 60 days ago
        },
    });

    console.log('Created Medical History');

    console.log('\n=== Seed Data Summary ===');
    console.log('Organization: City Hospital');
    console.log('Admin: admin@cityhospital.com / admin123');
    console.log('Receptionist: mary@cityhospital.com / recep123');
    console.log('Doctors:');
    console.log('  - sarah@cityhospital.com / doc123 (Cardiology)');
    console.log('  - michael@cityhospital.com / doc123 (Pediatrics)');
    console.log('Patients:');
    console.log('  - john@example.com / patient123');
    console.log('  - emily@example.com / patient123');
    console.log('  - robert@example.com / patient123');
    console.log('Appointments: 4 (1 completed, 2 confirmed, 1 pending)');
    console.log('Prescriptions: 1');
    console.log('Reschedule Requests: 1 (pending)');
    console.log('Reviews: 1');
    console.log('Medical History: 2 entries');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });

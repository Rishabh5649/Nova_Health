const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // 1. Create Patient user + Patient profile
  const patientUser = await prisma.user.create({
    data: {
      id: 'pat-user-999',
      email: 'patient@example.com',
      passwordHash: 'not-real',
      role: 'PATIENT', // make sure this matches your enum/case
      phone: '9999999999',
      status: 'ACTIVE',
      patient: {
        create: {
          name: 'Test Patient',
          dob: new Date('2000-01-01T00:00:00.000Z'),
          gender: 'female',
          allergies: ['penicillin'],
          chronicConditions: ['asthma'],
        },
      },
    },
    include: {
      patient: true,
    },
  });

  // 2. Create Doctor user + Doctor profile
  const doctorUser = await prisma.user.create({
    data: {
      id: 'doc-user-123',
      email: 'doctor@example.com',
      passwordHash: 'not-real',
      role: 'DOCTOR',
      phone: '8888888888',
      status: 'ACTIVE',
      doctor: {
        create: {
          name: 'Dr. Test Doctor',
          specialties: ['General Medicine'], // <-- FIXED: array instead of string
          // if your Doctor model has other required fields, Prisma will tell us next
        },
      },
    },
    include: {
      doctor: true,
    },
  });

  // 3. Create Admin user
  const adminUser = await prisma.user.create({
    data: {
      id: 'admin-user-1',
      email: 'admin@example.com',
      passwordHash: 'not-real',
      role: 'ADMIN',
      phone: '7777777777',
      status: 'ACTIVE',
    },
  });

  console.log('✅ Seed complete');
  console.log({
    patientUser,
    doctorUser,
    adminUser,
  });
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    prisma.$disconnect();
  });

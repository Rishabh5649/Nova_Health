// prisma/seed.cjs
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  const docPwdHash = await bcrypt.hash('doc1', 10);
  const patPwdHash = await bcrypt.hash('pat1', 10);

  // create doctor user + doctor record
  let docUser = await prisma.user.findUnique({ where: { email: 'doc1@hms.local' }});
  if (!docUser) {
    docUser = await prisma.user.create({
      data: {
        email: 'doc1@hms.local',
        passwordHash: docPwdHash,
        role: 'DOCTOR',
        status: 'ACTIVE'
      }
    });
    await prisma.doctor.create({
      data: {
        userId: docUser.id,
        name: 'Dr Test',
        qualifications: ['MBBS'],
        specialties: ['Cardiology'],
        yearsExperience: 5
      }
    });
  }

  // create patient user + patient record
  let patUser = await prisma.user.findUnique({ where: { email: 'pat1@hms.local' }});
  if (!patUser) {
    patUser = await prisma.user.create({
      data: {
        email: 'pat1@hms.local',
        passwordHash: patPwdHash,
        role: 'PATIENT',
        status: 'ACTIVE'
      }
    });
    await prisma.patient.create({
      data: {
        userId: patUser.id,
        name: 'Test Patient',
        allergies: [],
        chronicConditions: []
      }
    });
  }

  // set basic weekly availability (Mon-Wed 09:00-17:00)
  await prisma.doctorAvailability.deleteMany({ where: { doctorId: docUser.id } });
  await prisma.doctorAvailability.createMany({
    data: [
      { doctorId: docUser.id, weekday: 1, startMin: 9*60, endMin: 17*60 },
      { doctorId: docUser.id, weekday: 2, startMin: 9*60, endMin: 17*60 },
      { doctorId: docUser.id, weekday: 3, startMin: 9*60, endMin: 17*60 },
    ]
  });

  console.log('SEED: doctor userId:', docUser.id);
  console.log('SEED: patient userId:', patUser.id);
  console.log('SEED: doctor login -> email: doc1@hms.local password: doc1');
  console.log('SEED: patient login -> email: pat1@hms.local password: pat1');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

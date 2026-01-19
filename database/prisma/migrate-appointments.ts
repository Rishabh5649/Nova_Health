import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrateAppointments() {
    console.log('Starting appointment migration...');

    // Get the first organization (or you can specify which org to use)
    const org = await prisma.organization.findFirst();

    if (!org) {
        console.log('No organization found. Please create an organization first.');
        return;
    }

    console.log(`Using organization: ${org.name} (${org.id})`);

    // Find all appointments without an organizationId
    const appointmentsWithoutOrg = await prisma.appointment.findMany({
        where: {
            organizationId: null,
        },
        include: {
            doctor: true,
        },
    });

    console.log(`Found ${appointmentsWithoutOrg.length} appointments without organization`);

    // Update each appointment
    let updated = 0;
    for (const appt of appointmentsWithoutOrg) {
        // Try to find the doctor's organization membership
        const doctorUser = await prisma.user.findUnique({
            where: { id: appt.doctorId },
            include: {
                memberships: {
                    include: { organization: true },
                },
            },
        });

        let targetOrgId = org.id; // Default to first org

        // If doctor has memberships, use their first organization
        if (doctorUser?.memberships && doctorUser.memberships.length > 0) {
            targetOrgId = doctorUser.memberships[0].organizationId;
        }

        await prisma.appointment.update({
            where: { id: appt.id },
            data: { organizationId: targetOrgId },
        });

        updated++;
    }

    console.log(`✅ Updated ${updated} appointments with organizationId`);

    // Do the same for prescriptions
    const prescriptionsWithoutOrg = await prisma.prescription.findMany({
        where: {
            organizationId: null,
        },
    });

    console.log(`Found ${prescriptionsWithoutOrg.length} prescriptions without organization`);

    let prescUpdated = 0;
    for (const presc of prescriptionsWithoutOrg) {
        await prisma.prescription.update({
            where: { id: presc.id },
            data: { organizationId: org.id },
        });
        prescUpdated++;
    }

    console.log(`✅ Updated ${prescUpdated} prescriptions with organizationId`);
}

migrateAppointments()
    .catch((e) => {
        console.error('Migration failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });

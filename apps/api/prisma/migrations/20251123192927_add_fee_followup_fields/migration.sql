-- AlterTable
ALTER TABLE "Appointment" ADD COLUMN     "chargedFee" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "followUpParentId" TEXT,
ADD COLUMN     "isFollowUp" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "Doctor" ADD COLUMN     "followUpDays" INTEGER NOT NULL DEFAULT 7,
ADD COLUMN     "followUpFee" INTEGER NOT NULL DEFAULT 0,
ALTER COLUMN "baseFee" SET DEFAULT 500;

-- AlterTable
ALTER TABLE "Organization" ADD COLUMN     "feeControlMode" TEXT NOT NULL DEFAULT 'doctor_controlled';

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_followUpParentId_fkey" FOREIGN KEY ("followUpParentId") REFERENCES "Appointment"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AlterTable
ALTER TABLE "RescheduleRequest" ADD COLUMN     "isWithinSameWeek" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "requestCount" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "unavailableUntil" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "AppointmentCancellation" (
    "id" TEXT NOT NULL,
    "appointmentId" TEXT NOT NULL,
    "cancelledById" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "refundStatus" TEXT NOT NULL,
    "refundAmount" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AppointmentCancellation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AppointmentCancellation_appointmentId_key" ON "AppointmentCancellation"("appointmentId");

-- CreateIndex
CREATE INDEX "AppointmentCancellation_appointmentId_idx" ON "AppointmentCancellation"("appointmentId");

-- CreateIndex
CREATE INDEX "AppointmentCancellation_cancelledById_idx" ON "AppointmentCancellation"("cancelledById");

-- AddForeignKey
ALTER TABLE "AppointmentCancellation" ADD CONSTRAINT "AppointmentCancellation_appointmentId_fkey" FOREIGN KEY ("appointmentId") REFERENCES "Appointment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AppointmentCancellation" ADD CONSTRAINT "AppointmentCancellation_cancelledById_fkey" FOREIGN KEY ("cancelledById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

/*
  Warnings:

  - You are about to drop the column `condition` on the `MedicalHistory` table. All the data in the column will be lost.
  - You are about to drop the column `medicines` on the `Prescription` table. All the data in the column will be lost.
  - Added the required column `diagnosis` to the `MedicalHistory` table without a default value. This is not possible if the table is not empty.
  - Added the required column `diagnosis` to the `Prescription` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Prescription` table without a default value. This is not possible if the table is not empty.
  - Made the column `appointmentId` on table `Prescription` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "public"."Prescription" DROP CONSTRAINT "Prescription_appointmentId_fkey";

-- AlterTable
ALTER TABLE "Doctor" ADD COLUMN     "age" INTEGER;

-- AlterTable
ALTER TABLE "MedicalHistory" DROP COLUMN "condition",
ADD COLUMN     "diagnosis" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "Patient" ADD COLUMN     "bloodGroup" TEXT;

-- AlterTable
ALTER TABLE "Prescription" DROP COLUMN "medicines",
ADD COLUMN     "diagnosis" TEXT NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ALTER COLUMN "appointmentId" SET NOT NULL;

-- CreateTable
CREATE TABLE "Medication" (
    "id" TEXT NOT NULL,
    "prescriptionId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "dosage" TEXT NOT NULL,
    "frequency" TEXT NOT NULL,
    "duration" TEXT NOT NULL,
    "instruction" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Medication_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Prescription" ADD CONSTRAINT "Prescription_appointmentId_fkey" FOREIGN KEY ("appointmentId") REFERENCES "Appointment"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Medication" ADD CONSTRAINT "Medication_prescriptionId_fkey" FOREIGN KEY ("prescriptionId") REFERENCES "Prescription"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

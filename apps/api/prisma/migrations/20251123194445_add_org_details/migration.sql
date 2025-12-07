-- AlterTable
ALTER TABLE "Organization" ADD COLUMN     "branches" TEXT[],
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION,
ADD COLUMN     "yearEstablished" INTEGER;

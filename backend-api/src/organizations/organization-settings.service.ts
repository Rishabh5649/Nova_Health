import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OrganizationSettingsService {
    constructor(private prisma: PrismaService) { }

    /**
     * Get organization settings
     */
    async getSettings(organizationId: string) {
        let settings = await this.prisma.organizationSettings.findUnique({
            where: { organizationId },
        });

        // Create default settings if they don't exist
        if (!settings) {
            settings = await this.prisma.organizationSettings.create({
                data: {
                    organizationId,
                    enableReceptionists: false,
                    allowPatientBooking: true,
                    requireApprovalForDoctors: true,
                    requireApprovalForReceptionists: true,
                    autoApproveFollowUps: true,
                },
            });
        }

        return settings;
    }

    /**
     * Update organization settings
     */
    async updateSettings(organizationId: string, data: Partial<{
        enableReceptionists: boolean;
        allowPatientBooking: boolean;
        requireApprovalForDoctors: boolean;
        requireApprovalForReceptionists: boolean;
        autoApproveFollowUps: boolean;
    }>) {
        // Ensure settings exist first
        await this.getSettings(organizationId);

        return this.prisma.organizationSettings.update({
            where: { organizationId },
            data,
        });
    }

    /**
     * Check if receptionists are enabled for an organization
     */
    async areReceptionistsEnabled(organizationId: string): Promise<boolean> {
        const settings = await this.getSettings(organizationId);
        return settings.enableReceptionists;
    }

    /**
     * Check if doctor approval is required
     */
    async isDoctorApprovalRequired(organizationId: string): Promise<boolean> {
        const settings = await this.getSettings(organizationId);
        return settings.requireApprovalForDoctors;
    }

    /**
     * Check if receptionist approval is required
     */
    async isReceptionistApprovalRequired(organizationId: string): Promise<boolean> {
        const settings = await this.getSettings(organizationId);
        return settings.requireApprovalForReceptionists;
    }
}

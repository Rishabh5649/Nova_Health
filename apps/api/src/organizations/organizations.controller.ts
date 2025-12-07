import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, ForbiddenException } from '@nestjs/common';
import { OrganizationsService } from './organizations.service';
import { OrganizationSettingsService } from './organization-settings.service';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { ApproveStaffDto, UpdateOrganizationSettingsDto } from './dto/staff-management.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UpdateDoctorDto } from '../doctors/dto/update-doctor.dto';

@Controller('organizations')
export class OrganizationsController {
  constructor(
    private readonly organizationsService: OrganizationsService,
    private readonly settingsService: OrganizationSettingsService,
  ) { }

  @Post()
  create(@Body() createOrganizationDto: CreateOrganizationDto) {
    return this.organizationsService.create(createOrganizationDto);
  }

  @Get()
  findAll() {
    return this.organizationsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.organizationsService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateOrganizationDto: UpdateOrganizationDto) {
    return this.organizationsService.update(id, updateOrganizationDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.organizationsService.remove(id);
  }

  @Post(':id/members')
  addMember(
    @Param('id') id: string,
    @Body() body: { userId: string; role: 'ORG_ADMIN' | 'RECEPTIONIST' | 'DOCTOR' }
  ) {
    return this.organizationsService.addMember(id, body.userId, body.role);
  }

  // ============================================
  // STAFF MANAGEMENT ENDPOINTS
  // ============================================

  /**
   * Get pending staff awaiting approval
   * Only accessible by ORG_ADMIN
   */
  @UseGuards(JwtAuthGuard)
  @Get(':id/staff/pending')
  async getPendingStaff(
    @Param('id') orgId: string,
    @CurrentUser() user: any,
  ) {
    // Check if user is admin of this organization
    const isAdmin = await this.organizationsService.isOrgAdmin(orgId, user.sub);
    if (!isAdmin) {
      throw new ForbiddenException('Only organization admins can view pending staff');
    }

    return this.organizationsService.getPendingStaff(orgId);
  }

  /**
   * Get all staff with optional status filter
   * Only accessible by ORG_ADMIN
   */
  @UseGuards(JwtAuthGuard)
  @Get(':id/staff')
  async getAllStaff(
    @Param('id') orgId: string,
    @Query('status') status?: 'PENDING' | 'APPROVED' | 'REJECTED',
    @CurrentUser() user?: any,
  ) {
    // Check if user is admin of this organization
    const isAdmin = await this.organizationsService.isOrgAdmin(orgId, user.sub);
    if (!isAdmin) {
      throw new ForbiddenException('Only organization admins can view staff');
    }

    return this.organizationsService.getAllStaff(orgId, status);
  }

  /**
   * Approve or reject a staff membership
   * Only accessible by ORG_ADMIN
   */
  @UseGuards(JwtAuthGuard)
  @Patch(':id/staff/:membershipId')
  async updateMembershipStatus(
    @Param('id') orgId: string,
    @Param('membershipId') membershipId: string,
    @Body() body: ApproveStaffDto,
    @CurrentUser() user: any,
  ) {
    // Check if user is admin of this organization
    const isAdmin = await this.organizationsService.isOrgAdmin(orgId, user.sub);
    if (!isAdmin) {
      throw new ForbiddenException('Only organization admins can approve/reject staff');
    }

    return this.organizationsService.updateMembershipStatus(
      membershipId,
      body.status,
      user.sub,
    );
  }

  /**
   * Remove a staff member
   * Only accessible by ORG_ADMIN
   */
  @UseGuards(JwtAuthGuard)
  @Delete(':id/staff/:membershipId')
  async removeMember(
    @Param('id') orgId: string,
    @Param('membershipId') membershipId: string,
    @CurrentUser() user: any,
  ) {
    // Check if user is admin of this organization
    const isAdmin = await this.organizationsService.isOrgAdmin(orgId, user.sub);
    if (!isAdmin) {
      throw new ForbiddenException('Only organization admins can remove staff');
    }

    return this.organizationsService.removeMember(membershipId);
  }

  // ============================================
  // ORGANIZATION SETTINGS ENDPOINTS
  // ============================================

  /**
   * Get organization settings
   */
  @UseGuards(JwtAuthGuard)
  @Get(':id/settings')
  async getSettings(
    @Param('id') orgId: string,
    @CurrentUser() user: any,
  ) {
    // Check if user has approved membership
    const hasAccess = await this.organizationsService.hasApprovedMembership(orgId, user.sub);
    if (!hasAccess) {
      throw new ForbiddenException('Not a member of this organization');
    }

    return this.settingsService.getSettings(orgId);
  }

  /**
   * Update organization settings
   * Only accessible by ORG_ADMIN
   */
  @UseGuards(JwtAuthGuard)
  @Patch(':id/settings')
  async updateSettings(
    @Param('id') orgId: string,
    @Body() body: UpdateOrganizationSettingsDto,
    @CurrentUser() user: any,
  ) {
    // Check if user is admin of this organization
    const isAdmin = await this.organizationsService.isOrgAdmin(orgId, user.sub);
    if (!isAdmin) {
      throw new ForbiddenException('Only organization admins can update settings');
    }

    return this.settingsService.updateSettings(orgId, body);
  }

  @Get(':id/patients')
  @UseGuards(JwtAuthGuard)
  async getPatients(
    @Param('id') id: string,
    @Query('search') search: string,
    @CurrentUser() user: any,
  ) {
    const hasAccess = await this.organizationsService.hasApprovedMembership(id, user.sub);
    if (!hasAccess) {
      throw new ForbiddenException('Not a member of this organization');
    }
    return this.organizationsService.getPatients(id, search);
  }

  @Patch(':id/doctors/:userId')
  @UseGuards(JwtAuthGuard)
  async updateDoctorProfile(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @Body() dto: UpdateDoctorDto,
    @CurrentUser() user: any,
  ) {
    const isAdmin = await this.organizationsService.isOrgAdmin(id, user.sub);
    if (!isAdmin) {
      throw new ForbiddenException('Only organization admins can update doctor profiles');
    }
    return this.organizationsService.updateDoctorProfile(id, userId, dto);
  }
}

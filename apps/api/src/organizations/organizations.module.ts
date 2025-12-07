import { Module } from '@nestjs/common';
import { OrganizationsService } from './organizations.service';
import { OrganizationSettingsService } from './organization-settings.service';
import { OrganizationsController } from './organizations.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [OrganizationsController],
  providers: [OrganizationsService, OrganizationSettingsService],
  exports: [OrganizationsService, OrganizationSettingsService],
})
export class OrganizationsModule { }

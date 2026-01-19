import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { DoctorsModule } from './doctors/doctors.module';
import { AppointmentsModule } from './appointments/appointments.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { PatientsModule } from './patients/patients.module';
import { PrescriptionsModule } from './prescriptions/prescriptions.module';
import { AdminModule } from './admin/admin.module';
import { AvailabilityModule } from './availability/availability.module';
import { MedicalHistoryModule } from './medical-history/medical-history.module';
import { OrganizationsModule } from './organizations/organizations.module';
import { ReviewsModule } from './reviews/reviews.module';
import { NotificationsModule } from './notifications/notifications.module';
import { SchedulerModule } from './scheduler/scheduler.module';
import { RemindersModule } from './reminders/reminders.module';
import { PaymentsModule } from './payments/payments.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    UsersModule,
    AuthModule,
    DoctorsModule,
    AppointmentsModule,
    PatientsModule,
    PrescriptionsModule,
    AdminModule,
    AvailabilityModule,
    MedicalHistoryModule,
    OrganizationsModule,
    ReviewsModule,
    NotificationsModule,
    SchedulerModule,
    RemindersModule,
    PaymentsModule,
  ],
})
export class AppModule { }

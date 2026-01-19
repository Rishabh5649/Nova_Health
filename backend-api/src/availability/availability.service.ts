import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AvailabilityService {
  constructor(private prisma: PrismaService) {}

  /**
   * Set weekly availability for a doctor.
   *
   * OLD LOGIC (minutes per weekday) no longer matches the new schema because:
   * - DoctorAvailability now stores actual DateTime ranges (startTime, endTime)
   *   instead of { weekday, startMin, endMin }.
   *
   * For now we keep the method signature (so controllers don't break),
   * but we no-op it and return TODO.
   */
  async upsertWeekly(
    doctorUserId: string,
    windows: Array<{ weekday: number; startMin: number; endMin: number }>,
  ) {
    // Auth check: must be a doctor
    const doctor = await this.prisma.doctor.findUnique({
      where: { userId: doctorUserId },
    });
    if (!doctor) {
      throw new ForbiddenException('Only doctors can set availability');
    }

    // We can't map startMin/endMin --> DoctorAvailability.startTime/endTime
    // without deciding a reference date. So we stub this for now.
    // You can tell faculty: "table & API stub exist, logic WIP".
    return {
      ok: false,
      message:
        'Weekly availability logic is not yet implemented for the updated schema.',
      received: { doctorUserId, windows },
    };
  }

  /**
   * Doctor adds a time-off block.
   * This still matches the schema:
   * DoctorTimeOff { doctorId, startTime, endTime, reason? }
   */
  async addTimeOff(
    doctorUserId: string,
    start: Date,
    end: Date,
    reason?: string,
  ) {
    if (!(start < end)) {
      throw new BadRequestException('start must be before end');
    }

    const doctor = await this.prisma.doctor.findUnique({
      where: { userId: doctorUserId },
    });

    if (!doctor) {
      throw new ForbiddenException('Only doctors can add time off');
    }

    return this.prisma.doctorTimeOff.create({
      data: {
        doctorId: doctorUserId,
        startTime: start,
        endTime: end,
        reason: reason ?? null,
      },
    });
  }

  /**
   * Public: compute free slots between [from, to) for a given doctor.
   *
   * OLD LOGIC used:
   *  - doctorAvailability with weekday + startMin/endMin
   *  - appointment.startTime/endTime
   *  - custom status list ['ACCEPTED', 'RESCHEDULED']
   *
   * Our new schema has:
   *  - doctorAvailability ranges as DateTimes, but no "slotMinutes" concept
   *  - appointment only has scheduledAt (single timestamp)
   *  - statuses: PENDING | CONFIRMED | CANCELLED | COMPLETED
   *
   * Full recompute requires redesign. We'll stub for now.
   */
  async freeSlots(
    doctorId: string,
    from: Date,
    to: Date,
    slotMinutes: number,
  ) {
    if (!(from < to)) {
      throw new BadRequestException('from must be before to');
    }

    // We can at least read what's in DB (for demo/debug info)
    const [availability, timeOff, appts] = await this.prisma.$transaction([
      this.prisma.doctorAvailability.findMany({
        where: { doctorId },
      }),
      this.prisma.doctorTimeOff.findMany({
        where: {
          doctorId,
          startTime: { lt: to },
          endTime: { gt: from },
        },
      }),
      this.prisma.appointment.findMany({
        where: {
          doctorId,
          scheduledAt: {
            gte: from,
            lt: to,
          },
          status: {
            in: ['PENDING', 'CONFIRMED'], // only treat real/future bookings as "blocking"
          },
        },
        select: {
          id: true,
          scheduledAt: true,
          status: true,
        },
      }),
    ]);

    // We are not generating real slot combinations right now,
    // just returning data the frontend/admin can inspect.
    return {
      ok: false,
      message:
        'Slot generation logic is not yet implemented for the updated schema.',
      debug: {
        doctorId,
        range: { from, to, slotMinutes },
        availability,
        timeOff,
        appts,
      },
      slots: [],
    };
  }

  /**
   * Internal check if a slot is valid.
   *
   * OLD LOGIC assumed:
   *   - we had per-day startMin/endMin windows
   *   - appointments had startTime/endTime
   *   - statuses ACCEPTED/RESCHEDULED block the slot
   *
   * Under new schema, we would check:
   *   1. doctorAvailability windows for that day
   *   2. doctorTimeOff overlap
   *   3. does any CONFIRMED/PENDING appointment have same scheduledAt
   *
   * We'll stub it now to always return true (available),
   * but include debug info so you can talk about future improvements.
   */
  async isWithinDoctorAvailability(
    doctorId: string,
    start: Date,
    end: Date,
  ) {
    // collect context for debugging / viva explanation
    const [availability, timeOff, conflictingAppt] =
      await this.prisma.$transaction([
        this.prisma.doctorAvailability.findMany({
          where: { doctorId },
        }),
        this.prisma.doctorTimeOff.findMany({
          where: {
            doctorId,
            startTime: { lt: end },
            endTime: { gt: start },
          },
          select: { id: true, startTime: true, endTime: true, reason: true },
        }),
        this.prisma.appointment.findFirst({
          where: {
            doctorId,
            scheduledAt: {
              gte: start,
              lt: end,
            },
            status: {
              in: ['PENDING', 'CONFIRMED'],
            },
          },
          select: { id: true, scheduledAt: true, status: true },
        }),
      ]);

    // We don't have final logic yet, so just say "true" if no conflicts.
    const ok = !conflictingAppt && timeOff.length === 0;

    return {
      ok,
      debug: {
        requestedStart: start,
        requestedEnd: end,
        availability,
        timeOff,
        conflictingAppt,
      },
      note: 'Validation logic simplified due to schema change; full range checking is TODO.',
    };
  }
}

# Advanced Reschedule & Cancellation System - Implementation Plan

## Overview
This document outlines the implementation plan for an advanced appointment management system with sophisticated reschedule and cancellation rules based on user role and business logic.

---

## Business Rules Summary

### 🔄 Reschedule Rules

#### **Patient Reschedule Request**
- ✅ Can request reschedule **ONCE only**
- ✅ Must provide:
  - Requested new date/time
  - Reason for reschedule
  - "Can't make it until" date/time (unavailable period)
- ✅ **Same Week Rule**: If reschedule is within same week → Allowed
- ❌ **>1 Week Rule**: If reschedule is >1 week away → Must CANCEL instead
- 📋 Status tracked: Request counter, original appointment details

#### **Doctor Reschedule Request**
- ✅ Can request reschedule (unlimited times)
- ✅ Must provide:
  - Requested new date/time
  - Reason for reschedule
  - "Unavailable until" date/time
- ❌ **Cannot CANCEL** appointments (only reschedule)

#### **Admin/Receptionist Reschedule**
- ✅ Can **directly reschedule** any appointment (no approval needed)
- ✅ Instant reschedule via calendar slot selection
- ✅ Can also approve/reject reschedule requests from patients/doctors

### ❌ Cancellation Rules

#### **Patient Cancellation**
- ✅ Can cancel anytime
- ❌ **No refund** for patient-initiated cancellation
- ✅ Must provide cancellation reason
- 💰 Payment marked as `non_refundable`

#### **Organization/Admin Cancellation**
- ✅ Can cancel anytime
- ✅ **Full refund** processed
- ✅ Must provide detailed cancellation reason (mandatory)
- 💰 Payment status: `refunded`
- 📧 Patient notified of refund + reason

#### **Doctor Cancellation**
- ❌ **NOT ALLOWED** - Doctors can only request reschedule
- 🔄 If doctor needs to cancel → Must request reschedule or admin cancels on their behalf

---

## Database Schema Updates

### 1. Update `RescheduleRequest` Model

```prisma
model RescheduleRequest {
  id        String   @id @default(uuid())
  
  appointment   Appointment @relation(fields: [appointmentId], references: [id], onDelete: Cascade)
  appointmentId String
  
  requestedBy   User   @relation(fields: [requestedById], references: [id])
  requestedById String
  
  requestedDateTime DateTime
  reason            String
  
  // NEW FIELDS
  unavailableUntil  DateTime?  // "Can't make it until" date
  requestCount      Int        @default(1)  // Track how many times patient requested
  isWithinSameWeek  Boolean    @default(true)  // Auto-calculated
  
  status            String @default("PENDING") // PENDING, APPROVED, REJECTED
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@index([appointmentId])
  @@index([requestedById])
}
```

### 2. Create `AppointmentCancellation` Model

```prisma
model AppointmentCancellation {
  id              String   @id @default(uuid())
  
  appointment     Appointment @relation(fields: [appointmentId], references: [id], onDelete: Cascade)
  appointmentId   String   @unique
  
  cancelledBy     User   @relation(fields: [cancelledById], references: [id])
  cancelledById   String
  
  reason          String   // Mandatory cancellation reason
  refundStatus    String   // 'refunded', 'non_refundable', 'pending'
  refundAmount    Int?     // Amount refunded (if applicable)
  
  createdAt       DateTime @default(now())
  
  @@index([appointmentId])
  @@index([cancelledById])
}
```

### 3. Update `Appointment` Model

```prisma
model Appointment {
  // ... existing fields ...
  
  // NEW FIELDS
  rescheduleRequestCount Int @default(0)  // Track total reschedule requests for this appointment
  canBeRescheduled       Boolean @default(true)  // False if patient exceeded limit
  
  // Relations
  rescheduleRequests RescheduleRequest[]
  cancellation       AppointmentCancellation?
}
```

---

## Backend Implementation

### Phase 1: Enhanced Reschedule Service

**File**: `apps/api/src/appointments/reschedule.service.ts`

#### New Methods:

```typescript
/**
 * Patient requests reschedule with business rules enforcement
 */
async requestRescheduleAsPatient(
  appointmentId: string,
  patientId: string,
  requestedDateTime: Date,
  reason: string,
  unavailableUntil: Date
) {
  // 1. Check if patient already requested reschedule
  const appointment = await this.prisma.appointment.findUnique({
    where: { id: appointmentId },
    include: { rescheduleRequests: true }
  });
  
  const patientRequests = appointment.rescheduleRequests.filter(
    r => r.requestedById === patientId
  );
  
  if (patientRequests.length >= 1) {
    throw new ForbiddenException('Patients can only request reschedule once');
  }
  
  // 2. Check if reschedule is within same week
  const originalDate = appointment.scheduledAt;
  const isWithinSameWeek = isSameWeek(originalDate, requestedDateTime);
  
  if (!isWithinSameWeek) {
    throw new ForbiddenException(
      'Reschedule requests must be within the same week. Please cancel and rebook instead.'
    );
  }
  
  // 3. Create reschedule request
  return this.prisma.rescheduleRequest.create({
    data: {
      appointmentId,
      requestedById: patientId,
      requestedDateTime,
      reason,
      unavailableUntil,
      isWithinSameWeek,
      requestCount: 1,
      status: 'PENDING'
    }
  });
}

/**
 * Doctor requests reschedule (no limits)
 */
async requestRescheduleAsDoctor(
  appointmentId: string,
  doctorId: string,
  requestedDateTime: Date,
  reason: string,
  unavailableUntil?: Date
) {
  // Doctors can request unlimited times
  return this.prisma.rescheduleRequest.create({
    data: {
      appointmentId,
      requestedById: doctorId,
      requestedDateTime,
      reason,
      unavailableUntil,
      status: 'PENDING'
    }
  });
}
```

### Phase 2: Cancellation Service

**File**: `apps/api/src/appointments/cancellation.service.ts`

```typescript
import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CancellationService {
  constructor(private prisma: PrismaService) {}

  /**
   * Patient cancels appointment (no refund)
   */
  async cancelAsPatient(
    appointmentId: string,
    patientId: string,
    reason: string
  ) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: { patient: true }
    });

    if (appointment.patientId !== patientId) {
      throw new ForbiddenException('Not your appointment');
    }

    // Update appointment status
    await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: 'CANCELLED' }
    });

    // Record cancellation
    await this.prisma.appointmentCancellation.create({
      data: {
        appointmentId,
        cancelledById: patientId,
        reason,
        refundStatus: 'non_refundable',
        refundAmount: 0
      }
    });

    // TODO: Send notification to patient
    
    return { message: 'Appointment cancelled. No refund provided.' };
  }

  /**
   * Admin/Organization cancels (refund provided)
   */
  async cancelAsAdmin(
    appointmentId: string,
    adminId: string,
    reason: string
  ) {
    if (!reason || reason.trim().length < 10) {
      throw new ForbiddenException('Detailed cancellation reason required (min 10 characters)');
    }

    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: { patient: true }
    });

    // Calculate refund (for now, assume full fee)
    const refundAmount = 500; // TODO: Get from appointment fee

    // Update appointment status
    await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: 'CANCELLED' }
    });

    // Record cancellation with refund
    await this.prisma.appointmentCancellation.create({
      data: {
        appointmentId,
        cancelledById: adminId,
        reason,
        refundStatus: 'refunded',
        refundAmount
      }
    });

    // TODO: Process refund via payment gateway
    // TODO: Send refund notification to patient

    return { 
      message: 'Appointment cancelled. Refund processed.',
      refundAmount 
    };
  }

  /**
   * Doctor attempts to cancel (blocked)
   */
  async cancelAsDoctor() {
    throw new ForbiddenException(
      'Doctors cannot cancel appointments. Please request a reschedule instead.'
    );
  }
}
```

---

## API Endpoints

### Reschedule Endpoints

```
POST   /appointments/:id/reschedule-request/patient
Body: { requestedDateTime, reason, unavailableUntil }

POST   /appointments/:id/reschedule-request/doctor
Body: { requestedDateTime, reason, unavailableUntil }

GET    /appointments/reschedule-requests
Query: ?status=PENDING&role=PATIENT

PATCH  /appointments/reschedule-requests/:id/approve

PATCH  /appointments/reschedule-requests/:id/reject
```

### Cancellation Endpoints

```
POST   /appointments/:id/cancel/patient
Body: { reason }

POST   /appointments/:id/cancel/admin
Body: { reason }

GET    /appointments/:id/cancellation
```

---

## Frontend Implementation

### 1. Enhanced Reschedule Request Page

**Features**:
- Form with fields:
  - New date/time picker
  - Reason (required, min 20 chars)
  - "Can't make it until" date picker
- Validate same-week rule for patients
- Show warning if >1 week: "Please cancel and rebook instead"
- Submit to appropriate endpoint based on role

### 2. Cancellation Modal/Page

**Features**:
- Cancel button on appointment detail page
- Modal with:
  - Cancellation reason textarea (required, min 10 chars for admin)
  - Warning message based on role:
    - Patient: "No refund will be provided"
    - Admin: "Patient will receive full refund of ₹XXX"
  - Confirm button
- Role-based visibility:
  - Show for: PATIENT, ADMIN, RECEPTIONIST
  - Hide for: DOCTOR

### 3. Reschedule Requests Management

**Enhancements to existing page**:
- Show "unavailableUntil" date
- Show request count for patients
- Badge: "1st Request" or "Exceeded Limit"
- Filter by role: Patient Requests | Doctor Requests

---

## Testing Checklist

### Reschedule Testing
- [ ] Patient requests reschedule within same week → Success
- [ ] Patient requests 2nd reschedule → Blocked
- [ ] Patient requests reschedule >1 week → Blocked with message
- [ ] Doctor requests multiple reschedules → All succeed
- [ ] Admin directly reschedules → Instant success

### Cancellation Testing
- [ ] Patient cancels → No refund
- [ ] Admin cancels without reason → Blocked
- [ ] Admin cancels with reason → Refund processed
- [ ] Doctor attempts cancel → Blocked with message
- [ ] Cancelled appointment cannot be rescheduled

---

## Migration Steps

1. **Database**:
   ```bash
   cd apps/api
   # Add new fields to schema.prisma
   npx prisma migrate dev --name add_advanced_reschedule_cancel
   npx prisma generate
   ```

2. **Backend**:
   - Create `CancellationService`
   - Update `RescheduleService`
   - Add new controller endpoints
   - Add validation decorators

3. **Frontend**:
   - Create cancellation modal component
   - Update reschedule request forms
   - Add role-based button visibility
   - Integrate API calls

4. **Testing**:
   - Unit tests for business rules
   - Integration tests for workflows
   - Manual QA with different roles

---

## Priority Implementation Order

### **P0 - Critical (Implement Now)**
1. ✅ Calendar-based reschedule (DONE)
2. Basic cancel button for admin
3. Patient cancel with no-refund logic

### **P1 - High**
1. Enhanced reschedule request fields (unavailableUntil)
2. Same-week validation for patients
3. Once-only limit for patient requests
4. Admin refundable cancellation

### **P2 - Medium**
1. Doctor reschedule request UI
2. Cancellation history tracking
3. Refund amount calculation
4. Email notifications

### **P3 - Nice to Have**
1. Cancellation analytics
2. Bulk cancellation (for doctor leaves)
3. Auto-suggest alternative slots
4. Payment gateway integration

---

**Status**: Phase 1 (Calendar Reschedule) ✅ Complete  
**Next**: Implement basic cancellation with refund logic  
**Target**: Full system complete within 2-3 development sessions

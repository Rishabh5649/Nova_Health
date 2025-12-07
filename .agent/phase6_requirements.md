# Feature Requirements - Phase 6 Implementation Plan

## 📋 New Requirements Summary

### 1. Doctor Can Mark Appointments as Complete ✅
**Status**: Already implemented in backend
**Action Needed**: Verify mobile app UI has the button

### 2. Admin Calendar/Schedule View 🔄
**Status**: Not yet implemented
**Priority**: HIGH

### 3. Appointment Rescheduling 🔄
**Status**: Not yet implemented
**Priority**: HIGH

### 4. Medical History Access 🔄
**Status**: Partially implemented
**Priority**: MEDIUM

---

## 🎯 Detailed Requirements

### Requirement 1: Doctor Appointment Completion

**Current State**:
- ✅ API endpoint `/appointments/:id/complete` allows DOCTOR and ADMIN
- ✅ Backend service supports doctor completing appointments
- ❓ Need to verify mobile app has "Mark Complete" button

**Action Items**:
1. Check if mobile app has complete button in appointment detail view
2. If missing, add "Mark Complete" button to confirmed appointments
3. Test workflow: Confirmed → Complete

---

### Requirement 2: Admin Calendar/Schedule View

**Description**: 
Admin needs a calendar view showing:
- Doctor's daily schedule
- Work hours (e.g., 9 AM - 5 PM)
- Booked appointments
- Free slots
- Ability to assign appointments to free slots

**Implementation Plan**:

#### A. Backend Changes Needed:
1. **Doctor Availability API**:
   - GET `/doctors/:id/availability?date=2025-11-23`
   - Returns: work hours, booked slots, free slots

2. **Appointment Scheduling API**:
   - PATCH `/appointments/:id/schedule`
   - Body: `{ scheduledAt: "2025-11-23T10:00:00Z" }`
   - Allows admin to set exact time

#### B. Frontend Changes (Admin Portal):
1. **Calendar Component**:
   - Week view or day view
   - Show doctor's schedule
   - Visual representation of appointments

2. **Slot Selection**:
   - Click on free slot
   - Assign pending appointment to that slot
   - Drag-and-drop for rescheduling

#### C. Database Schema:
Already exists:
- `DoctorAvailability` table (weekday, startTime, endTime)
- `DoctorTimeOff` table (for holidays/breaks)

**Example Calendar View**:
```
Dr. Sarah Smith - November 23, 2025

09:00 AM ─────────────────────────
         [FREE SLOT]
10:00 AM ─────────────────────────
         [John Patient - Fever]
11:00 AM ─────────────────────────
         [FREE SLOT]
12:00 PM ─────────────────────────
         [LUNCH BREAK]
01:00 PM ─────────────────────────
         [FREE SLOT]
02:00 PM ─────────────────────────
         [Mary Patient - Checkup]
03:00 PM ─────────────────────────
         [FREE SLOT]
```

---

### Requirement 3: Appointment Rescheduling

**Description**:
- Patients can request rescheduling
- Doctors can request rescheduling
- Admin can approve and reschedule

**Implementation Plan**:

#### A. Database Changes:
Add to `Appointment` model:
```prisma
model Appointment {
  // ... existing fields
  rescheduleRequestedBy String?  // userId who requested
  rescheduleReason      String?
  rescheduleStatus      String?  // PENDING, APPROVED, REJECTED
  originalScheduledAt   DateTime?
}
```

#### B. API Endpoints:
1. **Request Reschedule**:
   - POST `/appointments/:id/reschedule-request`
   - Body: `{ reason: "Emergency", preferredDate: "..." }`
   - Allowed: PATIENT, DOCTOR

2. **Approve Reschedule**:
   - PATCH `/appointments/:id/reschedule-approve`
   - Body: `{ newScheduledAt: "..." }`
   - Allowed: ADMIN

3. **Reject Reschedule**:
   - PATCH `/appointments/:id/reschedule-reject`
   - Allowed: ADMIN

#### C. UI Changes:

**Patient Mobile App**:
- "Request Reschedule" button on confirmed appointments
- Form to enter reason and preferred date

**Doctor Mobile App**:
- "Request Reschedule" button on confirmed appointments
- View reschedule requests from patients

**Admin Web Portal**:
- "Reschedule Requests" tab
- Approve/Reject with new time selection
- Calendar integration for easy rescheduling

**Workflow**:
```
1. Patient/Doctor → Request Reschedule
2. Admin sees request in portal
3. Admin checks calendar for free slots
4. Admin approves with new time OR rejects
5. Patient/Doctor notified of decision
```

---

### Requirement 4: Medical History Access

**Current State**:
- ✅ `MedicalHistory` table exists in database
- ✅ API endpoints exist for creating/viewing medical history
- ❓ Need to verify access permissions

**Access Control Requirements**:

| User Type | Can View | Can Edit | Scope |
|-----------|----------|----------|-------|
| **Patient** | ✅ Own only | ❌ No | All their history |
| **Doctor** | ✅ Yes | ✅ Yes | Only for their appointments |
| **Admin** | ✅ Yes | ❌ No | Organization patients only |

**Implementation Checklist**:

#### A. Backend Verification:
1. Check `/medical-history` endpoints exist
2. Verify role-based access control
3. Ensure organization scoping for admin

#### B. Frontend Implementation:

**Patient Mobile App**:
- "My Medical History" section
- View all past diagnoses and treatments
- Read-only access

**Doctor Mobile App**:
- View patient history when viewing appointment
- Add medical history entry after completing appointment
- Form: Diagnosis, Details, Date

**Admin Web Portal**:
- Patient detail page shows medical history
- Read-only view
- Filter by date, doctor, diagnosis

#### C. Privacy Considerations:
- Patient consent required for sharing history
- Audit log for who accessed what
- HIPAA/privacy compliance

---

## 🚀 Implementation Priority

### Phase 6A: Critical Features (Week 1)
1. ✅ **Doctor Complete Button** (verify/add if missing)
2. 🔄 **Admin Calendar View** (basic day view)
3. 🔄 **Manual Appointment Scheduling** (admin assigns time)

### Phase 6B: Enhanced Features (Week 2)
4. 🔄 **Reschedule Request Flow** (patient/doctor request)
5. 🔄 **Reschedule Approval** (admin approves with calendar)
6. 🔄 **Medical History Access** (verify and enhance UI)

### Phase 6C: Polish (Week 3)
7. 🔄 **Calendar Drag-and-Drop**
8. 🔄 **Notifications** (reschedule approved/rejected)
9. 🔄 **Audit Logs Viewer**

---

## 📊 Technical Architecture

### Calendar View Component Stack:
```
┌─────────────────────────────────┐
│   Admin Web Portal (Next.js)    │
│                                  │
│  ┌────────────────────────────┐ │
│  │  Calendar Component        │ │
│  │  - React Big Calendar      │ │
│  │  - FullCalendar            │ │
│  │  - Custom Grid View        │ │
│  └────────────────────────────┘ │
└─────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│      Backend API (NestJS)       │
│                                  │
│  GET /doctors/:id/schedule      │
│  GET /doctors/:id/availability  │
│  PATCH /appointments/:id/schedule│
└─────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│     Database (PostgreSQL)       │
│                                  │
│  - DoctorAvailability           │
│  - Appointment                  │
│  - DoctorTimeOff                │
└─────────────────────────────────┘
```

---

## 🧪 Testing Scenarios

### Test 1: Doctor Completes Appointment
1. Doctor logs in to mobile app
2. Views confirmed appointment
3. Clicks "Mark Complete"
4. Status changes to COMPLETED
5. Appointment moves to "Past Appointments"

### Test 2: Admin Assigns Time to Pending Request
1. Admin sees pending request (no time assigned)
2. Opens calendar view for that doctor
3. Sees free slots
4. Clicks on 2:00 PM slot
5. Assigns pending appointment to that slot
6. Status changes to CONFIRMED with scheduled time

### Test 3: Patient Requests Reschedule
1. Patient has confirmed appointment for Nov 23, 10 AM
2. Clicks "Request Reschedule"
3. Enters reason: "Work conflict"
4. Suggests new date: Nov 24, 2 PM
5. Request sent to admin
6. Admin sees request in portal
7. Admin checks calendar, approves for Nov 24, 3 PM
8. Patient notified of new time

### Test 4: Doctor Views Patient Medical History
1. Doctor views appointment detail
2. Sees "Medical History" tab
3. Views patient's past diagnoses
4. After completing appointment, adds new entry
5. Entry saved and visible to patient

---

## 📝 Files to Create/Modify

### Backend (NestJS):
- `apps/api/src/appointments/dto/reschedule-request.dto.ts` (new)
- `apps/api/src/appointments/appointments.service.ts` (update)
- `apps/api/src/appointments/appointments.controller.ts` (update)
- `apps/api/src/doctors/doctors.service.ts` (add schedule methods)
- `apps/api/prisma/schema.prisma` (add reschedule fields)

### Frontend - Admin Portal (Next.js):
- `apps/admin-web/src/app/dashboard/calendar/page.tsx` (new)
- `apps/admin-web/src/components/Calendar.tsx` (new)
- `apps/admin-web/src/components/AppointmentScheduler.tsx` (new)
- `apps/admin-web/src/lib/api.ts` (add calendar methods)

### Frontend - Mobile App (Flutter):
- `hms_frontend_flutter/lib/screens/appointment_detail_screen.dart` (new/update)
- `hms_frontend_flutter/lib/screens/reschedule_request_screen.dart` (new)
- `hms_frontend_flutter/lib/screens/medical_history_screen.dart` (new/update)

---

## ❓ Questions to Clarify

1. **Calendar View**:
   - Should it show multiple doctors at once or one at a time?
   - Week view or day view preferred?
   - Should it show past appointments or only future?

2. **Rescheduling**:
   - Can appointments be rescheduled multiple times?
   - How many days in advance can reschedule be requested?
   - Should there be a limit on reschedule requests?

3. **Medical History**:
   - Should patients be able to add their own history entries?
   - Should there be categories (diagnosis, medication, allergies)?
   - Should it integrate with prescriptions?

4. **Work Hours**:
   - Are doctor work hours the same every day?
   - How to handle holidays and time off?
   - Should doctors be able to set their own availability?

---

## 🎯 Next Steps

Please confirm:
1. Should I start implementing the **Admin Calendar View** first?
2. Do you want a simple list view or a visual calendar grid?
3. Should I add the **"Mark Complete"** button to doctor's mobile app now?
4. Any specific calendar library preference (FullCalendar, React Big Calendar, custom)?

Once confirmed, I'll begin implementation! 🚀

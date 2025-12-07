# Role-Based Access Control - Updated Permissions

## 📋 Appointment Management Workflow

### Patient → Request Appointment
1. Patient books appointment via mobile app
2. Appointment created with status: `PENDING`
3. Appointment appears in:
   - Admin Portal (Pending Requests)
   - Doctor's Mobile App (Pending Requests - View Only)

### Admin/Receptionist → Accept/Reject
1. Admin logs into Web Portal
2. Views pending requests
3. Can **Accept** (status → `CONFIRMED`) or **Reject** (status → `CANCELLED`)
4. Only admins can perform these actions

### Doctor → View & Complete
1. Doctor sees confirmed appointments in mobile app
2. Doctor can view pending requests (but cannot accept/reject)
3. Doctor can mark confirmed appointments as `COMPLETED`

---

## 🔐 Updated Permissions Matrix

| Action | Patient | Doctor | Admin/Receptionist |
|--------|---------|--------|-------------------|
| **Request Appointment** | ✅ Mobile | ❌ | ❌ |
| **View Pending Requests** | ❌ | ✅ Mobile (View Only) | ✅ Web |
| **Accept Request** | ❌ | ❌ | ✅ Web |
| **Reject Request** | ❌ | ❌ | ✅ Web |
| **View Confirmed Appointments** | ✅ Mobile | ✅ Mobile | ✅ Web |
| **Complete Appointment** | ❌ | ✅ Mobile | ✅ Web |
| **Cancel Appointment** | ✅ Own Only | ✅ Own Only | ✅ Any |

---

## 🎯 API Endpoint Permissions

### POST `/appointments/request`
- **Allowed**: `PATIENT`
- **Purpose**: Create new appointment request

### PATCH `/appointments/:id/confirm`
- **Allowed**: `ADMIN` only
- **Purpose**: Accept pending request → CONFIRMED
- **Changed**: Previously allowed DOCTOR, now ADMIN only

### PATCH `/appointments/:id/reject`
- **Allowed**: `ADMIN` only
- **Purpose**: Reject pending request → CANCELLED
- **Changed**: Previously allowed DOCTOR, now ADMIN only

### PATCH `/appointments/:id/complete`
- **Allowed**: `DOCTOR`, `ADMIN`
- **Purpose**: Mark appointment as completed
- **Unchanged**: Both roles can complete

### PATCH `/appointments/:id/cancel`
- **Allowed**: `PATIENT`, `DOCTOR`, `ADMIN`
- **Purpose**: Cancel appointment
- **Rules**: Patients/Doctors can only cancel their own, Admins can cancel any

### GET `/appointments`
- **Allowed**: All authenticated users
- **Purpose**: List appointments with filters
- **Scoped**: By user role and organization

---

## 📱 Mobile App Changes (Doctor)

### Pending Requests Screen
**Before**:
- Showed "Accept" button
- Doctor could pick date/time and confirm
- Direct API call to `/appointments/:id/confirm`

**After**:
- **View-only** display
- Shows "Waiting for admin approval" message
- No action buttons
- Informative empty state explaining admin approval process

### Today's Appointments Screen
**Unchanged**:
- Shows confirmed appointments
- Can mark as complete
- Full appointment details

---

## 🌐 Web Portal (Admin)

### Appointments Page
**Features**:
- Filter by status (All, Pending, Confirmed, Completed)
- **Accept** button for pending requests
- **Reject** button for pending requests
- **Complete** button for confirmed appointments
- Real-time status updates

### Workflow
1. Admin sees pending request
2. Clicks "Accept"
3. Status changes to CONFIRMED
4. Appointment appears in doctor's "Today" list
5. Doctor completes appointment
6. Status changes to COMPLETED

---

## 🔄 Data Flow

```
┌─────────────┐
│   Patient   │
│  (Mobile)   │
└──────┬──────┘
       │ 1. Request Appointment
       ▼
┌─────────────────┐
│   API Server    │
│  Status: PENDING│
└────┬────────┬───┘
     │        │
     │        │ 2. View (Read-only)
     │        ▼
     │   ┌──────────┐
     │   │  Doctor  │
     │   │ (Mobile) │
     │   └──────────┘
     │
     │ 3. Accept/Reject
     ▼
┌──────────────┐
│    Admin     │
│    (Web)     │
└──────┬───────┘
       │ 4. Status → CONFIRMED
       ▼
┌─────────────────┐
│   API Server    │
│ Status: CONFIRMED│
└────┬────────────┘
     │
     │ 5. Appears in Today's List
     ▼
┌──────────┐
│  Doctor  │
│ (Mobile) │
└────┬─────┘
     │ 6. Complete
     ▼
┌─────────────────┐
│   API Server    │
│ Status: COMPLETED│
└─────────────────┘
```

---

## ✅ Benefits of This Approach

1. **Centralized Control**: Admin/Receptionist manages all scheduling
2. **Doctor Focus**: Doctors focus on patient care, not scheduling
3. **Better Workflow**: Clear separation of administrative vs clinical tasks
4. **Audit Trail**: All acceptances tracked to admin user
5. **Scalability**: Easy to add more receptionists without giving doctors admin access

---

## 🧪 Testing the New Workflow

### Test Case 1: Patient Books Appointment
1. Login as patient (john@example.com)
2. Book appointment with Dr. Sarah
3. Verify status is PENDING

### Test Case 2: Doctor Views Request (Cannot Accept)
1. Login as doctor (sarah@cityhospital.com)
2. Navigate to "Pending Requests"
3. Verify you see the request
4. Verify there's NO accept button
5. Verify message says "Waiting for admin approval"

### Test Case 3: Admin Accepts Request
1. Login to web portal (admin@cityhospital.com)
2. Navigate to Appointments → Pending
3. Click "Accept" on the request
4. Verify status changes to CONFIRMED

### Test Case 4: Doctor Completes Appointment
1. As doctor, navigate to "Today's Appointments"
2. See the confirmed appointment
3. Click "Complete" (if available)
4. Verify status changes to COMPLETED

---

## 📝 Files Modified

1. **Backend API**:
   - `apps/api/src/appointments/appointments.controller.ts`
     - Changed `@Roles('DOCTOR', 'ADMIN')` → `@Roles('ADMIN')` for confirm/reject
   
2. **Mobile App**:
   - `hms_frontend_flutter/lib/screens/pending_requests_screen.dart`
     - Removed accept button
     - Made view-only
     - Added informative messages

---

## 🎓 Key Takeaway

**Doctors** are now focused on **clinical work** (viewing appointments, completing consultations), while **Admins/Receptionists** handle **administrative tasks** (scheduling, accepting/rejecting requests).

This creates a clear separation of responsibilities and improves the overall workflow efficiency.

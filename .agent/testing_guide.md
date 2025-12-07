# Multi-Organization System - Testing Guide

## 🎯 Testing Objectives

This guide will help you verify that the multi-organization tenancy system is working correctly across all three applications.

---

## 📋 Pre-Test Setup

### Ensure All Services Are Running:
1. **Backend API**: `http://localhost:3000` (in `apps/api`)
2. **Admin Web Portal**: `http://localhost:3001` (in `apps/admin-web`)
3. **Mobile App**: Flutter Web in Chrome (in `hms_frontend_flutter`)

### Test Credentials:
- **Org Admin**: admin@cityhospital.com / admin123
- **Doctor**: sarah@cityhospital.com / doc123
- **Patient**: john@example.com / patient123

---

## 🧪 Test Scenarios

### Test 1: Admin Portal Login & Dashboard

**Objective**: Verify admin can log in and see organization-scoped data

**Steps**:
1. Open `http://localhost:3001`
2. Login with: admin@cityhospital.com / admin123
3. Verify you're redirected to `/dashboard`
4. Check that the dashboard shows:
   - Appointments Today count
   - Pending Requests count
   - Completed count
   - Recent Appointments table

**Expected Result**: ✅ Dashboard loads with real data from City Hospital

**Troubleshooting**:
- If login fails: Check API is running on port 3000
- If no data shows: Check database has seeded data

---

### Test 2: Appointment Management (Web Portal)

**Objective**: Verify receptionist can manage appointments

**Steps**:
1. While logged in as admin, navigate to "Appointments" in sidebar
2. Verify you see tabs: All, Pending, Confirmed, Completed
3. Click "Pending" tab
4. If there are pending appointments:
   - Click "Accept" on one
   - Verify status changes to "Confirmed"
5. Click "Confirmed" tab
6. Click "Complete" on a confirmed appointment
7. Verify status changes to "Completed"

**Expected Result**: ✅ Appointment statuses update in real-time

**Troubleshooting**:
- If no appointments: Create one from mobile app first (Test 4)
- If actions fail: Check browser console for errors

---

### Test 3: Patient Books Appointment (Mobile App)

**Objective**: Verify patient can book appointment with organization context

**Steps**:
1. In Flutter app, login as: john@example.com / patient123
2. Navigate to "Find Doctors" or search
3. Select a doctor (Dr. Sarah Smith)
4. Click "Book Appointment"
5. Enter symptoms: "Fever and cough"
6. Verify you see organization info: "City Hospital"
7. Click "Confirm and book"
8. Verify success message appears

**Expected Result**: ✅ Appointment created with organizationId

**Troubleshooting**:
- If doctor not found: Check doctor seeded in database
- If organization not shown: Check doctor has membership

---

### Test 4: Multi-Organization Doctor Selection

**Objective**: Verify patient can choose organization when doctor works at multiple locations

**Setup**:
1. First, add Dr. Sarah to a second organization via Prisma Studio or SQL:
```sql
-- Create second org
INSERT INTO "Organization" (id, name, type) 
VALUES ('org-2', 'Wellness Clinic', 'Clinic');

-- Add doctor to second org
INSERT INTO "OrganizationMembership" (id, "userId", "organizationId", role) 
VALUES ('mem-2', '<sarah-user-id>', 'org-2', 'DOCTOR');
```

**Steps**:
1. Login as patient in mobile app
2. Search for Dr. Sarah Smith
3. Click "Book Appointment"
4. **Verify**: Dialog appears asking "Select Organization"
5. Verify you see both:
   - City Hospital
   - Wellness Clinic
6. Select "Wellness Clinic"
7. Complete booking
8. Check admin portal - appointment should show under Wellness Clinic

**Expected Result**: ✅ Patient can choose organization

**Troubleshooting**:
- If dialog doesn't appear: Check doctor has 2+ memberships
- If wrong org: Check organizationId in appointment record

---

### Test 5: Organization Data Isolation

**Objective**: Verify organizations only see their own data

**Setup**:
1. Create a second organization and admin user
2. Create appointments for both organizations

**Steps**:
1. Login to web portal as City Hospital admin
2. Note the appointments shown
3. Logout and login as second organization admin
4. Verify you see DIFFERENT appointments
5. Verify you CANNOT see City Hospital's appointments

**Expected Result**: ✅ Complete data isolation between organizations

**Troubleshooting**:
- If seeing all data: Check organizationId filter in API calls
- If seeing no data: Check user's memberships

---

### Test 6: Doctor Dashboard (Mobile App)

**Objective**: Verify doctor can see their appointments

**Steps**:
1. Login to mobile app as: sarah@cityhospital.com / doc123
2. Navigate to "Today's Appointments"
3. Verify you see appointments for today
4. Click on an appointment
5. Verify patient details are shown
6. Navigate to "Pending Requests"
7. Verify you see pending appointment requests

**Expected Result**: ✅ Doctor sees organization-scoped appointments

**Troubleshooting**:
- If no appointments: Create some from patient account
- If seeing wrong appointments: Check doctor's organizationId

---

### Test 7: Navigation & Routing (Web Portal)

**Objective**: Verify all dashboard pages load correctly

**Steps**:
1. Login to web portal as admin
2. Click each sidebar link:
   - Dashboard ✅
   - Appointments ✅
   - Patients ✅
   - Doctors ✅
   - Settings ✅
3. Verify each page loads without errors
4. Verify sidebar highlights active page

**Expected Result**: ✅ All pages load, navigation works smoothly

**Troubleshooting**:
- If 404 errors: Check Next.js routing configuration
- If pages blank: Check browser console for errors

---

### Test 8: Data Migration Verification

**Objective**: Verify existing appointments have organizationId

**Steps**:
1. Open Prisma Studio: `npx prisma studio` (in apps/api)
2. Navigate to "Appointment" model
3. Check all appointments have `organizationId` field populated
4. Navigate to "Prescription" model
5. Verify prescriptions also have `organizationId`

**Expected Result**: ✅ All records have organizationId

**Troubleshooting**:
- If null values: Run migration script again
- If script fails: Check database connection

---

### Test 9: API Endpoints (Manual Testing)

**Objective**: Verify API endpoints return correct data

**Tools**: Postman, Thunder Client, or curl

**Test Login**:
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@cityhospital.com","password":"admin123"}'
```

**Expected**: Returns token and user with memberships

**Test Get Appointments** (replace TOKEN):
```bash
curl http://localhost:3000/appointments?organizationId=<org-id> \
  -H "Authorization: Bearer <TOKEN>"
```

**Expected**: Returns only appointments for that organization

**Test Get Organizations**:
```bash
curl http://localhost:3000/organizations \
  -H "Authorization: Bearer <TOKEN>"
```

**Expected**: Returns list of organizations

---

## 🔍 Edge Cases to Test

### Edge Case 1: Doctor with No Organization
- Create a doctor without organization membership
- Verify they can still be searched
- Verify booking works (organizationId should be null)

### Edge Case 2: Patient Books Multiple Appointments
- Book 3+ appointments with same doctor
- Verify all appear in admin portal
- Verify all appear in doctor's dashboard

### Edge Case 3: Concurrent Actions
- Have admin accept appointment while patient is viewing it
- Verify status updates correctly
- No data corruption

### Edge Case 4: Invalid Organization ID
- Try to create appointment with fake organizationId
- Verify proper error handling
- No crashes

---

## 📊 Performance Testing

### Load Test: Multiple Appointments
1. Create 20+ appointments via API or mobile app
2. Load admin portal appointments page
3. Verify page loads in < 2 seconds
4. Verify filtering works smoothly

### Load Test: Dashboard Stats
1. With 50+ appointments in database
2. Load dashboard
3. Verify stats calculate correctly
4. Verify page loads in < 1 second

---

## ✅ Success Criteria

All tests should pass with these criteria:

- [ ] Admin can login and see organization data
- [ ] Appointments can be created, accepted, and completed
- [ ] Patients can book appointments with org context
- [ ] Multi-org selection works when doctor has 2+ orgs
- [ ] Data isolation between organizations is enforced
- [ ] Doctor can see their appointments in mobile app
- [ ] All web portal pages load without errors
- [ ] Migration script successfully added organizationId
- [ ] API endpoints return correct org-scoped data
- [ ] Edge cases handled gracefully
- [ ] Performance is acceptable (< 2s page loads)

---

## 🐛 Common Issues & Solutions

### Issue: "Failed to fetch" in web portal
**Solution**: 
- Check API is running on port 3000
- Check CORS configuration in `apps/api/src/main.ts`
- Verify network tab in browser dev tools

### Issue: No appointments showing in dashboard
**Solution**:
- Check user has organization membership
- Verify appointments have organizationId
- Check API response in network tab

### Issue: Organization selection dialog not appearing
**Solution**:
- Verify doctor has 2+ organization memberships
- Check doctor profile API returns memberships
- Check mobile app console for errors

### Issue: Appointment status not updating
**Solution**:
- Check API endpoint is being called
- Verify token is valid
- Check database for actual update

---

## 📝 Test Results Template

Use this template to record your test results:

```
Test Date: ___________
Tester: ___________

Test 1: Admin Login ............... [ PASS / FAIL ]
Test 2: Appointment Management .... [ PASS / FAIL ]
Test 3: Patient Booking ........... [ PASS / FAIL ]
Test 4: Multi-Org Selection ....... [ PASS / FAIL ]
Test 5: Data Isolation ............ [ PASS / FAIL ]
Test 6: Doctor Dashboard .......... [ PASS / FAIL ]
Test 7: Navigation ................ [ PASS / FAIL ]
Test 8: Data Migration ............ [ PASS / FAIL ]
Test 9: API Endpoints ............. [ PASS / FAIL ]

Edge Cases Tested: ___________
Performance: ___________
Issues Found: ___________
```

---

## 🚀 Next Steps After Testing

Once all tests pass:
1. Document any bugs found
2. Create tickets for Phase 6 features
3. Plan production deployment
4. Set up monitoring and logging
5. Create user documentation

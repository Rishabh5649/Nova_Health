---
description: Migration plan for Multi-Organization Tenancy
---

# Multi-Organization Tenancy & Role-Based Access Control

## Overview
Implement a comprehensive multi-organization system with flexible role-based access control (Admin, Receptionist, Doctor) where:
- Admins have full control over their organization
- Receptionists are optional (configurable per organization)
- Admins must approve new doctors and receptionists

## Database Changes

### 1. Add Pending Status to OrganizationMembership
```prisma
model OrganizationMembership {
  // ... existing fields
  status String @default("PENDING") // PENDING, APPROVED, REJECTED
  approvedBy String? // userId of admin who approved
  approvedAt DateTime?
}
```

### 2. Add Organization Settings
```prisma
model OrganizationSettings {
  id             String   @id @default(uuid())
  organizationId String   @unique
  
  // Receptionist Settings
  enableReceptionists Boolean @default(false)
  
  // Other settings
  allowPatientBooking Boolean @default(true)
  requireApprovalForDoctors Boolean @default(true)
  
  organization Organization @relation(fields: [organizationId], references: [id])
}
```

## Backend Implementation

### 1. Update Prisma Schema
- Add `status`, `approvedBy`, `approvedAt` to OrganizationMembership
- Create OrganizationSettings model
- Run migration

### 2. Create Organization Settings Service
- CRUD operations for organization settings
- Default settings on organization creation

### 3. Update Auth Service
- When doctor/receptionist registers, create membership with PENDING status
- Admin registration creates APPROVED membership automatically

### 4. Create Staff Management Endpoints (Admin Module)
```
POST   /admin/organizations/:orgId/staff/invite
GET    /admin/organizations/:orgId/staff/pending
PATCH  /admin/organizations/:orgId/staff/:membershipId/approve
PATCH  /admin/organizations/:orgId/staff/:membershipId/reject
DELETE /admin/organizations/:orgId/staff/:membershipId
GET    /admin/organizations/:orgId/staff
```

### 5. Update Authorization Guards
- Create OrgRole decorator for organization-level permissions
- Create OrgPermission guard that checks:
  - User is member of organization
  - Membership is APPROVED
  - User has required role (ORG_ADMIN, RECEPTIONIST, DOCTOR)
- Admin can perform all receptionist actions
- Receptionist can only access if enabled in OrganizationSettings

### 6. Permission Matrix

| Feature | Patient | Doctor | Receptionist | Admin |
|---------|---------|--------|--------------|-------|
| View own appointments | ✓ | ✓ | ✗ | ✗ |
| Book appointments | ✓ | ✗ | ✓* | ✓ |
| Cancel appointments | ✓ | ✓ | ✓* | ✓ |
| View all appointments | ✗ | Own only | All in org* | All in org |
| Create prescriptions | ✗ | ✓ | ✗ | ✗ |
| View prescriptions | Own only | Own patients | All in org* | All in org |
| Add doctors | ✗ | ✗ | ✗ | ✓ |
| Add receptionists | ✗ | ✗ | ✗ | ✓ |
| Approve staff | ✗ | ✗ | ✗ | ✓ |
| View org data | ✗ | Own only | All* | All |
| Org settings | ✗ | ✗ | ✗ | ✓ |

\* Only if receptionists are enabled

## Frontend Implementation

### Admin Web (Next.js)

#### 1. Organization Settings Page
- Toggle receptionist feature
- Other org preferences

#### 2. Staff Management Page
- Pending approvals list
- Active staff list
- Invite new staff (doctor/receptionist)
- Approve/reject/remove staff

#### 3. Dashboard Updates
- Show pending approvals count
- Quick approve/reject actions

### Flutter App

#### 1. Registration Flow
- After doctor/receptionist registers, show "Pending Approval" screen
- Poll for approval status
- Redirect to dashboard once approved

#### 2. Admin Dashboard
- Pending staff approvals
- Staff management

## Migration Steps

// turbo-all

1. Update Prisma Schema
```bash
cd apps/api
# Edit schema.prisma
npx prisma migrate dev --name add_org_membership_approval
npx prisma generate
```

2. Update Seed Data
```bash
npx ts-node prisma/seed.ts
```

3. Implement Backend Services
- OrganizationSettings service
- Staff management in admin service
- Update guards

4. Update Admin Web UI
- Settings page
- Staff management

5. Update Flutter App
- Pending approval screen
- Admin features

## Testing Scenarios

1. **Small Clinic (No Receptionists)**
   - Admin handles everything
   - Receptionist toggle is OFF
   - Receptionist endpoints return 403

2. **Large Hospital (With Receptionists)**
   - Admin enables receptionist feature
   - Receptionist can manage appointments
   - Admin can do everything receptionist can

3. **Staff Approval**
   - New doctor registration → PENDING
   - Admin approves → APPROVED, can login
   - Admin rejects → REJECTED, cannot login

4. **Permission Tests**
   - Receptionist cannot add doctors
   - Receptionist cannot access settings
   - Admin can perform all actions

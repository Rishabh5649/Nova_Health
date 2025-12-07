const API_URL = 'http://127.0.0.1:3000';

export async function login(email: string, password: string) {
    const res = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
    });

    if (!res.ok) {
        const error = await res.json();
        throw new Error(error.message || 'Login failed');
    }

    return res.json();
}

export async function getOrganizations(token: string) {
    const res = await fetch(`${API_URL}/organizations`, {
        headers: {
            'Authorization': `Bearer ${token}`,
        },
    });

    if (!res.ok) {
        throw new Error('Failed to fetch organizations');
    }

    return res.json();
}

export async function getAppointments(token: string, organizationId?: string, status?: string, patientId?: string) {
    const params = new URLSearchParams();
    if (organizationId) {
        params.append('organizationId', organizationId);
    }
    if (status) {
        params.append('status', status);
    }
    if (patientId) {
        params.append('patientId', patientId);
    }

    const res = await fetch(`${API_URL}/appointments?${params.toString()}`, {
        headers: {
            'Authorization': `Bearer ${token}`,
        },
    });

    if (!res.ok) {
        throw new Error('Failed to fetch appointments');
    }

    return res.json();
}

export async function updateAppointmentStatus(token: string, appointmentId: string, action: 'confirm' | 'reject' | 'complete') {
    const res = await fetch(`${API_URL}/appointments/${appointmentId}/${action}`, {
        method: 'PATCH',
        headers: {
            'Authorization': `Bearer ${token}`,
        },
    });

    if (!res.ok) {
        throw new Error(`Failed to ${action} appointment`);
    }

    return res.json();
}

export async function createPrescription(token: string, data: any) {
    const res = await fetch(`${API_URL}/prescriptions`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    });

    if (!res.ok) {
        throw new Error('Failed to create prescription');
    }

    return res.json();
}

export async function getDoctors(token: string) {
    const res = await fetch(`${API_URL}/doctors`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch doctors');
    return res.json();
}

export async function createAppointment(token: string, data: any) {
    const res = await fetch(`${API_URL}/appointments/request`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to create appointment');
    return res.json();
}

export async function checkEligibility(token: string, patientId: string, doctorId: string) {
    const params = new URLSearchParams({ patientId, doctorId });
    const res = await fetch(`${API_URL}/appointments/check-eligibility?${params.toString()}`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to check eligibility');
    return res.json();
}

export async function updateOrganization(token: string, id: string, data: any) {
    const res = await fetch(`${API_URL}/organizations/${id}`, {
        method: 'PATCH',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to update organization');
    return res.json();
}

// Organization Settings
export async function getOrganizationSettings(token: string, orgId: string) {
    const res = await fetch(`${API_URL}/organizations/${orgId}/settings`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch organization settings');
    return res.json();
}

export async function updateOrganizationSettings(token: string, orgId: string, data: any) {
    const res = await fetch(`${API_URL}/organizations/${orgId}/settings`, {
        method: 'PATCH',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to update organization settings');
    return res.json();
}

// Staff Management
export async function getPendingStaff(token: string, orgId: string) {
    const res = await fetch(`${API_URL}/organizations/${orgId}/staff/pending`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch pending staff');
    return res.json();
}

export async function getAllStaff(token: string, orgId: string, status?: string) {
    const params = status ? `?status=${status}` : '';
    const res = await fetch(`${API_URL}/organizations/${orgId}/staff${params}`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch staff');
    return res.json();
}

export async function updateStaffStatus(token: string, orgId: string, membershipId: string, status: 'APPROVED' | 'REJECTED') {
    const res = await fetch(`${API_URL}/organizations/${orgId}/staff/${membershipId}`, {
        method: 'PATCH',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status }),
    });
    if (!res.ok) throw new Error(`Failed to ${status.toLowerCase()} staff member`);
    return res.json();
}

export async function removeStaff(token: string, orgId: string, membershipId: string) {
    const res = await fetch(`${API_URL}/organizations/${orgId}/staff/${membershipId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to remove staff member');
    return res.json();
}

export async function getOrganization(token: string, id: string) {
    const res = await fetch(`${API_URL}/organizations/${id}`, {
        headers: {
            'Authorization': `Bearer ${token}`,
        },
    });

    if (!res.ok) {
        throw new Error('Failed to fetch organization details');
    }

    return res.json();
}

export async function getOrganizationPatients(token: string, orgId: string, search?: string) {
    const params = search ? `?search=${encodeURIComponent(search)}` : '';
    const res = await fetch(`${API_URL}/organizations/${orgId}/patients${params}`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch patients');
    return res.json();
}

export async function getDoctorProfile(token: string, userId: string) {
    const res = await fetch(`${API_URL}/doctors/${userId}`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch doctor profile');
    return res.json();
}

export async function updateDoctorProfile(token: string, orgId: string, userId: string, data: any) {
    const res = await fetch(`${API_URL}/organizations/${orgId}/doctors/${userId}`, {
        method: 'PATCH',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to update doctor profile');
    return res.json();
}

export async function getAppointment(token: string, id: string) {
    const res = await fetch(`${API_URL}/appointments/${id}`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch appointment');
    return res.json();
}

export async function getDoctorAvailability(token: string, userId: string) {
    const res = await fetch(`${API_URL}/doctors/${userId}/availability`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch doctor availability');
    return res.json();
}

export async function setDoctorAvailability(token: string, userId: string, workHours: any[]) {
    const res = await fetch(`${API_URL}/doctors/${userId}/availability`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ workHours }),
    });
    if (!res.ok) throw new Error('Failed to set doctor availability');
    return res.json();
}

export async function getDoctorTimeOff(token: string, userId: string, from?: string, to?: string) {
    const params = new URLSearchParams();
    if (from) params.append('from', from);
    if (to) params.append('to', to);

    const res = await fetch(`${API_URL}/doctors/${userId}/timeoff?${params.toString()}`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch doctor time off');
    return res.json();
}

export async function addDoctorTimeOff(token: string, userId: string, data: { startTime: string; endTime: string; reason?: string }) {
    const res = await fetch(`${API_URL}/doctors/${userId}/timeoff`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to add time off');
    return res.json();
}

export async function removeDoctorTimeOff(token: string, id: string) {
    const res = await fetch(`${API_URL}/doctors/timeoff/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to remove time off');
    return res.json();
}

// Reschedule API functions
export async function getRescheduleRequests(token: string, organizationId?: string, status?: string) {
    const params = new URLSearchParams();
    if (organizationId) params.append('organizationId', organizationId);
    if (status) params.append('status', status);

    const res = await fetch(`${API_URL}/appointments/reschedule-requests/all?${params}`, {
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to fetch reschedule requests');
    return res.json();
}

export async function approveRescheduleRequest(token: string, requestId: string) {
    const res = await fetch(`${API_URL}/appointments/reschedule-requests/${requestId}/approve`, {
        method: 'PATCH',
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to approve reschedule request');
    return res.json();
}

export async function rejectRescheduleRequest(token: string, requestId: string) {
    const res = await fetch(`${API_URL}/appointments/reschedule-requests/${requestId}/reject`, {
        method: 'PATCH',
        headers: { 'Authorization': `Bearer ${token}` },
    });
    if (!res.ok) throw new Error('Failed to reject reschedule request');
    return res.json();
}

export async function directReschedule(token: string, appointmentId: string, scheduledAt: string) {
    const res = await fetch(`${API_URL}/appointments/${appointmentId}/direct-reschedule`, {
        method: 'PATCH',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ scheduledAt }),
    });
    if (!res.ok) throw new Error('Failed to reschedule appointment');
    return res.json();
}

export const cancelAppointmentAsPatient = async (token: string, appointmentId: string, reason?: string) => {
    const res = await fetch(`${API_URL}/appointments/${appointmentId}/cancel`, {
        method: 'PATCH',
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ reason }),
    });
    if (!res.ok) throw new Error('Failed to cancel appointment');
    return res.json();
};

export const cancelAppointmentAsAdmin = async (token: string, appointmentId: string, reason: string) => {
    const res = await fetch(`${API_URL}/appointments/${appointmentId}/cancel`, {
        method: 'PATCH',
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ reason }),
    });
    if (!res.ok) throw new Error('Failed to cancel appointment');
    return res.json();
};

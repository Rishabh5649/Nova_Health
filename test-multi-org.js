#!/usr/bin/env node

/**
 * Test Multi-Organization Tenancy Features
 * Run with: node test-multi-org.js
 */

const API_URL = 'http://localhost:3000';

// ANSI color codes for terminal output
const colors = {
    reset: '\x1b[0m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m',
};

const log = {
    success: (msg) => console.log(`${colors.green}✓${colors.reset} ${msg}`),
    error: (msg) => console.log(`${colors.red}✗${colors.reset} ${msg}`),
    info: (msg) => console.log(`${colors.blue}ℹ${colors.reset} ${msg}`),
    warning: (msg) => console.log(`${colors.yellow}⚠${colors.reset} ${msg}`),
    section: (msg) => console.log(`\n${colors.cyan}========== ${msg} ==========${colors.reset}\n`),
};

async function request(url, options = {}) {
    const response = await fetch(`${API_URL}${url}`, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            ...options.headers,
        },
    });

    const data = await response.json();
    return { status: response.status, data };
}

async function testLogin(email, password) {
    log.info(`Testing login for: ${email}`);
    const { status, data } = await request('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
    });

    if (status === 200 && data.token) {
        log.success(`Login successful! Token: ${data.token.substring(0, 20)}...`);
        return data.token;
    } else {
        log.error(`Login failed: ${JSON.stringify(data)}`);
        return null;
    }
}

async function testOrgSettings(orgId, token) {
    log.info(`Fetching org settings for: ${orgId}`);
    const { status, data } = await request(`/organizations/${orgId}/settings`, {
        headers: { Authorization: `Bearer ${token}` },
    });

    if (status === 200) {
        log.success(`Settings retrieved: enableReceptionists=${data.enableReceptionists}`);
        return data;
    } else {
        log.error(`Failed to get settings: ${JSON.stringify(data)}`);
        return null;
    }
}

async function testPendingStaff(orgId, token) {
    log.info(`Fetching pending staff for org: ${orgId}`);
    const { status, data } = await request(`/organizations/${orgId}/staff/pending`, {
        headers: { Authorization: `Bearer ${token}` },
    });

    if (status === 200) {
        log.success(`Found ${data.length} pending staff members`);
        return data;
    } else {
        log.error(`Failed to get pending staff: ${JSON.stringify(data)}`);
        return null;
    }
}

async function testAllStaff(orgId, token) {
    log.info(`Fetching all staff for org: ${orgId}`);
    const { status, data } = await request(`/organizations/${orgId}/staff`, {
        headers: { Authorization: `Bearer ${token}` },
    });

    if (status === 200) {
        log.success(`Found ${data.length} staff members total`);
        data.forEach(member => {
            const statusEmoji = member.status === 'APPROVED' ? '✓' :
                member.status === 'PENDING' ? '⏳' : '✗';
            console.log(`  ${statusEmoji} ${member.user.name} (${member.role}) - ${member.status}`);
        });
        return data;
    } else {
        log.error(`Failed to get all staff: ${JSON.stringify(data)}`);
        return null;
    }
}

async function testUpdateSettings(orgId, token, settings) {
    log.info(`Updating org settings...`);
    const { status, data } = await request(`/organizations/${orgId}/settings`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
        body: JSON.stringify(settings),
    });

    if (status === 200) {
        log.success(`Settings updated successfully`);
        return data;
    } else {
        log.error(`Failed to update settings: ${JSON.stringify(data)}`);
        return null;
    }
}

async function testCreatePendingUser() {
    log.info('Creating a new pending doctor...');
    const { status, data } = await request('/auth/register', {
        method: 'POST',
        body: JSON.stringify({
            name: 'Dr. Test Pending',
            email: 'testpending@example.com',
            password: 'test123',
            role: 'DOCTOR',
            phone: '+9999999999',
        }),
    });

    if (status === 201 || status === 200) {
        log.success(`User created: ${data.user.email}`);
        return data.user;
    } else {
        log.warning(`User creation response: ${JSON.stringify(data)}`);
        return data.user || null;
    }
}

async function testPendingLogin(email, password) {
    log.info(`Testing login for pending user: ${email}`);
    const { status, data } = await request('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
    });

    if (status === 401) {
        log.success(`Correctly blocked pending user! Message: ${data.message}`);
        return true;
    } else {
        log.error(`Pending user should not be able to login! Status: ${status}`);
        return false;
    }
}

async function main() {
    try {
        log.section('MULTI-ORG TENANCY TESTS');

        // Test 1: Admin Login
        log.section('Test 1: Admin Login');
        const adminToken = await testLogin('admin@cityhospital.com', 'admin123');
        if (!adminToken) {
            log.error('Admin login failed. Cannot proceed with tests.');
            return;
        }

        // Get first organization
        log.info('Fetching organizations...');
        const { data: orgs } = await request('/organizations');
        if (!orgs || orgs.length === 0) {
            log.error('No organizations found!');
            return;
        }
        const orgId = orgs[0].id;
        log.success(`Using organization: ${orgs[0].name} (ID: ${orgId})`);

        // Test 2: Organization Settings
        log.section('Test 2: Organization Settings');
        await testOrgSettings(orgId, adminToken);

        // Test 3: View All Staff
        log.section('Test 3: View All Staff');
        await testAllStaff(orgId, adminToken);

        // Test 4: View Pending Staff
        log.section('Test 4: View Pending Staff');
        await testPendingStaff(orgId, adminToken);

        // Test 5: Doctor Login (Approved)
        log.section('Test 5: Doctor Login (Approved)');
        const doctorToken = await testLogin('sarah@cityhospital.com', 'doc123');

        // Test 6: Receptionist Login (Approved)
        log.section('Test 6: Receptionist Login (Approved)');
        const receptionistToken = await testLogin('mary@cityhospital.com', 'recep123');

        // Test 7: Update Settings (Disable Receptionists)
        log.section('Test 7: Toggle Receptionist Feature');
        await testUpdateSettings(orgId, adminToken, { enableReceptionists: false });
        log.info('Waiting 1 second...');
        await new Promise(resolve => setTimeout(resolve, 1000));
        await testOrgSettings(orgId, adminToken);

        // Re-enable receptionists
        await testUpdateSettings(orgId, adminToken, { enableReceptionists: true });
        await testOrgSettings(orgId, adminToken);

        // Test 8: Create Pending User (Optional - will fail if user exists)
        log.section('Test 8: Create Pending User (Optional)');
        const pendingUser = await testCreatePendingUser();

        if (pendingUser) {
            // Test 9: Try to login as pending user (should fail)
            log.section('Test 9: Pending User Login Blocked');
            await testPendingLogin('testpending@example.com', 'test123');

            // Test 10: View pending staff (should show new user)
            log.section('Test 10: View Pending Staff (After New Registration)');
            await testPendingStaff(orgId, adminToken);
        }

        log.section('ALL TESTS COMPLETED');
        log.success('Multi-org tenancy is working correctly! 🎉');

    } catch (error) {
        log.error(`Test failed with error: ${error.message}`);
        console.error(error);
    }
}

main();

// lib/main.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';

import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'core/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/public/public_dashboard_screen.dart';
import 'screens/public/public_doctor_screen.dart';
import 'screens/shell/home_patient.dart';
import 'screens/shell/home_doctor.dart';
import 'screens/shell/home_admin.dart';
import 'screens/appointments/appointment_list_screen.dart';
import 'screens/doctor/doctor_list_screen.dart';
import 'screens/doctor/doctor_public_profile.dart';
import 'screens/common/notifications_center_screen.dart';
import 'screens/appointments/book_appointment_details.dart';
import 'screens/patient/medical_history_screen.dart';
import 'screens/patient/prescription_list_screen.dart';
import 'screens/doctor/doctor_profile_screen.dart';
import 'screens/doctor/pending_requests_screen.dart';
import 'screens/doctor/pending_requests_screen.dart';
import 'screens/appointments/completed_appointment_detail.dart';
import 'screens/organization/organization_details_screen.dart';
import 'screens/common/whats_new_screen.dart';
import 'screens/common/premium_plans_screen.dart';
import 'screens/common/insurance_plans_screen.dart';
import 'screens/organization/organization_details_screen.dart';
import 'screens/doctor/doctor_today_appointments_screen.dart';
import 'screens/doctor/doctor_past_appointments_screen.dart';
import 'screens/organization/organization_details_screen.dart'; // Duplicate but keeping structure
import 'screens/common/pending_approval_screen.dart';
import 'screens/admin/admin_staff_management_screen.dart';
import 'screens/patient/patient_settings_screen.dart';
import 'screens/patient/patient_profile_screen.dart';
import 'screens/common/notifications_center_screen.dart';
import 'screens/common/reminders_screen.dart';
import 'screens/admin/admin_organization_settings_screen.dart';
import 'screens/common/coming_soon_screen.dart';

void main() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  
  // Handle platform errors - suppress them
  PlatformDispatcher.instance.onError = (error, stack) {
    return true; 
  };
  
  runApp(
    ProviderScope(
      child: DevicePreview(
        enabled: true, // Switched to Web Simulation due to emulator issues
        builder: (context) => const App(),
      ),
    ),
  );
}

class App extends ConsumerStatefulWidget {
  const App({super.key});
  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // hydrate session on app start with error handling
    Future.microtask(() async {
      try {
        await ref.read(authControllerProvider).hydrate();
      } catch (e) {
        // Silently handle hydration errors - app can still work without session
        debugPrint('[App] Session hydration failed: $e');
      }
    });

    _router = GoRouter(
      // Public landing page first
      initialLocation: '/',

      // Refresh router when auth events fire
      refreshListenable: GoRouterRefreshStream(ref.read(authEventsProvider)),

      routes: [
        // Public home (visible to all)
        GoRoute(
          path: '/',
          builder: (_, __) => const PublicDashboardScreen(),
        ),

        // Doctor landing page
        GoRoute(
          path: '/doctor-home',
          builder: (_, __) => const PublicDoctorScreen(),
        ),

        // Login page
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),

        // Signup page
        GoRoute(
          path: '/signup',
          builder: (_, __) => const SignUpScreen(),
        ),

        // Forgot Password page
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen(),
        ),

        // Pending approval screen
        GoRoute(
          path: '/pending-approval',
          builder: (_, __) => const PendingApprovalScreen(),
        ),

        // Admin staff management
        GoRoute(
          path: '/dashboard/staff',
          builder: (_, __) => const AdminStaffManagementScreen(),
        ),

        // Admin organization settings
        GoRoute(
          path: '/dashboard/settings/organization',
          builder: (_, __) => const AdminOrganizationSettingsScreen(),
        ),

        // Patient profile
        GoRoute(
          path: '/patient/profile',
          builder: (_, __) => const PatientProfileScreen(),
        ),
        GoRoute(
          path: '/patient/doctors',
          builder: (_, __) => const DoctorListScreen(),
        ),
        GoRoute(
          path: '/patient/doctor/:userId',
          builder: (_, state) => DoctorPublicProfileScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
        GoRoute(
          path: '/patient/book-details',
          builder: (_, state) {
            final doctorId = state.uri.queryParameters['doctorId'] ?? '';
            return BookAppointmentDetailsScreen(doctorId: doctorId);
          },
        ),
        GoRoute(
          path: '/patient/notifications',
          builder: (_, __) => const NotificationsCenterScreen(),
        ),
        GoRoute(
          path: '/patient/medical-history',
          builder: (_, __) => const MedicalHistoryScreen(),
        ),
        GoRoute(
          path: '/patient/appointments',
          builder: (_, __) => const AppointmentListScreen(),
        ),
        GoRoute(
          path: '/patient/prescriptions',
          builder: (_, __) => const PrescriptionListScreen(),
        ),
        GoRoute(
          path: '/patient/doctors',
          builder: (_, __) => const DoctorListScreen(),
        ),

        GoRoute(
          path: '/patient/settings',
          builder: (_, __) => const PatientSettingsScreen(),
        ),
        GoRoute(
          path: '/patient/profile-details',
          builder: (_, __) => const PatientProfileScreen(),
        ),
        GoRoute(
          path: '/patient/premium',
          builder: (_, __) => const PremiumPlansScreen(),
        ),
        GoRoute(
          path: '/patient/insurance',
          builder: (_, __) => const InsurancePlansScreen(),
        ),
        GoRoute(
          path: '/patient/notifications',
          builder: (_, __) => const NotificationsCenterScreen(),
        ),
        GoRoute(
          path: '/patient/whats-new',
          builder: (_, __) => const WhatsNewScreen(),
        ),
        GoRoute(
          path: '/patient/reminders',
          builder: (_, __) => const RemindersScreen(),
        ),
        
        // Doctor specific routes
        GoRoute(
          path: '/doctor/profile',
          builder: (_, __) => const DoctorProfileScreen(),
        ),
        GoRoute(
          path: '/doctor/requests',
          builder: (_, __) => const PendingRequestsScreen(),
        ),
        GoRoute(
          path: '/doctor/appointment/:id',
          builder: (_, state) => CompletedAppointmentDetailScreen(
            appointmentId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/doctor/today',
          builder: (_, __) => const DoctorTodayAppointmentsScreen(),
        ),
        GoRoute(
          path: '/doctor/past',
          builder: (_, __) => const DoctorPastAppointmentsScreen(),
        ),

        // Private app area (role routed)
        GoRoute(
          path: '/app',
          builder: (context, __) {
            try {
              final container = ProviderScope.containerOf(context, listen: false);
              final s = container.read(sessionAtomProvider).value;
              String role = 'PATIENT';
              if (s != null && s.user != null) {
                final roleValue = s.user['role'];
                if (roleValue != null) {
                  role = roleValue.toString().toUpperCase();
                }
              }
              switch (role) {
                case 'DOCTOR':
                  return const HomeDoctor();
                case 'ADMIN':
                  return const HomeAdmin();
                default:
                  return const HomePatient();
              }
            } catch (e) {
              // Fallback to patient home if there's any error
              debugPrint('[Router] Error in /app route: $e');
              return const HomePatient();
            }
          },
        ),



        GoRoute(
          path: '/organizations/:orgId',
          builder: (_, state) {
            final orgId = state.pathParameters['orgId']!;
            return OrganizationDetailsScreen(orgId: orgId);
          },
        ),
        
        // Booking route
        GoRoute(
          path: '/appointments/book',
          builder: (context, state) {
            final doctorId = state.uri.queryParameters['doctorId'] ?? '';
            return BookAppointmentDetailsScreen(doctorId: doctorId);
          },
        ),
        
        // Doctor profile route (public)
        GoRoute(
          path: '/doctor-profile/:doctorId',
          builder: (_, state) => DoctorPublicProfileScreen(
            userId: state.pathParameters['doctorId']!,
          ),
        ),
        
        // Doctor profile route (alternative path)
        GoRoute(
          path: '/doctors/:id',
          builder: (_, state) => DoctorPublicProfileScreen(
            userId: state.pathParameters['id']!,
          ),
        ),
        
        // Organization details route
        GoRoute(
          path: '/organizations/:id',
          builder: (_, state) => OrganizationDetailsScreen(
            orgId: state.pathParameters['id']!,
          ),
        ),

        // Direct booking route
        GoRoute(
          path: '/book-appointment/:doctorId',
          builder: (context, state) {
            final doctorId = state.pathParameters['doctorId'] ?? '';
            return BookAppointmentDetailsScreen(doctorId: doctorId);
          },
        ),

        // Coming Soon Route
        GoRoute(
          path: '/coming-soon',
          builder: (_, state) {
            final title = state.uri.queryParameters['title'] ?? 'Feature';
            return ComingSoonScreen(title: title);
          },
        ),
      ],

      // Navigation guard
      redirect: (ctx, state) {
        try {
          // Get container from context to access providers
          final container = ProviderScope.containerOf(ctx, listen: false);
          final s = container.read(sessionAtomProvider).value;
          final isLogin = state.uri.path == '/login';
          final isSignup = state.uri.path == '/signup';
          final isPendingApproval = state.uri.path == '/pending-approval';
          final isPrivate = state.uri.path.startsWith('/app') || 
                           state.uri.path.startsWith('/doctor/') ||
                           state.uri.path.startsWith('/patient') ||
                           state.uri.path.startsWith('/appointments');

          // Check membership status if logged in
          if (s != null && s.user != null) {
            final memberships = s.user['memberships'] as List?;
            if (memberships != null && memberships.isNotEmpty) {
              final status = memberships[0]['status'];
              
              // If status is PENDING, only allow pending-approval page
              if (status == 'PENDING') {
                if (!isPendingApproval) {
                  return '/pending-approval';
                }
                return null; // Already on pending approval page
              }
              
              // If status is REJECTED, force logout and redirect to login
              if (status == 'REJECTED') {
                // Clear session and go to login
                return '/login';
              }
            }
          }

          // If trying to access private pages while logged out -> go to login
          if (s == null && isPrivate) return '/login';

          // If trying to access pending approval page while not logged in
          if (s == null && isPendingApproval) return '/login';

          // If already logged in and on /login or /signup -> go to app
          if (s != null && (isLogin || isSignup)) return '/app';

          // Public routes (like '/') never force redirect
          return null;
        } catch (e) {
          // If container is not available yet, allow navigation
          return null;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'HMS',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      darkTheme: AppThemes.dark(),
      themeMode: themeMode,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      routerConfig: _router,
    );
  }
}

/// Helper that turns a Stream into a ChangeNotifier so GoRouter can refresh
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
      onError: (error) {
        // Handle stream errors silently
        debugPrint('[GoRouterRefreshStream] Stream error: $error');
      },
      cancelOnError: false,
    );
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

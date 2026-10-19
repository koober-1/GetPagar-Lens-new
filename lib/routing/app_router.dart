import 'package:go_router/go_router.dart';

import 'package:getpagar_lens/features/auth/login/login_screen.dart';
import 'package:getpagar_lens/models/employee_model.dart';

import 'package:getpagar_lens/screens/attendance/attendance_camera_screen.dart';
import 'package:getpagar_lens/screens/employee/employee_profile_screen.dart';

import 'package:getpagar_lens/screens/face_registration/registration_camera_screen.dart';
import 'package:getpagar_lens/screens/face_registration/registration_instruction_screen.dart';
import 'package:getpagar_lens/screens/face_registration/registration_success_screen.dart';

import 'package:getpagar_lens/screens/home/home_shell_screen.dart';
import 'package:getpagar_lens/screens/home/tabs/employee_tab_screen.dart';
import 'package:getpagar_lens/screens/home/tabs/logs_tab_screen.dart';
import 'package:getpagar_lens/screens/home/tabs/face_preview_screen.dart';

import 'package:getpagar_lens/screens/setting/setting_screen.dart';
import 'package:getpagar_lens/screens/welcome/welcome_screen.dart';

import 'app_routes.dart';
import 'auth_notifier.dart';

final authNotifier = AuthNotifier();

final appRouter = GoRouter(
  // ============================================================
  // INITIAL LOCATION
  // ============================================================
  initialLocation: AppRoutes.login,

  refreshListenable: authNotifier,

  // ============================================================
  // REDIRECT
  // ============================================================
  redirect: (context, state) {
    // ----------------------------------------------------------
    // WAIT FOR AUTH INITIALIZATION
    // ----------------------------------------------------------

    if (!authNotifier.initialized) {
      return null;
    }

    final currentRoute = state.matchedLocation;

    final isLoginPage = currentRoute == AppRoutes.login;

    final isWelcomePage = currentRoute == AppRoutes.welcome;

    // ----------------------------------------------------------
    // NOT LOGGED IN
    // ----------------------------------------------------------

    if (!authNotifier.loggedIn) {
      // If user is not logged in, only Login is allowed.
      if (!isLoginPage) {
        return AppRoutes.login;
      }

      return null;
    }

    // ==========================================================
    // LOGGED IN
    // ==========================================================

    // ----------------------------------------------------------
    // WELCOME SCREEN
    // ----------------------------------------------------------
    //
    // IMPORTANT:
    // Do NOT redirect away from Welcome Screen here.
    //
    // The login flow controls the Welcome Screen using
    // postLoginRoute.
    //
    // This keeps your existing Welcome logic.
    // ----------------------------------------------------------

    if (isWelcomePage) {
      return null;
    }

    // ----------------------------------------------------------
    // LOGIN PAGE
    // ----------------------------------------------------------

    if (isLoginPage) {
      // ========================================================
      // FIRST LOGIN / WELCOME FLOW
      // ========================================================
      //
      // If login() has provided a postLoginRoute, use it.
      //
      // Example:
      //
      // Login
      //   ↓
      // Welcome
      //   ↓
      // Employee
      //
      // ========================================================

      if (authNotifier.postLoginRoute != null &&
          authNotifier.postLoginRoute!.isNotEmpty) {
        return authNotifier.postLoginRoute!;
      }

      // ========================================================
      // APP RESTART FLOW
      // ========================================================
      //
      // employeeScreen = true
      // attendanceCamera = true
      //
      //              ↓
      //
      // Attendance Camera
      //
      // ========================================================

      if (authNotifier.employeeScreen && authNotifier.attendanceCamera) {
        return AppRoutes.attendanceCamera;
      }

      // ========================================================
      // APP RESTART FLOW
      // ========================================================
      //
      // employeeScreen = true
      // attendanceCamera = false
      //
      //              ↓
      //
      // Employee Screen
      //
      // ========================================================

      if (authNotifier.employeeScreen && !authNotifier.attendanceCamera) {
        return AppRoutes.employee;
      }

      // ========================================================
      // SAFE FALLBACK
      // ========================================================

      return AppRoutes.employee;
    }

    // ----------------------------------------------------------
    // EVERYTHING ELSE
    // ----------------------------------------------------------

    return null;
  },

  // ============================================================
  // ROUTES
  // ============================================================
  routes: [
    // ==========================================================
    // LOGIN
    // ==========================================================
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    // ==========================================================
    // WELCOME
    // ==========================================================
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) {
        final mobile = authNotifier.loginMobile;

        // Safety fallback.
        if (mobile == null || mobile.isEmpty) {
          return const LoginScreen();
        }

        return WelcomeScreen(mobile: mobile);
      },
    ),

    // ==========================================================
    // SETTING
    // ==========================================================
    GoRoute(
      path: AppRoutes.setting,
      builder: (context, state) {
        return const SettingScreen();
      },
    ),

    // ==========================================================
    // FACE PREVIEW
    // ==========================================================
    GoRoute(
      path: AppRoutes.facePreview,
      builder: (context, state) {
        final imagePath = state.extra as String;

        return FacePreviewScreen(imagePath: imagePath);
      },
    ),

    // ==========================================================
    // REGISTRATION INSTRUCTIONS
    // ==========================================================
    GoRoute(
      path: AppRoutes.registrationInstructions,
      builder: (context, state) {
        final employee = state.extra as EmployeeModel;

        return RegistrationInstructionScreen(employee: employee);
      },
    ),

    // ==========================================================
    // REGISTRATION CAMERA
    // ==========================================================
    GoRoute(
      path: AppRoutes.registrationCamera,
      builder: (context, state) {
        final employee = state.extra as EmployeeModel;

        return RegistrationCameraScreen(employee: employee);
      },
    ),

    // ==========================================================
    // REGISTRATION SUCCESS
    // ==========================================================
    GoRoute(
      path: AppRoutes.registrationSuccess,
      builder: (context, state) {
        final employee = state.extra as EmployeeModel;

        return RegistrationSuccessScreen(employee: employee);
      },
    ),

    // ==========================================================
    // EMPLOYEE PROFILE
    // ==========================================================
    GoRoute(
      path: AppRoutes.employeeProfile,
      builder: (context, state) {
        final employee = state.extra as EmployeeModel;

        return EmployeeProfileScreen(employee: employee);
      },
    ),

    // ==========================================================
    // ATTENDANCE CAMERA
    // ==========================================================
    GoRoute(
      path: AppRoutes.attendanceCamera,
      builder: (context, state) {
        return const AttendanceCameraScreen();
      },
    ),

    // ==========================================================
    // HOME SHELL
    // ==========================================================
    ShellRoute(
      builder: (context, state, child) {
        return HomeShellScreen(child: child);
      },

      routes: [
        // ======================================================
        // EMPLOYEE
        // ======================================================
        GoRoute(
          path: AppRoutes.employee,
          builder: (context, state) {
            return const EmployeeTabScreen();
          },
        ),

        // ======================================================
        // LOGS
        // ======================================================
        GoRoute(
          path: AppRoutes.logs,
          builder: (context, state) {
            return const LogsTabScreen();
          },
        ),
      ],
    ),
  ],
);

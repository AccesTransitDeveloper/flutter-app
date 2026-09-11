import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/router/app_navigation.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/bottom_nav_visibility_provider.dart';
import '../../data/repository/app_repository.dart';
import '../../viewmodels/activity_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/inbox_viewmodel.dart';
import '../../viewmodels/main_viewmodel.dart';
import '../../views/bottomsheets/logout_bottom_sheet.dart';
import '../../views/widgets/app_bottom_nav_bar.dart';
import '../../views/widgets/app_text.dart';
import 'profile/account_screen.dart';
import 'activity/activity_screen.dart';
import 'booking/plan_ride_screen.dart';
import 'support/inbox_screen.dart';
import 'booking/current_ride_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  final Set<int> _visitedTabs = {0}; // Only Home is built initially

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial entity refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - refreshing entity detail');
      ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
    }
  }

  void _onTabChanged(int index) {
    final previousIndex = _currentNavIndex;
    setState(() {
      _currentNavIndex = index;
      _visitedTabs.add(index);
    });

    // Switching tabs always re-reveals the bar.
    ref.read(bottomNavVisibleProvider.notifier).state = true;

    // Refresh entity detail and information status when switching back to home tab
    if (index == 0 && previousIndex != 0) {
      debugPrint('📱 Switched to home tab - refreshing entity detail & information status');
      ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
      ref.read(homeViewModelProvider.notifier).getInformationStatus();
    }

    // Refresh Activity tab data on every visit
    if (index == 1) {
      ref.invalidate(activityViewModelProvider);
    }

    // Refresh Inbox tab data on every visit
    if (index == 2) {
      ref.invalidate(inboxViewModelProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainState = ref.watch(mainViewModelProvider);
    final navVisible = ref.watch(bottomNavVisibleProvider);

    // Blocked user — show full-screen blocked view, no bottom nav
    final entityStatus = mainState.entity?.status;
    if (entityStatus == EntityTypeStatus.block) {
      return Scaffold(
        body: _BlockedCustomerScreen(
          onLogout: () => _handleLogout(context),
          onContactUs: () => context.navigateToContactUs(),
        ),
      );
    }

    // Determine which widget to show in the first tab (home position)
    // Use ValueKey to ensure Flutter properly disposes/creates widgets
    // when switching between HomeScreen and CurrentRideScreen, instead of
    // trying to update in-place which causes IndexedStack assertion errors.
    final activeBookingId = mainState.firstBookingId;
    Widget homeOrCurrentRide;
    if (activeBookingId != null) {
      homeOrCurrentRide = CurrentRideScreen(
        key: ValueKey('current_ride_$activeBookingId'),
        bookingId: activeBookingId,
      );
    } else {
      // The landing tab is "Plan your ride" itself — the old home screen had
      // been reduced to a card that only opened this, so it is skipped rather
      // than made a step on the way. citySetting and the booking types still
      // come from HomeViewModel, which is what fetches the vehicle types.
      final homeState = ref.watch(homeViewModelProvider);
      homeOrCurrentRide = PlanRideScreen(
        key: const ValueKey('plan_ride_root'),
        isRoot: true,
        initialPickupAddress: homeState.pickupAddress,
        citySetting: homeState.vehicleTypeResponse?.citySetting,
        rideTypeItems: homeState.rideTypeItems,
      );
    }

    return PopScope(
      // Allow the OS to minimize/exit only when already on the home tab
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Not on home tab — navigate to home first
          _onTabChanged(0);
        }
      },
      child: Scaffold(
        // Let content scroll behind the translucent floating nav bar.
        extendBody: true,
        body: IndexedStack(
          index: _currentNavIndex,
          // Delivery tab is hidden — this build ships taxi only. To restore it,
          // re-insert `const DeliveryScreen()` at index 1 (and its nav item in
          // AppBottomNavBar), then shift the tab indices below back by one.
          children: [
            homeOrCurrentRide,
            if (_visitedTabs.contains(1))
              ActivityScreen(
                showBackButton: false,
                onNavigateToHome: () => _onTabChanged(0),
              )
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(2))
              const InboxScreen(showBackButton: false)
            else
              const SizedBox.shrink(),
            if (_visitedTabs.contains(3))
              const AccountScreen()
            else
              const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          offset: navVisible ? Offset.zero : const Offset(0, 1.6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: navVisible ? 1 : 0,
            child: AppBottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: _onTabChanged,
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => LogoutBottomSheet(
        isLoading: false,
        onLogout: _performLogout,
      ),
    );
  }

  Future<void> _performLogout() async {
    final appRepository = ref.read(appRepositoryProvider);
    await appRepository.signOut();
    final sharedPref = ref.read(sharedPreferenceManagerProvider).maybeWhen(
          data: (data) => data,
          orElse: () => null,
        );
    await sharedPref?.signOut();
    if (mounted) {
      context.navigateToLogin();
    }
  }
}

/// Full-screen view for blocked users — only logout and contact us available
class _BlockedCustomerScreen extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onContactUs;

  const _BlockedCustomerScreen({
    required this.onLogout,
    required this.onContactUs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block_rounded,
                size: 100,
                color: colors.colorTertiary,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              AppText.title(
                getString(appStr.errorNotApprovedYet, 'error_not_approved_yet'),
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingM),
              AppText.body(
                getString(appStr.descriptionYourAccountIsBlocked, 'description_your_account_is_blocked'),
                textAlign: TextAlign.center,
                color: colors.colorText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppDimens.paddingXL * 2),
              // Logout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.colorButtonBackground,
                    foregroundColor: colors.colorButtonText,
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: AppText.body(
                    getString(appStr.buttonLogout, 'button_logout'),
                    fontWeight: FontWeight.w600,
                    color: colors.colorButtonText,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.paddingM),
              // Contact Us button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onContactUs,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.colorText,
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: colors.colorText.withValues(alpha: 0.3)),
                  ),
                  child: AppText.body(
                    getString(appStr.buttonContactUs, 'button_contact_us'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

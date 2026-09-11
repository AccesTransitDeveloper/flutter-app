import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/managers/permission_manager.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/common_utils.dart';
import '../../../models/ride_for_other_result.dart';
import '../../bottomsheets/new_rider_form_bottom_sheet.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toolbar.dart';

/// Full-screen contact picker for choosing a rider.
/// Shows device contacts with search, and frequent contacts section.
class ChooseRiderScreen extends StatefulWidget {
  final List<RideForOtherResult> recentRiders;
  final String defaultCountryCode;

  const ChooseRiderScreen({
    super.key,
    this.recentRiders = const [],
    required this.defaultCountryCode,
  });

  @override
  State<ChooseRiderScreen> createState() => _ChooseRiderScreenState();
}

class _ChooseRiderScreenState extends State<ChooseRiderScreen> {
  final _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final result = await PermissionManager.instance.requestContacts();

    if (result != PermissionResult.granted) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
      }
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      sorted: true,
    );

    if (mounted) {
      setState(() {
        _contacts = contacts
            .where((c) => c.phones.isNotEmpty)
            .toList();
        _filteredContacts = _contacts;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredContacts = _contacts);
      return;
    }
    setState(() {
      _filteredContacts = _contacts.where((c) {
        final name = c.displayName.toLowerCase();
        final phone = c.phones.first.number.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  Future<void> _onContactSelected(Contact contact) async {
    final phone = contact.phones.first;
    final phoneNumber = phone.number.replaceAll(RegExp(r'[^\d+]'), '');

    // Extract country code if phone starts with +
    String? countryCode;
    String cleanNumber = phoneNumber;
    if (phoneNumber.startsWith('+')) {
      countryCode = _extractCountryCode(phoneNumber);
      if (countryCode != null) {
        cleanNumber = phoneNumber.substring(countryCode.length);
      }
    }

    final nameParts = contact.displayName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

    // Navigate to edit screen pre-filled with contact data
    final result = await Navigator.push<RideForOtherResult>(
      context,
      MaterialPageRoute(
        builder: (_) => NewRiderFormScreen(
          defaultCountryCode: widget.defaultCountryCode,
          initialFirstName: firstName,
          initialLastName: lastName,
          initialPhone: cleanNumber,
          initialCountryCode: countryCode,
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  String? _extractCountryCode(String phoneNumber) {
    // First try matching the default country code
    if (phoneNumber.startsWith(widget.defaultCountryCode)) {
      return widget.defaultCountryCode;
    }
    // Otherwise just return the default — we don't have a country code database
    // and guessing by length gives wrong results (e.g. +9114 instead of +91)
    return null;
  }

  Future<void> _openNewRiderForm() async {
    final result = await Navigator.push<RideForOtherResult>(
      context,
      MaterialPageRoute(
        builder: (_) => NewRiderFormScreen(
          defaultCountryCode: widget.defaultCountryCode,
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  void _onRecentRiderSelected(RideForOtherResult rider) {
    Navigator.pop(context, rider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingChooseARider, 'heading_choose_a_rider'),
              onBack: () => Navigator.pop(context),
              rightIcon: Icons.person_add_outlined,
              onRightIconPressed: _openNewRiderForm,
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.padding,
                vertical: AppDimens.paddingS,
              ),
              child: AppTextField(
                controller: _searchController,
                hintText: getString(appStr.hintSearchNameOrNumber, 'hint_search_name_or_number'),
                prefixIcon: Icon(Icons.search, color: colors.colorText),
                fillColor: colors.colorBackgroundGray,
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _permissionDenied
                      ? _buildPermissionDenied(colors)
                      : _buildContactsList(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(AppColorPalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts_outlined,
                size: 64, color: colors.colorText.withValues(alpha: 0.3)),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              getString(appStr.descriptionContactsPermissionRequired, 'description_contacts_permission_required'),
              textAlign: TextAlign.center,
              color: colors.colorText.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppDimens.padding),
            AppTextButton(
              text: getString(appStr.buttonOpenSettings, 'button_open_settings'),
              onPressed: () => PermissionManager.instance.openSettings(),
            ),
            const SizedBox(height: AppDimens.paddingM),
            AppTextButton(
              text: getString(appStr.buttonAddManually, 'button_add_manually'),
              onPressed: _openNewRiderForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(AppColorPalette colors) {
    return CustomScrollView(
      slivers: [
        // Frequent contacts section
        if (widget.recentRiders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.padding,
                AppDimens.padding,
                AppDimens.padding,
                AppDimens.paddingS,
              ),
              child: AppText.body(
                getString(appStr.descriptionFrequentContacts, 'description_frequent_contacts'),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colors.colorText,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final rider = widget.recentRiders[index];
                return _ContactItem(
                  name: rider.displayName,
                  phone:
                      '${rider.countryPhoneCode ?? ''}${rider.phone ?? ''}',
                  colors: colors,
                  onTap: () => _onRecentRiderSelected(rider),
                );
              },
              childCount: widget.recentRiders.length,
            ),
          ),
        ],

        // Device contacts section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.padding,
              AppDimens.padding,
              AppDimens.padding,
              AppDimens.paddingS,
            ),
            child: AppText.body(
              getString(appStr.descriptionDeviceContacts, 'description_device_contacts'),
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colors.colorText,
            ),
          ),
        ),
        if (_filteredContacts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingXL),
              child: Center(
                child: AppText.body(
                  _searchController.text.isEmpty
                      ? getString(appStr.descriptionNoContactsFound, 'description_no_contacts_found')
                      : getString(appStr.descriptionNoMatchingContacts, 'description_no_matching_contacts'),
                  color: colors.colorText.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final contact = _filteredContacts[index];
                final phone = contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : '';
                return _ContactItem(
                  name: contact.displayName,
                  phone: phone,
                  colors: colors,
                  onTap: () => _onContactSelected(contact),
                );
              },
              childCount: _filteredContacts.length,
            ),
          ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final String name;
  final String phone;
  final AppColorPalette colors;
  final VoidCallback onTap;

  const _ContactItem({
    required this.name,
    required this.phone,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(name);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.colorPrimary,
              child: AppText.body(
                initials,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    name,
                    fontWeight: FontWeight.w500,
                    color: colors.colorText,
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AppText.caption(
                      phone,
                      color: colors.colorText.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

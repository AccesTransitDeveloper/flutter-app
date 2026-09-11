import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../views/widgets/app_text.dart';

class DatePickerBottomSheet extends StatefulWidget {
  final DateTime? initialDate;

  const DatePickerBottomSheet({
    super.key,
    this.initialDate,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DatePickerBottomSheet(
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  late DateTime _selectedDate;
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  final _years = List.generate(50, (index) => DateTime.now().year + index);
  final _months = List.generate(12, (index) => index + 1);

  List<int> get _days {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 365));
    _selectedYear = _selectedDate.year;
    _selectedMonth = _selectedDate.month;
    _selectedDay = _selectedDate.day;
  }

  bool get _isPastDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _selectedDate.isBefore(today);
  }

  void _updateSelectedDate() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    if (_selectedDay > daysInMonth) {
      _selectedDay = daysInMonth;
    }
    _selectedDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.paddingL),
          topRight: Radius.circular(AppDimens.paddingL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AppText.body(
                      getString(appStr.buttonCancel, 'button_cancel'),
                      color: colors.colorText,
                    ),
                  ),
                  AppText.title(
                    getString(appStr.headingSelectDate, 'heading_select_date'),
                    fontWeight: FontWeight.w600,
                  ),
                  TextButton(
                    onPressed: _isPastDate
                        ? null
                        : () => Navigator.pop(context, _selectedDate),
                    child: AppText.body(
                      getString(appStr.buttonDone, 'button_done'),
                      color: _isPastDate
                          ? colors.colorTextHint
                          : colors.colorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.colorBackgroundGray),

            // Date Pickers
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Day Picker
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: _selectedDay - 1,
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedDay = index + 1;
                          _updateSelectedDate();
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _days.length,
                        builder: (context, index) {
                          final isSelected = _days[index] == _selectedDay;
                          return Center(
                            child: AppText.body(
                              _days[index].toString().padLeft(2, '0'),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colors.colorText
                                  : colors.colorText,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Month Picker
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: _selectedMonth - 1,
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMonth = index + 1;
                          _updateSelectedDate();
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _months.length,
                        builder: (context, index) {
                          final isSelected = _months[index] == _selectedMonth;
                          return Center(
                            child: AppText.body(
                              _getMonthName(_months[index]),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colors.colorText
                                  : colors.colorText,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Year Picker
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: _years.indexOf(_selectedYear),
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedYear = _years[index];
                          _updateSelectedDate();
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _years.length,
                        builder: (context, index) {
                          final isSelected = _years[index] == _selectedYear;
                          return Center(
                            child: AppText.body(
                              _years[index].toString(),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colors.colorText
                                  : colors.colorText,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

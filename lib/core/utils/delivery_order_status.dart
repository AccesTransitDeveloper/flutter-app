import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

/// Delivery / quick-commerce order status — mirrors the native `OrderStatus`
/// enum (QDeliveryEnums.swift). Provides display label + colour buckets
/// (yellow = requested, orange = merchant stages, green = driver stages,
/// blue = on-the-way, red = cancelled) matching native `getStatus`.
class DeliveryOrderStatus {
  static const int requested = 1;
  static const int assigned = 10;
  static const int noDriverFound = 11;
  static const int rejected = 13;
  static const int merchantAccepted = 14;
  static const int noPickerFound = 16;
  static const int accepted = 20;
  static const int pickerCompleted = 24;
  static const int inRoute = 30;
  static const int arrivedAtPickup = 40;
  static const int picked = 41;
  static const int started = 50;
  static const int arrivedNearDestination = 65;
  static const int arrivedAtDestination = 70;
  static const int completed = 80;
  static const int cancelled = 90;
  static const int merchantPreparing = 141;
  static const int merchantCompleted = 142;

  static bool isCancelled(int? s) => s == cancelled || s == rejected;
  static bool isCompleted(int? s) => s == completed;

  /// Customer-facing status = (label, colour), mirroring native customer
  /// `UtilityQDelivery.getStatus`. While the order is still at the merchant
  /// (booking status < picked/41) the label comes from the MERCHANT sub-status
  /// (`quickCommerce.status`); once picked up (41+) it reflects the delivery
  /// partner's progress. Pass merchantStatus null when it isn't available.
  static ({String label, Color color}) resolve(
      int? status, int? merchantStatus) {
    final s = status ?? assigned;
    final ms = merchantStatus ?? merchantAccepted;

    if (s == cancelled || s == rejected) {
      return (
        label: getString(null, 'delivery_status_order_cancelled'),
        color: _red
      );
    }
    if (s == completed) {
      return (
        label: getString(null, 'delivery_status_delivered'),
        color: _green
      );
    }

    if (s < picked) {
      // Merchant stage — driven by the merchant sub-status.
      if (ms <= requested) {
        return (
          label: getString(null, 'delivery_status_order_placed'),
          color: _yellow
        );
      }
      if (ms <= pickerCompleted) {
        return (
          label: getString(null, 'delivery_status_restaurant_accepted'),
          color: _orange
        );
      }
      if (ms <= merchantPreparing) {
        return (
          label: getString(null, 'delivery_status_preparing_your_order'),
          color: _orange
        );
      }
      return (
        label: getString(null, 'delivery_status_order_ready_pickup'),
        color: _orange
      );
    }

    // Delivery-partner stage.
    if (s <= picked) {
      return (
        label: getString(null, 'delivery_status_order_picked_up'),
        color: _green
      );
    }
    if (s <= started) {
      return (
        label: getString(null, 'delivery_status_out_for_delivery'),
        color: _blue
      );
    }
    if (s <= arrivedNearDestination) {
      return (
        label: getString(null, 'delivery_status_arriving_soon'),
        color: _blue
      );
    }
    if (s <= arrivedAtDestination) {
      return (
        label: getString(null, 'delivery_status_partner_arrived'),
        color: _green
      );
    }
    return (
      label: getString(null, 'delivery_status_on_the_way'),
      color: _green
    );
  }

  static String label(int? s) {
    switch (s) {
      case requested:
        return getString(null, 'delivery_status_requested');
      case merchantAccepted:
        return getString(null, 'delivery_status_merchant_accepted');
      case merchantPreparing:
        return getString(null, 'delivery_status_preparing');
      case merchantCompleted:
        return getString(null, 'delivery_status_merchant_completed');
      case assigned:
        return getString(null, 'delivery_status_driver_assigned');
      case noDriverFound:
        return getString(null, 'delivery_status_finding_driver');
      case accepted:
        return getString(null, 'description_accepted');
      case inRoute:
        return getString(null, 'delivery_status_on_the_way_to_store');
      case arrivedAtPickup:
        return getString(null, 'delivery_status_arrived_at_store');
      case picked:
        return getString(null, 'delivery_status_order_picked_up_caps');
      case started:
        return getString(null, 'delivery_status_out_for_delivery_caps');
      case arrivedNearDestination:
        return getString(null, 'delivery_status_arriving_soon_caps');
      case arrivedAtDestination:
        return getString(null, 'delivery_status_arrived');
      case completed:
        return getString(null, 'delivery_status_delivered');
      case cancelled:
        return getString(null, 'description_cancelled');
      case rejected:
        return getString(null, 'description_rejected');
      default:
        return getString(null, 'delivery_status_ongoing');
    }
  }

  /// A descriptive status line for the order card banner (like native's
  /// "Waiting for merchant to accept your order").
  static String message(int? s) {
    switch (s) {
      case requested:
        return getString(null, 'delivery_msg_waiting_merchant');
      case merchantAccepted:
        return getString(null, 'delivery_msg_merchant_accepted');
      case merchantPreparing:
        return getString(null, 'delivery_msg_being_prepared');
      case merchantCompleted:
        return getString(null, 'delivery_msg_order_ready');
      case assigned:
      case accepted:
        return getString(null, 'delivery_msg_partner_assigned');
      case noDriverFound:
        return getString(null, 'delivery_msg_finding_partner');
      case inRoute:
        return getString(null, 'delivery_msg_partner_heading_store');
      case arrivedAtPickup:
        return getString(null, 'delivery_msg_partner_reached_store');
      case picked:
        return getString(null, 'delivery_status_order_picked_up');
      case started:
        return getString(null, 'delivery_status_out_for_delivery');
      case arrivedNearDestination:
        return getString(null, 'delivery_msg_partner_arriving_soon');
      case arrivedAtDestination:
        return getString(null, 'delivery_status_partner_arrived');
      case completed:
        return getString(null, 'delivery_order_delivered');
      case cancelled:
        return getString(null, 'delivery_status_order_cancelled');
      case rejected:
        return getString(null, 'delivery_order_rejected');
      default:
        return getString(null, 'delivery_msg_order_in_progress');
    }
  }

  /// A past order is terminal — it's either cancelled/rejected or delivered.
  /// Live-progress messages ("Delivery partner has arrived") are misleading in
  /// history, so collapse everything non-cancelled to "Order delivered".
  static String historyMessage(int? s) {
    if (s == cancelled) return getString(null, 'delivery_status_order_cancelled');
    if (s == rejected) return getString(null, 'delivery_order_rejected');
    return getString(null, 'delivery_order_delivered');
  }

  static Color historyColor(int? s) {
    if (s == cancelled || s == rejected) return _red;
    return _green;
  }

  static const Color _yellow = Color(0xFFE0A100);
  static const Color _orange = Color(0xFFE07A1F);
  static const Color _green = Color(0xFF3AA757);
  static const Color _blue = Color(0xFF2E7CE4);
  static const Color _red = Color(0xFFD64545);
  static const Color _grey = Color(0xFF8A8F98);

  static Color color(int? s) {
    if (s == null) return _grey;
    if (s == cancelled || s == rejected) return _red;
    if (s == completed) return _green;
    if (s == requested) return _yellow;
    if (s == merchantAccepted ||
        s == merchantPreparing ||
        s == merchantCompleted) {
      return _orange;
    }
    if (s == started) return _blue;
    if (s >= assigned && s <= arrivedAtDestination) return _green;
    return _grey;
  }
}

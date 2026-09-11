import '../core/constants/app_constants.dart';
import 'responses/booking/get_vehicle_type_response.dart';

/// Represents a ride type item displayed on the home screen.
/// Can be either a booking type (Normal, Share, Rental, FixGroup) or a specific vehicle.
class RideTypeItem {
  final String? imgUrl;
  final String typeName;
  final RideType type;
  final bool isVisible;
  final NormalVehicles? vehicleType;

  const RideTypeItem({
    this.imgUrl,
    required this.typeName,
    required this.type,
    this.isVisible = true,
    this.vehicleType,
  });

  RideTypeItem copyWith({
    String? imgUrl,
    String? typeName,
    RideType? type,
    bool? isVisible,
    NormalVehicles? vehicleType,
  }) {
    return RideTypeItem(
      imgUrl: imgUrl ?? this.imgUrl,
      typeName: typeName ?? this.typeName,
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}

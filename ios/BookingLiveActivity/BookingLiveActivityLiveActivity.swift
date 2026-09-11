//
//  BookingLiveActivityLiveActivity.swift
//  BookingLiveActivity
//
//  Created by urvish kaneriya on 13/03/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// NOTE: BookingLiveActivityAttributes is defined in BookingActivityAttribute.swift

struct BookingLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BookingLiveActivityAttributes.self) { context in
            // Lock screen / banner UI
            BookingCardView(
                attributes: context.attributes,
                state: context.state
            )
            .padding(14)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IdentityRow(attributes: context.attributes)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    MapPanelView(
                        progress: context.state.progress,
                        destinationPoint: context.state.destinationPoint,
                        status: context.state.status
                    )
                    .frame(width: 92, height: 76)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TripRows(attributes: context.attributes)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundStyle(statusColor(for: context.state.status))
            } compactTrailing: {
                Text(statusString(for: context.state.status))
                    .font(.caption2)
                    .foregroundStyle(statusColor(for: context.state.status))
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundStyle(statusColor(for: context.state.status))
            }
        }
    }
}

// MARK: - Card

struct BookingCardView: View {
    let attributes: BookingLiveActivityAttributes
    let state: BookingLiveActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                IdentityRow(attributes: attributes)
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(height: 1)
                TripRows(attributes: attributes)
                Spacer(minLength: 0)
            }

            MapPanelView(
                progress: state.progress,
                destinationPoint: state.destinationPoint,
                status: state.status
            )
            .frame(width: 100, height: 92)
        }
    }
}

struct IdentityRow: View {
    let attributes: BookingLiveActivityAttributes

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(photoPath: attributes.photoPath, name: attributes.driverName)

            VStack(alignment: .leading, spacing: 2) {
                if !attributes.driverName.isEmpty {
                    Text(attributes.driverName)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                if !attributes.vehicleName.isEmpty {
                    Text(attributes.vehicleName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 6)

            if !attributes.plateNo.isEmpty {
                Text(attributes.plateNo)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.08))
                    )
            }
        }
    }
}

struct AvatarView: View {
    let photoPath: String
    let name: String

    private var image: UIImage? {
        guard !photoPath.isEmpty else { return nil }
        return UIImage(contentsOfFile: photoPath)
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.primary.opacity(0.1)
                    if initials.isEmpty {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(initials)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())
    }
}

struct TripRows: View {
    let attributes: BookingLiveActivityAttributes

    var body: some View {
        let hasPickup = !attributes.pickupAddress.isEmpty
        let hasDrop = !attributes.destinationAddress.isEmpty
        VStack(alignment: .leading, spacing: 0) {
            if hasPickup {
                TripRow(
                    systemIcon: "location.north.fill",
                    iconColor: Color(red: 0.18, green: 0.49, blue: 0.9),
                    text: attributes.pickupAddress,
                    time: attributes.pickupTime
                )
            }
            if hasPickup && hasDrop {
                // Dotted connector aligned under the icon column (icon frame = 18).
                HStack(spacing: 8) {
                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))
                        .foregroundStyle(.secondary)
                        .frame(width: 18, height: 10)
                    Spacer()
                }
            }
            if hasDrop {
                TripRow(
                    systemIcon: "mappin.circle.fill",
                    iconColor: Color(red: 0.88, green: 0.48, blue: 0.12),
                    text: attributes.destinationAddress,
                    time: attributes.destinationTime
                )
            }
        }
    }
}

/// A vertical line — stroked with a dash pattern for the pickup→drop connector.
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

struct TripRow: View {
    let systemIcon: String
    let iconColor: Color
    let text: String
    let time: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemIcon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 6)
            if !time.isEmpty {
                Text(time)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StatusBadge: View {
    let status: Int

    var body: some View {
        Text(statusString(for: status))
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(statusColor(for: status))
            )
            .lineLimit(1)
    }
}

// MARK: - Stylised map panel

/// The map panel — a bundled map illustration (WidgetKit can't host MapKit or
/// load remote tiles) with the live status badge overlaid top-trailing.
struct MapPanelView: View {
    let progress: Int
    let destinationPoint: Int
    let status: Int

    var body: some View {
        Image("live_map")
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .topTrailing) {
                StatusBadge(status: status)
                    .padding(5)
            }
    }
}

// MARK: - Status helpers

func statusString(for status: Int) -> String {
    switch status {
    case 1, 10, 16: return "Finding"
    case 14, 141: return "Preparing"
    case 20, 21, 24, 142: return "Accepted"
    case 30: return "En route"
    case 40: return "At pickup"
    case 41: return "Picked up"
    case 50: return "On trip"
    case 65: return "Arriving"
    case 70: return "Arrived"
    case 80: return "Done"
    case 90: return "Cancelled"
    default: return "Ongoing"
    }
}

func statusColor(for status: Int) -> Color {
    switch status {
    case 90: return Color(red: 0.84, green: 0.27, blue: 0.27)      // red
    case 70, 80: return Color(red: 0.23, green: 0.66, blue: 0.34)  // green
    case 14, 141, 24, 142: return Color(red: 0.88, green: 0.48, blue: 0.12) // orange
    default: return Color(red: 0.18, green: 0.49, blue: 0.9)       // blue
    }
}

// MARK: - Dynamic Island compact ring

struct ActivityProgressView: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3)
                .foregroundStyle(Color.gray)
                .opacity(0.5)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundStyle(Color.cyan)
                .rotationEffect(.radians(-.pi / 2))
        }
        .frame(width: 20, height: 20)
        .padding(.leading, 5)
    }
}

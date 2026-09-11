// Server-driven view-config models for the delivery dynamic-group design.
// These mirror the the native user app config schema (GridViewConfig,
// GridChildViewConfig, TextConfigModel, BorderConfigModel, etc.) so the layout
// — text, colors, borders, padding, scroll type — is fully backend-driven.

double? _toD(dynamic v) => (v as num?)?.toDouble();
int? _toI(dynamic v) => (v as num?)?.toInt();

List<double> _toDList(dynamic v) {
  // Config arrays can contain nulls (e.g. "padding":[10,null,10,null]) — treat
  // null / non-numeric entries as 0 instead of throwing.
  if (v is! List) return const [];
  return v.map((e) => e is num ? e.toDouble() : 0.0).toList();
}

List<String> _toSList(dynamic v) =>
    (v as List<dynamic>?)?.whereType<String>().toList() ?? const [];

/// Text config: text + color + size + weight + position + padding.
class QText {
  final String? text;
  final String? color; // hex
  final int? fontSize;
  final int? fontWeight; // 100..900
  final List<String> position; // [INSIDE/OUTSIDE, TOP/BOTTOM/CENTER, L/R/CENTER]
  final List<double> padding; // [top, right, bottom, left]

  const QText({
    this.text,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.position = const [],
    this.padding = const [],
  });

  bool get isInside =>
      position.isNotEmpty && position.first.toUpperCase() == 'INSIDE';

  static QText? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QText(
      text: json['text'] as String?,
      color: json['color'] as String?,
      fontSize: _toI(json['fontSize']),
      fontWeight: _toI(json['fontWeight']),
      position: _toSList(json['position']),
      padding: _toDList(json['padding']),
    );
  }
}

/// Border config: color + width (size) + per-corner radius.
class QBorder {
  final String? color; // hex
  final double? size; // stroke width
  final List<double> radius; // [topLeft, topRight, bottomRight, bottomLeft]

  const QBorder({this.color, this.size, this.radius = const []});

  static QBorder? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QBorder(
      color: json['color'] as String?,
      size: _toD(json['size']),
      radius: _toDList(json['radius']),
    );
  }
}

/// Image config for a child cell.
class QImageConfig {
  final String? url;
  final List<double> padding;
  final List<double> margin;
  final double? width;
  final double? height;
  final String? bgColor;
  final QBorder? border;

  const QImageConfig({
    this.url,
    this.padding = const [],
    this.margin = const [],
    this.width,
    this.height,
    this.bgColor,
    this.border,
  });

  static QImageConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QImageConfig(
      url: json['url'] as String?,
      padding: _toDList(json['padding']),
      margin: _toDList(json['margin']),
      width: _toD(json['width']),
      height: _toD(json['height']),
      bgColor: json['bgColor'] as String?,
      border: QBorder.fromJson(json['border'] as Map<String, dynamic>?),
    );
  }
}

/// Per-child (cell) config: image + title + bg + padding + border.
class QGridChildConfig {
  final QImageConfig? image;
  final QText? title;
  final String? bgColor;
  final List<double> padding;
  final QBorder? border;
  final double? betweenPadding;

  const QGridChildConfig({
    this.image,
    this.title,
    this.bgColor,
    this.padding = const [],
    this.border,
    this.betweenPadding,
  });

  static QGridChildConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QGridChildConfig(
      image: QImageConfig.fromJson(json['image'] as Map<String, dynamic>?),
      title: QText.fromJson(json['title'] as Map<String, dynamic>?),
      bgColor: json['bgColor'] as String?,
      padding: _toDList(json['padding']),
      border: QBorder.fromJson(json['border'] as Map<String, dynamic>?),
      betweenPadding: _toD(json['betweenPadding']),
    );
  }
}

/// Grid config: columns, view type (STATIC/SCROLL/SLIDER), spacing, bg, border.
class QGridConfig {
  final List<double> padding;
  final String? bgColor;
  final QBorder? border;
  final double? betweenPadding;
  final int? maxColumnCount;
  final List<double> childPadding;
  final String? viewType; // STATIC / SCROLL / SLIDER

  const QGridConfig({
    this.padding = const [],
    this.bgColor,
    this.border,
    this.betweenPadding,
    this.maxColumnCount,
    this.childPadding = const [],
    this.viewType,
  });

  bool get isScroll => (viewType ?? '').toUpperCase() == 'SCROLL';
  bool get isSlider => (viewType ?? '').toUpperCase() == 'SLIDER';
  int get columns => maxColumnCount ?? 2;

  static QGridConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QGridConfig(
      padding: _toDList(json['padding']),
      bgColor: json['bgColor'] as String?,
      border: QBorder.fromJson(json['border'] as Map<String, dynamic>?),
      betweenPadding: _toD(json['betweenPadding']),
      maxColumnCount: _toI(json['maxColumnCount']),
      childPadding: _toDList(json['childPadding']),
      viewType: json['viewType'] as String?,
    );
  }
}

/// Outer group container config.
class QMainViewConfig {
  final String? viewType;
  final String? bgColor;
  final List<double> padding;
  final QBorder? border;

  const QMainViewConfig({
    this.viewType,
    this.bgColor,
    this.padding = const [],
    this.border,
  });

  static QMainViewConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QMainViewConfig(
      viewType: json['viewType'] as String?,
      bgColor: json['bgColor'] as String?,
      padding: _toDList(json['padding']),
      border: QBorder.fromJson(json['border'] as Map<String, dynamic>?),
    );
  }
}

/// Header/footer config: title + description + bg + padding + border + isShow.
class QHeaderFooter {
  final QText? title;
  final QText? description;
  final String? bgColor;
  final List<double> padding;
  final QBorder? border;
  final bool isShow;

  const QHeaderFooter({
    this.title,
    this.description,
    this.bgColor,
    this.padding = const [],
    this.border,
    this.isShow = false,
  });

  static QHeaderFooter? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QHeaderFooter(
      title: QText.fromJson(json['title'] as Map<String, dynamic>?),
      description: QText.fromJson(json['description'] as Map<String, dynamic>?),
      bgColor: json['bgColor'] as String?,
      padding: _toDList(json['padding']),
      border: QBorder.fromJson(json['border'] as Map<String, dynamic>?),
      isShow: (json['isShow'] as bool?) ?? false,
    );
  }
}

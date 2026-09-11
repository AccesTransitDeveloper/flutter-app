import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/delivery/delivery_config.dart';
import '../../../models/responses/delivery/delivery_responses.dart';
import 'delivery_color_util.dart';

// ── Config → Flutter helpers ──────────────────────────────────────

/// Native padding arrays are [top, right, bottom, left].
EdgeInsets qInsets(List<double> arr) {
  if (arr.isEmpty) return EdgeInsets.zero;
  final top = arr.isNotEmpty ? arr[0] : 0.0;
  final right = arr.length > 1 ? arr[1] : 0.0;
  final bottom = arr.length > 2 ? arr[2] : 0.0;
  final left = arr.length > 3 ? arr[3] : 0.0;
  return EdgeInsets.fromLTRB(left, top, right, bottom);
}

/// Native fontWeight (100..900) → Flutter FontWeight.
FontWeight qWeight(int? w) {
  switch (w) {
    case 100:
      return FontWeight.w100;
    case 200:
      return FontWeight.w200;
    case 300:
      return FontWeight.w300;
    case 400:
      return FontWeight.w400;
    case 500:
      return FontWeight.w500;
    case 600:
      return FontWeight.w600;
    case 700:
      return FontWeight.w700;
    case 800:
      return FontWeight.w800;
    case 900:
      return FontWeight.w900;
    default:
      return FontWeight.w400;
  }
}

/// Border radius from [topLeft, topRight, bottomRight, bottomLeft].
BorderRadius qRadius(QBorder? b) {
  final r = b?.radius ?? const [];
  if (r.isEmpty) return BorderRadius.zero;
  return BorderRadius.only(
    topLeft: Radius.circular(r.isNotEmpty ? r[0] : 0),
    topRight: Radius.circular(r.length > 1 ? r[1] : 0),
    bottomRight: Radius.circular(r.length > 2 ? r[2] : 0),
    bottomLeft: Radius.circular(r.length > 3 ? r[3] : 0),
  );
}

/// BoxDecoration from a bg color + border config.
BoxDecoration? qDecoration(String? bgColorHex, QBorder? border) {
  final bg = hexToColor(bgColorHex);
  final borderColor = hexToColor(border?.color);
  final borderWidth = border?.size ?? 0;
  final radius = qRadius(border);
  if (bg == null &&
      borderColor == null &&
      radius == BorderRadius.zero) {
    return null;
  }
  return BoxDecoration(
    color: bg,
    borderRadius: radius == BorderRadius.zero ? null : radius,
    border: (borderColor != null && borderWidth > 0)
        ? Border.all(color: borderColor, width: borderWidth)
        : null,
  );
}

/// Render a config-driven text. Falls back to [fallbackText] / theme color.
Widget qText(BuildContext context, QText? cfg,
    {String? fallbackText, TextAlign? align, int? maxLines}) {
  final text = cfg?.text ?? fallbackText ?? '';
  if (text.isEmpty) return const SizedBox.shrink();
  final color = hexToColor(cfg?.color) ?? context.colors.colorText;
  final widget = Text(
    text,
    textAlign: align,
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : null,
    style: TextStyle(
      color: color,
      fontSize: (cfg?.fontSize ?? 14).toDouble(),
      fontWeight: qWeight(cfg?.fontWeight),
    ),
  );
  final pad = cfg?.padding ?? const [];
  return pad.isEmpty ? widget : Padding(padding: qInsets(pad), child: widget);
}

// ── Widgets ───────────────────────────────────────────────────────

/// A full server-configured group section: header + grid + footer, wrapped in
/// the group's main-view container (bg / padding / border).
class DynamicGroupSection extends StatelessWidget {
  final DeliveryGroup group;

  const DynamicGroupSection({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    if (!group.isActive || group.products.isEmpty) {
      return const SizedBox.shrink();
    }

    final main = group.mainView;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (group.header?.isShow ?? false)
          _HeaderFooter(config: group.header!),
        _GroupGrid(group: group),
        if (group.footer?.isShow ?? false)
          _HeaderFooter(config: group.footer!),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: qInsets(main?.padding ?? const []),
      decoration: qDecoration(main?.bgColor, main?.border),
      child: content,
    );
  }
}

class _HeaderFooter extends StatelessWidget {
  final QHeaderFooter config;

  const _HeaderFooter({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: qInsets(config.padding),
      decoration: qDecoration(config.bgColor, config.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          qText(context, config.title),
          if (config.description?.text?.isNotEmpty ?? false)
            qText(context, config.description),
        ],
      ),
    );
  }
}

/// Grid honouring the group's viewType: STATIC (wrapped grid), SCROLL
/// (horizontal), or SLIDER (paged), with column count / spacing from config.
class _GroupGrid extends StatelessWidget {
  final DeliveryGroup group;

  const _GroupGrid({required this.group});

  @override
  Widget build(BuildContext context) {
    final grid = group.grid;
    final items = group.products;
    final between = grid?.betweenPadding ?? 12;
    final columns = grid?.columns ?? 2;

    Widget wrapper(Widget child) => Container(
          padding: qInsets(grid?.padding ?? const []),
          decoration: qDecoration(grid?.bgColor, grid?.border),
          child: child,
        );

    // SCROLL / SLIDER → horizontal rail. Native sizes each cell to
    // (width - gaps)/columns * 0.9 so the next item peeks in.
    if ((grid?.isScroll ?? false) || (grid?.isSlider ?? false)) {
      return wrapper(LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final cellW = (maxW - (columns - 1) * between) / columns * 0.9;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: qInsets(grid?.childPadding ?? const []),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(width: between),
                  SizedBox(
                    width: cellW,
                    child: _GroupCell(
                      merchant: items[i],
                      group: group,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ));
    }

    // STATIC → non-scrolling wrapped grid with fixed column count.
    return wrapper(Padding(
      padding: qInsets(grid?.childPadding ?? const []),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final cellW = (maxW - (columns - 1) * between) / columns;
          return Wrap(
            spacing: between,
            runSpacing: between,
            children: [
              for (final m in items)
                SizedBox(
                  width: cellW,
                  child: _GroupCell(merchant: m, group: group),
                ),
            ],
          );
        },
      ),
    ));
  }
}

/// A single cell: a square image (fills the cell width; shape/border/bg from
/// config, exactly like the native square+aspectRatio(1) sub-image), plus a
/// config-driven title below and a rating/prep subtitle for merchant groups.
class _GroupCell extends StatelessWidget {
  final Merchant merchant;
  final DeliveryGroup group;

  const _GroupCell({required this.merchant, required this.group});

  bool get _isMerchant => (group.childType ?? '').contains('MERCHANT');

  @override
  Widget build(BuildContext context) {
    final childCfg = group.child;
    final titleCfg = childCfg?.title;
    final isInside = titleCfg?.isInside ?? false;

    final imageBlock = _buildImageBlock(context, childCfg);

    if (isInside) {
      final title = qText(context, titleCfg,
          fallbackText: merchant.name, maxLines: 2);
      return Stack(
        children: [
          imageBlock,
          Positioned.fill(
            child: Align(alignment: _insideAlignment(titleCfg), child: title),
          ),
        ],
      );
    }

    // OUTSIDE title: honour horizontal (LEFT/CENTER/RIGHT) and vertical
    // (TOP → above image, BOTTOM → below).
    final cross = _outsideCross(titleCfg);
    final title = qText(context, titleCfg,
        fallbackText: merchant.name, maxLines: 2, align: _outsideAlign(titleCfg));
    final below = <Widget>[
      const SizedBox(height: 6),
      title,
      if (_isMerchant) _subtitle(context, cross),
    ];

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: _titleAbove(titleCfg)
          ? [title, const SizedBox(height: 6), imageBlock]
          : [imageBlock, ...below],
    );
  }

  /// Square image filling the cell width (config image width/height is not used
  /// for sizing — native fills the cell). The circle/rounded shape comes from
  /// CLIPPING the block by the child border radius (large radius → circle); the
  /// image border adds the inner shape/stroke. Only the image block is shaped,
  /// never the title, so a large radius yields a clean circle, not a stadium.
  Widget _buildImageBlock(BuildContext context, QGridChildConfig? childCfg) {
    final colors = context.colors;
    final imgCfg = childCfg?.image;
    final imgRadius = qRadius(imgCfg?.border);
    final childRadius = qRadius(childCfg?.border);
    final imgBg = hexToColor(imgCfg?.bgColor) ?? colors.colorBackgroundGray;
    final childBg = hexToColor(childCfg?.bgColor);
    final url = ServerConfig.getFullImageUrl(merchant.imageUrl);

    final picture = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: imgBg),
      errorWidget: (_, _, _) => Container(
        color: imgBg,
        child: Icon(Icons.storefront, color: colors.colorTextHint, size: 30),
      ),
    );

    // Inner square image, clipped by the image border radius.
    Widget square = AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: imgBg,
          borderRadius: imgRadius == BorderRadius.zero ? null : imgRadius,
          border: _stroke(imgCfg?.border),
        ),
        child: picture,
      ),
    );

    final imgPad = imgCfg?.padding ?? const [];
    if (imgPad.isNotEmpty) {
      square = Padding(padding: qInsets(imgPad), child: square);
    }

    // Outer child block: padding + bg + border, CLIPPED by the child radius so
    // a large radius (e.g. 100/150) turns the square into a circle.
    Widget block = Container(
      padding: qInsets(childCfg?.padding ?? const []),
      clipBehavior: childRadius == BorderRadius.zero ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        color: childBg,
        borderRadius: childRadius == BorderRadius.zero ? null : childRadius,
        border: _stroke(childCfg?.border),
      ),
      child: square,
    );

    final margin = imgCfg?.margin ?? const [];
    return margin.isEmpty
        ? block
        : Padding(padding: qInsets(margin), child: block);
  }

  CrossAxisAlignment _outsideCross(QText? cfg) {
    final pos = cfg?.position ?? const [];
    final h = pos.length > 2 ? pos[2].toUpperCase() : 'LEFT';
    if (h == 'CENTER') return CrossAxisAlignment.center;
    if (h == 'RIGHT') return CrossAxisAlignment.end;
    return CrossAxisAlignment.start;
  }

  TextAlign _outsideAlign(QText? cfg) {
    final pos = cfg?.position ?? const [];
    final h = pos.length > 2 ? pos[2].toUpperCase() : 'LEFT';
    if (h == 'CENTER') return TextAlign.center;
    if (h == 'RIGHT') return TextAlign.right;
    return TextAlign.left;
  }

  bool _titleAbove(QText? cfg) {
    final pos = cfg?.position ?? const [];
    return pos.length > 1 && pos[1].toUpperCase() == 'TOP';
  }

  Border? _stroke(QBorder? b) {
    final color = hexToColor(b?.color);
    final width = b?.size ?? 0;
    if (color == null || width <= 0) return null;
    return Border.all(color: color, width: width);
  }

  Widget _subtitle(BuildContext context, CrossAxisAlignment cross) {
    final colors = context.colors;
    final parts = <Widget>[];
    if (merchant.customerRate != null) {
      parts.add(Icon(Icons.star, size: 13, color: colors.colorPrimary));
      parts.add(const SizedBox(width: 2));
      parts.add(Text(merchant.customerRate!.toStringAsFixed(1),
          style: TextStyle(fontSize: 12, color: colors.colorTextHint)));
    }
    if (merchant.maxPreparationTime != null) {
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 8));
      parts.add(Text('${merchant.maxPreparationTime!.toInt()} min',
          style: TextStyle(fontSize: 12, color: colors.colorTextHint)));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    final main = cross == CrossAxisAlignment.center
        ? MainAxisAlignment.center
        : cross == CrossAxisAlignment.end
            ? MainAxisAlignment.end
            : MainAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: main,
          children: parts),
    );
  }

  Alignment _insideAlignment(QText? cfg) {
    final pos = cfg?.position ?? const [];
    if (pos.length < 3) return Alignment.center;
    final v = pos[1].toUpperCase();
    final h = pos[2].toUpperCase();
    final y = v == 'TOP'
        ? -1.0
        : v == 'BOTTOM'
            ? 1.0
            : 0.0;
    final x = h == 'LEFT'
        ? -1.0
        : h == 'RIGHT'
            ? 1.0
            : 0.0;
    return Alignment(x, y);
  }
}

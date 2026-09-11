import 'package:json_annotation/json_annotation.dart';

part 'invoice.g.dart';

@JsonSerializable()
class Invoice {
  final String? title;
  final String? subTitle;
  final bool? isFree;
  final String? discount;
  final String? amount;
  final List<InvoiceChild>? invoiceChild;

  Invoice({
    this.title,
    this.subTitle,
    this.isFree,
    this.discount,
    this.amount,
    this.invoiceChild,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  Invoice copyWith({
    String? title,
    String? subTitle,
    bool? isFree,
    String? discount,
    String? amount,
    List<InvoiceChild>? invoiceChild,
  }) {
    return Invoice(
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      isFree: isFree ?? this.isFree,
      discount: discount ?? this.discount,
      amount: amount ?? this.amount,
      invoiceChild: invoiceChild ?? this.invoiceChild,
    );
  }
}

@JsonSerializable()
class InvoiceChild {
  final String? title;
  final String? amount;

  InvoiceChild({
    this.title,
    this.amount,
  });

  factory InvoiceChild.fromJson(Map<String, dynamic> json) =>
      _$InvoiceChildFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceChildToJson(this);
}

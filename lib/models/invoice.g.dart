// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
  title: json['title'] as String?,
  subTitle: json['subTitle'] as String?,
  isFree: json['isFree'] as bool?,
  discount: json['discount'] as String?,
  amount: json['amount'] as String?,
  invoiceChild: (json['invoiceChild'] as List<dynamic>?)
      ?.map((e) => InvoiceChild.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
  'title': instance.title,
  'subTitle': instance.subTitle,
  'isFree': instance.isFree,
  'discount': instance.discount,
  'amount': instance.amount,
  'invoiceChild': instance.invoiceChild,
};

InvoiceChild _$InvoiceChildFromJson(Map<String, dynamic> json) => InvoiceChild(
  title: json['title'] as String?,
  amount: json['amount'] as String?,
);

Map<String, dynamic> _$InvoiceChildToJson(InvoiceChild instance) =>
    <String, dynamic>{'title': instance.title, 'amount': instance.amount};

/// Five optional, offline-available reasons in the app's selected language.
List<String> commonCancellationReasons(String language) {
  const reasons = {
    'en': ['Plans changed', 'Wait is too long', 'Booked by mistake', 'Found other transport', 'Incorrect address'],
    'ru': ['Планы изменились', 'Долго ждать', 'Заказал по ошибке', 'Нашёл другой транспорт', 'Неверный адрес'],
    'es': ['Cambiaron mis planes', 'La espera es demasiado larga', 'Reservé por error', 'Encontré otro transporte', 'Dirección incorrecta'],
    'ar': ['تغيرت الخطط', 'وقت الانتظار طويل', 'حجزت بالخطأ', 'وجدت وسيلة نقل أخرى', 'العنوان غير صحيح'],
    'zh': ['计划有变', '等待时间太长', '误操作下单', '已找到其他交通方式', '地址有误'],
    'hi': ['योजना बदल गई', 'इंतज़ार बहुत लंबा है', 'गलती से बुक किया', 'दूसरा वाहन मिल गया', 'पता गलत है'],
    'tr': ['Planlarım değişti', 'Bekleme süresi çok uzun', 'Yanlışlıkla rezervasyon yaptım', 'Başka ulaşım buldum', 'Adres yanlış'],
    'ja': ['予定が変わった', '待ち時間が長すぎる', '誤って予約した', '別の交通手段が見つかった', '住所が間違っている'],
  };
  return List.of(reasons[language.split('-').first] ?? reasons['en']!);
}

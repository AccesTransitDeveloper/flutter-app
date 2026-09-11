# Accessible Transit — Customer Flutter App

Flutter-приложение клиента Accessible Transit с нативным AT AI:

- текстовый и голосовой AI-ассистент;
- перенос подтверждённого маршрута в штатную форму поездки;
- существующие карта, оплата, booking и поиск водителя;
- Android и iOS проекты.

## Требования

- Flutter SDK, совместимый с `pubspec.lock`;
- Android Studio/Android SDK для Android;
- Xcode и CocoaPods для iOS;
- VS Code с расширениями Flutter и Dart.

Проверьте окружение:

```bash
flutter doctor
```

## Клонирование

```bash
git clone git@github.com:AccesTransitDeveloper/flutter-app.git
cd flutter-app
flutter pub get
```

## Локальные конфигурационные файлы

Секреты и production-конфигурации намеренно не хранятся в Git.

### Firebase

Получите конфигурации соответствующего Firebase-проекта и добавьте:

```text
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### Google Maps — Android

Flutter обычно создаёт `android/local.properties` автоматически. Добавьте в него:

```properties
MAPS_API_KEY=your-android-google-maps-key
```

Не удаляйте автоматически созданные строки `sdk.dir` и `flutter.sdk`.

### Google Maps — iOS

```bash
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
```

Затем замените значение `GOOGLE_MAPS_API_KEY`.

### Android release signing

Для debug-запуска keystore не нужен. Для release:

```bash
cp android/keystore.properties.example android/keystore.properties
```

Укажите путь к собственному `.jks` и данные подписи.

## Запуск приложения

Передайте опубликованный HTTPS URL AT AI backend и публичный Mapbox token:

```bash
flutter run \
  --dart-define=AT_AI_API_BASE_URL=https://transit-accesibleai.replit.app \
  --dart-define=MAPBOX_ACCESS_TOKEN=your-public-mapbox-token
```

Если основной API ещё не возвращает `googleServerClientId`, добавьте:

```text
--dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-oauth-client-id
```

Для выбора устройства:

```bash
flutter devices
flutter run -d DEVICE_ID \
  --dart-define=AT_AI_API_BASE_URL=https://transit-accesibleai.replit.app \
  --dart-define=MAPBOX_ACCESS_TOKEN=your-public-mapbox-token
```

Дополнительные сведения находятся в [AT_AI_INTEGRATION.md](AT_AI_INTEGRATION.md).

## Проверки перед release

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release \
  --dart-define=AT_AI_API_BASE_URL=https://transit-accesibleai.replit.app \
  --dart-define=MAPBOX_ACCESS_TOKEN=your-public-mapbox-token
```

Для iOS после `flutter pub get`:

```bash
cd ios
pod install
cd ..
flutter run \
  --dart-define=AT_AI_API_BASE_URL=https://transit-accesibleai.replit.app \
  --dart-define=MAPBOX_ACCESS_TOKEN=your-public-mapbox-token
```
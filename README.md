# Finance Tracker

Android-приложение для локального учёта доходов и расходов на Flutter.

## Запуск

```powershell
flutter pub get
flutter run
```

Для `flutter run` запустите настроенный эмулятор Pixel 10 через Device Manager в Android Studio или подключите Android-телефон с отладкой по USB. После запуска проверьте устройство командой `flutter devices`; при нескольких устройствах используйте `flutter run -d <device-id>`. На этой машине Pixel 10 уже обнаружен, а приложение успешно запускалось на нём. APK можно отдельно собрать командой `flutter build apk --debug`.

Проверка: `flutter analyze`, `flutter test`, `flutter build apk --debug`.

Android package ID: `com.alen.financetracker`.

Данные хранятся локально в Hive CE. При первом запуске создаются пять категорий и две явно помеченные демонстрационные операции. Их можно удалить с главного экрана. Firebase Android-приложение зарегистрировано с package ID `com.alen.financetracker`, конфигурация находится в `android/app/google-services.json`. Аналитика и отчёты о сбоях доступны только после добровольного включения в настройках; по умолчанию сбор выключен. Учёт финансов работает оффлайн.

Чтобы проверить Analytics, запустите приложение, включите «Аналитика и отчёты о сбоях» в настройках и откройте экраны или добавьте тестовую операцию. Для проверки событий в реальном времени используйте [DebugView](https://firebase.google.com/docs/analytics/debugview).

Политика конфиденциальности опубликована [на Google Sites](https://sites.google.com/view/finance-tracker-alen-privacy/) и доступна из Настроек через WebView. Её текст также хранится в [docs/privacy-policy.md](docs/privacy-policy.md). Финансовые функции работают оффлайн; для загрузки страницы политики нужен интернет.

Для DebugView на Android-эмуляторе включите режим отладки событий командой `adb shell setprop debug.firebase.analytics.app com.alen.financetracker`, затем перезапустите приложение. После проверки выключите его командой `adb shell setprop debug.firebase.analytics.app .none.`. Отчёты Crashlytics появятся в консоли после первого тестового сбоя при включённой диагностике.

Android Auto Backup отключён для локальных финансовых данных. Это не заменяет пользовательский экспорт данных, который пока не реализован.

## Release для Google Play

Release signing настроен через upload key:

- приватный ключ: `android/app/upload-keystore.jks`;
- локальные свойства Gradle: `android/key.properties`;
- безопасный пример без секретов: `android/key.properties.example`.

`.jks` и `key.properties` игнорируются Git. Для сборки:

```powershell
flutter build appbundle --release
```

Готовый подписанный файл: `build/app/outputs/bundle/release/app-release.aab`.
Храните резервную копию upload keystore отдельно от репозитория, а пароль — в
менеджере паролей. Перед каждой следующей загрузкой в Google Play увеличивайте
`version` и номер после `+` в `pubspec.yaml`.

## Материалы Google Play

Готовые файлы находятся в `store_assets/`:

- `app_icon_512.png` — иконка 512×512, 32-битный PNG;
- `feature_graphic_1024x500.png` — главное изображение 1024×500, RGB без прозрачности;
- `screenshots/01_...05_..._1080x1920.png` — пять портретных скриншотов 9:16;
- `screenshots/contact_sheet.jpg` — общий лист для быстрой проверки серии.

Launcher-иконки Android сгенерированы пакетом `flutter_launcher_icons` из
`assets/app_icon.png`, адаптивного foreground и monochrome-варианта. Повторная
генерация:

```powershell
python tool/prepare_store_assets.py
flutter pub run flutter_launcher_icons
flutter test tool/store_screenshots_test.dart --no-pub
python tool/compose_store_screenshots.py
```

Сценарий скриншотов использует отдельную временную Hive-базу с вымышленными
операциями. Данные установленного приложения он не читает. Подробное описание
исходников и форматов находится в `store_assets/README.md`.

- [Продукт и архитектура](docs/product-and-architecture.md)
- [Чек-лист готовности к публикации](docs/release-readiness.md)
- [Политика конфиденциальности](docs/privacy-policy.md)
- [Материалы Google Play](store_assets/README.md)
- [Правила работы с Codex](AGENTS.md)

# Готовность Finance Tracker к публикации

Проверено 19 сентября 2026 года.

## Технический чек-лист

| № | Пункт | Статус | Проверка |
| --- | --- | --- | --- |
| 1 | Package ID и версия | Готово | `applicationId = com.alen.financetracker`; `pubspec.yaml`: `1.0.0+1`, где `1.0.0` становится `versionName`, а `1` — `versionCode`. Итоговая уникальность ID подтверждается при создании приложения в Play Console. |
| 2 | Офлайн-сохранение Hive | Готово | Автоматический тест записывает операцию и бюджет, закрывает Hive, повторно открывает тот же каталог и сверяет данные. |
| 3 | Firebase Analytics | Готово | `google-services.json` находится в `android/app/`; пользователь подтвердил события `add_transaction`, `set_budget` и `screen_view` в DebugView. Финансовые параметры не отправляются. |
| 3 | Firebase Crashlytics | Требуется внешняя проверка | Обработчики Flutter и платформенных ошибок подключены, сбор зависит от добровольного согласия. Появление отдельного тестового сбоя в Crashlytics Console пока не подтверждено. |
| 4 | Политика конфиденциальности | Готово | Анонимный HTTP-запрос вернул 200; страница открывается без входа. Тот же URL встроен в WebView с прогрессом, обработкой ошибки и повторной попыткой. |
| 5 | Upload keystore | Частично готово | `.jks` и `key.properties` существуют, четыре свойства заполнены, оба файла игнорируются Git, release AAB подписан. Резервную копию вне репозитория должен подтвердить владелец. |
| 6 | Release AAB | Готово | `build/app/outputs/bundle/release/app-release.aab`, 57 290 756 байт; `jarsigner`: `jar verified`. |
| 7 | Графика магазина | Готово | Иконка 512×512 RGBA; Feature Graphic 1024×500 RGB; пять скриншотов 1080×1920 RGB. |
| 8 | Target API | Готово | Release-манифест содержит `targetSdkVersion=36`, что соответствует требованию Google Play с 31 августа 2026 года. |

## Что ещё требуется в Play Console

- Создать приложение с package ID `com.alen.financetracker` и включить Play App Signing.
- Заполнить название, краткое и полное описание, категорию и контактные данные.
- Добавить URL политики: `https://sites.google.com/view/finance-tracker-alen-privacy/`.
- Заполнить раздел App content: наличие рекламы, доступ к приложению, целевая аудитория, возрастной рейтинг и Data safety.
- Указать, что приложение работает без регистрации и не содержит закрытых разделов.
- Согласовать Data safety с добровольными Firebase Analytics и Crashlytics и с текстом политики.
- Если личный аккаунт разработчика создан после 13 ноября 2023 года, провести закрытый тест: минимум 12 участников должны оставаться подключёнными непрерывно 14 дней, затем запросить доступ к production.
- Перед каждой следующей загрузкой увеличить число после `+` в `version`.

## Файлы для загрузки

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- Иконка: `store_assets/app_icon_512.png`
- Feature Graphic: `store_assets/feature_graphic_1024x500.png`
- Скриншоты: `store_assets/screenshots/*_1080x1920.png`

Размер 1080×2400 из первоначального руководства не используется: его отношение
сторон 9:20 нарушает правило Google Play, согласно которому длинная сторона
скриншота не должна быть больше удвоенной короткой. 1080×1920 — рекомендуемый
портретный формат 9:16.

## Контрольная сумма AAB

SHA-256:
`4BE0378D3484E8DC51A9C09CA564D34B45ED96D18E0A58FCFBB870AF18287FD2`

## Официальные источники

- [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)
- [Preview asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en-GB)
- [Testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB)

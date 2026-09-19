import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/settings_cubit.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cubit = context.watch<SettingsCubit>();
    final settings = cubit.state;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(s.t('language')),
                  trailing: DropdownButton<String>(
                    value: settings.localeCode,
                    items: const [
                      DropdownMenuItem(value: 'ru', child: Text('Русский')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SettingsCubit>().setLocale(value);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: Text(s.t('currency')),
                  trailing: DropdownButton<String>(
                    value: settings.currencyCode,
                    items: const ['RUB', 'AMD', 'USD', 'EUR']
                        .map(
                          (code) =>
                              DropdownMenuItem(value: code, child: Text(code)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SettingsCubit>().setCurrency(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
            child: Text(
              s.t('currencyHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.insights_outlined),
              title: Text(s.t('telemetry')),
              subtitle: Text(
                s.t(
                  cubit.telemetryAvailable
                      ? 'telemetryHint'
                      : 'telemetryUnavailable',
                ),
              ),
              value: settings.telemetryConsent && cubit.telemetryAvailable,
              onChanged: cubit.telemetryAvailable
                  ? (value) async {
                      try {
                        await cubit.setTelemetryConsent(value);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.t('telemetryError'))),
                          );
                        }
                      }
                    }
                  : null,
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(s.t('categories')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/categories'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(s.t('privacy')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/privacy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

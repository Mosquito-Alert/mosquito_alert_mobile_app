import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/core/localizations/my_localizations.dart';

void main() {
  group('beta locale gating', () {
    test('production hides Vietnamese', () {
      final locales = MyLocalizations.localesFor(isProduction: true);
      expect(locales, isNot(contains(Locale('vi', 'VN'))));
    });

    test('production still offers Arabic and the long-standing languages', () {
      final locales = MyLocalizations.localesFor(isProduction: true);
      expect(locales, contains(Locale('ar', 'MA')));
      expect(locales, contains(Locale('en', 'US')));
      expect(locales, contains(Locale('es', 'ES')));
      expect(locales, contains(Locale('es', 'UY')));
      expect(locales.length, 25);
    });

    test('non-production builds offer everything, Vietnamese included', () {
      final locales = MyLocalizations.localesFor(isProduction: false);
      expect(locales, contains(Locale('vi', 'VN')));
      expect(locales, contains(Locale('ar', 'MA')));
      expect(locales.length, 26);
    });

    test('gating never drops a language production already shipped', () {
      // Guards against a typo in _betaLocales silently removing a live
      // language: everything gated out must be a deliberate beta entry.
      final all = MyLocalizations.localesFor(isProduction: false).toSet();
      final prod = MyLocalizations.localesFor(isProduction: true).toSet();
      expect(all.difference(prod), {Locale('vi', 'VN')});
    });
  });
}

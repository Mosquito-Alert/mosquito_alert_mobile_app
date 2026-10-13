import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/features/bites/presentation/widgets/bite_stickman.dart';
import 'package:mosquito_alert_app/features/notifications/notification_repository.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/location_selector.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/photo_selector.dart';
import 'package:provider/provider.dart';

// Import shared mocks
import '../mocks/mocks.dart';

// Arabic (ar_MA) is the app's first RTL language (#781). Every widget below
// used physical left/right placement before the RTL pass. Each test runs in
// both directions: RTL must lay out cleanly and mirror, LTR must keep the
// geometry existing users already see.

const _english = Locale('en');
const _arabic = Locale('ar', 'MA');

/// Same delegates as the app's MaterialApp: the Global* delegates are what
/// turn an Arabic locale into an RTL [Directionality].
Widget createTestApp({required TextDirection direction, required Widget home}) {
  return MaterialApp(
    locale: direction == TextDirection.rtl ? _arabic : _english,
    supportedLocales: const [_english, _arabic],
    localizationsDelegates: const [
      MockMyLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

/// Lays out on a 360x640 phone screen, so overflows surface as on a device.
Rect usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  return Offset.zero & const Size(360, 640);
}

/// Distance between the end (trailing) edges of [outer] and [inner].
double endGap(Rect outer, Rect inner, TextDirection direction) =>
    direction == TextDirection.ltr
    ? outer.right - inner.right
    : inner.left - outer.left;

/// Distance between the start (leading) edges of [outer] and [inner].
double startGap(Rect outer, Rect inner, TextDirection direction) =>
    direction == TextDirection.ltr
    ? inner.left - outer.left
    : outer.right - inner.right;

/// Nothing may have thrown during layout -- RenderFlex overflows included --
/// and [widget] must really have been laid out in [direction].
void expectCleanLayout(
  WidgetTester tester,
  Finder widget,
  TextDirection direction,
) {
  expect(tester.takeException(), isNull);
  expect(Directionality.of(tester.element(widget)), direction);
}

// A valid 1x1 transparent PNG, so photo thumbnails decode without errors.
final Uint8List transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  for (final direction in TextDirection.values) {
    group('Directional layout (${direction.name})', () {
      testWidgets('NotificationDetailPage header starts at the start edge', (
        WidgetTester tester,
      ) async {
        // Given
        final screen = usePhoneViewport(tester);
        final mockClient = MockMosquitoAlert();
        final notification = createTestNotification(
          id: 1,
          title: 'Notification title',
          body: '<p>Notification body</p>',
        );
        mockClient.notificationsApi.setNotifications([notification]);

        // When
        await tester.pumpWidget(
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider(
              repository: NotificationRepository(apiClient: mockClient),
            ),
            child: createTestApp(
              direction: direction,
              home: NotificationDetailPage(notification: notification),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then
        expectCleanLayout(
          tester,
          find.byType(NotificationDetailPage),
          direction,
        );
        final title = tester.getRect(find.text('Notification title'));
        expect(startGap(screen, title, direction), 16.0);
      });

      testWidgets('LocationSelector location button sits at the end edge', (
        WidgetTester tester,
      ) async {
        // Given
        final screen = usePhoneViewport(tester);

        // When
        await tester.pumpWidget(
          createTestApp(
            direction: direction,
            home: Scaffold(
              body: LocationSelector(onLocationChanged: (_, _, _) {}),
            ),
          ),
        );
        await tester.pump();

        // Then
        expectCleanLayout(tester, find.byType(LocationSelector), direction);
        final button = tester.getRect(
          find.byKey(const Key('myLocationButton')),
        );
        expect(endGap(screen, button, direction), 16.0);
      });

      testWidgets('PhotoSelector remove button sits in the top-end corner', (
        WidgetTester tester,
      ) async {
        // Given
        usePhoneViewport(tester);

        // When
        await tester.pumpWidget(
          createTestApp(
            direction: direction,
            home: Scaffold(
              body: PhotoSelector(
                selectedPhotos: [transparentPng],
                onPhotosChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        // Then
        expectCleanLayout(tester, find.byType(PhotoSelector), direction);
        final removeButton = find.byIcon(Icons.close);
        final thumbnail = tester.getRect(
          find.ancestor(of: removeButton, matching: find.byType(Stack)).first,
        );
        final remove = tester.getRect(removeButton);
        expect(endGap(thumbnail, remove, direction), 4.0);
        expect(remove.top - thumbnail.top, 4.0);
      });

      testWidgets(
        'BiteStickMan keeps body regions physical, count badges at the end',
        (WidgetTester tester) async {
          // Given
          usePhoneViewport(tester);

          // When
          await tester.pumpWidget(
            createTestApp(
              direction: direction,
              home: Scaffold(
                body: BiteStickMan(
                  leftHandBites: 3,
                  rightHandBites: 5,
                  onChanged: (_, _) {},
                ),
              ),
            ),
          );
          await tester.pump();

          // Then
          expectCleanLayout(tester, find.byType(BiteStickMan), direction);
          Rect region(String count) => tester.getRect(
            find
                .ancestor(
                  of: find.text(count),
                  matching: find.byType(GestureDetector),
                )
                .first,
          );
          Rect badge(String count) => tester.getRect(
            find
                .ancestor(
                  of: find.text(count),
                  matching: find.byType(Container),
                )
                .first,
          );
          // The regions are tap targets over a body image that is not
          // mirrored, so the left-hand region stays on the physical left.
          expect(region('3').center.dx, lessThan(region('5').center.dx));
          // The count badge is UI chrome and follows the reading direction.
          expect(endGap(region('3'), badge('3'), direction), 4.0);
        },
      );
    });
  }
}

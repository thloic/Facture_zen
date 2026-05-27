// test/widget/subscription_screen_test.dart
//
// Teste les états visuels de SubscriptionScreen (chargement, erreur, succès)
// en injectant un SubscriptionViewModel contrôlable via ses constructeurs de test.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:facture_zen/features/invoicing/views/subscription_screen.dart';
import 'package:facture_zen/features/invoicing/viewmodels/subscription_view_model.dart';
import 'package:facture_zen/common/providers/premium_provider.dart';

import '../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  // Construit le widget sous test avec tous les Providers requis.
  Widget _buildScreen({
    required SubscriptionViewModel viewModel,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionViewModel>.value(value: viewModel),
        ChangeNotifierProvider<PremiumProvider>.value(
          value: PremiumProvider.fake(),
        ),
      ],
      child: const MaterialApp(
        home: SubscriptionScreen(remainingInvoices: 0),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // État de chargement
  // -------------------------------------------------------------------------

  group('État de chargement', () {
    testWidgets('montre un CircularProgressIndicator pendant le chargement',
        (tester) async {
      final completer = Completer<void>();
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.loadOfferings())
          .thenAnswer((_) => completer.future);
      when(() => mockRevenueCat.allAvailablePackages).thenReturn([]);
      when(() => mockRevenueCat.offerings).thenReturn(null);

      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );

      await tester.pumpWidget(_buildScreen(viewModel: vm));
      // Execute postFrameCallback → loadOfferings() démarre mais ne finit pas.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Libère le Completer pour ne pas laisser de futures pendants.
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('le texte "Chargement des offres" est visible',
        (tester) async {
      final completer = Completer<void>();
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.loadOfferings())
          .thenAnswer((_) => completer.future);
      when(() => mockRevenueCat.allAvailablePackages).thenReturn([]);
      when(() => mockRevenueCat.offerings).thenReturn(null);

      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );

      await tester.pumpWidget(_buildScreen(viewModel: vm));
      await tester.pump();

      expect(find.textContaining('Chargement'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });

  // -------------------------------------------------------------------------
  // État d'erreur
  // -------------------------------------------------------------------------

  group('État d\'erreur', () {
    testWidgets('montre le message d\'erreur quand loadOfferings échoue',
        (tester) async {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.loadOfferings())
          .thenThrow(Exception('Serveur indisponible'));
      when(() => mockRevenueCat.allAvailablePackages).thenReturn([]);

      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );

      await tester.pumpWidget(_buildScreen(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsWidgets);
    });

    testWidgets('affiche le bouton "Réessayer" en cas d\'erreur',
        (tester) async {
      final mockRevenueCat = MockRevenueCatService();
      when(() => mockRevenueCat.loadOfferings())
          .thenThrow(Exception('Erreur réseau'));
      when(() => mockRevenueCat.allAvailablePackages).thenReturn([]);

      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );

      await tester.pumpWidget(_buildScreen(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('bouton Réessayer rappelle loadOfferings()', (tester) async {
      final mockRevenueCat = MockRevenueCatService();
      // Première appel : erreur. Deuxième appel (après tap) : succès vide.
      var callCount = 0;
      when(() => mockRevenueCat.loadOfferings()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('Erreur réseau');
      });
      when(() => mockRevenueCat.allAvailablePackages).thenReturn([]);

      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );

      await tester.pumpWidget(_buildScreen(viewModel: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      // loadOfferings() a été appelé au moins 2 fois (initState + tap).
      expect(callCount, greaterThanOrEqualTo(2));
    });
  });

  // -------------------------------------------------------------------------
  // État de succès
  // -------------------------------------------------------------------------

  group('État succès — packages chargés', () {
    testWidgets('pas de spinner ni de message d\'erreur', (tester) async {
      final pkg = createMockPackage(
        productId: 'voxin_pro_monthly',
        title: 'Voxin Pro',
        priceString: '9,99 €',
      );
      final mockRevenueCat = createMockRevenueCat(packages: [pkg]);

      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );

      await tester.pumpWidget(_buildScreen(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('le titre de l\'écran "Choisissez votre offre" est visible',
        (tester) async {
      final pkg = createMockPackage();
      final mockRevenueCat = createMockRevenueCat(packages: [pkg]);

      final vm = SubscriptionViewModel.forTesting(
        revenueCatService: mockRevenueCat,
        syncService: createNoOpSyncService(),
      );

      await tester.pumpWidget(_buildScreen(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.text('Choisissez votre offre'), findsOneWidget);
    });
  });
}

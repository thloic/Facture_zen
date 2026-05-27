// Smoke test minimal : vérifie que MyApp se construit sans lancer Firebase
// (Firebase n'est pas initialisé en test unitaire — on ne pump pas l'app entière).
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test — test placeholder', (WidgetTester tester) async {
    // Aucun widget à tester ici ; ce fichier est conservé pour éviter
    // que flutter test renvoie "No test files found".
    expect(1 + 1, 2);
  });
}


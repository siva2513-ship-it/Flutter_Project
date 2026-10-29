import 'package:flutter_test/flutter_test.dart';
import 'package:paddy_disease_detection/main.dart';

void main() {
  testWidgets('Renders Home Screen elements correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const PaddyDiseaseApp());

    // Verify Title and Subtitle
    expect(find.text('Paddy Disease Detection'), findsOneWidget);
    expect(find.text('Detect paddy leaf diseases using AI'), findsOneWidget);

    // Verify initial placeholder
    expect(find.text('Select a paddy leaf image'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Detect Disease'), findsOneWidget);
  });

  testWidgets('Shows error message if Detect Disease is tapped without selecting an image',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PaddyDiseaseApp());

    // Tap Detect Disease button
    await tester.tap(find.text('Detect Disease'));
    await tester.pump();

    // Verify error message is shown
    expect(find.text('No image selected. Please choose a photo first.'), findsOneWidget);
  });
}

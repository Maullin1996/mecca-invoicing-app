import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecca/core/widgets/custom_textform_field.dart';
import 'package:mecca/core/widgets/empty_screen_widget.dart';
import 'package:mecca/core/widgets/error_message_widget.dart';

class TestAssetBundle extends CachingAssetBundle {
  static final ByteData _imageData = ByteData.view(
    Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2P8/5+hHgAHggJ/PpUxrwAAAABJRU5ErkJggg==',
      ),
    ).buffer,
  );

  @override
  Future<ByteData> load(String key) async => _imageData;
}

void main() {
  testWidgets('ErrorMessageWidget shows text and button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ErrorMessageWidget(text: 'Oops')),
    );

    expect(find.text('Oops'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('CustomTextformField accepts input', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CustomTextformField(label: 'Nombre', controller: controller),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Juan');
    expect(controller.text, 'Juan');
  });

  testWidgets('EmptyScreenWidget shows title and image', (tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: const MaterialApp(
          home: EmptyScreenWidget(
            title: 'Nada por aqui',
            gift: 'assets/images/factory.png',
          ),
        ),
      ),
    );

    expect(find.text('Nada por aqui'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}

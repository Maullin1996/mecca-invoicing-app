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
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final encoded = const StandardMessageCodec().encodeMessage(
        <String, List<Map<String, Object?>>>{
          'assets/images/factory.png': <Map<String, Object?>>[
            <String, Object?>{'asset': 'assets/images/factory.png'},
          ],
        },
      );
      return encoded ?? ByteData(0);
    }

    if (key == 'AssetManifest.json') {
      final manifestJson = jsonEncode(<String, List<Map<String, Object?>>>{
        'assets/images/factory.png': <Map<String, Object?>>[
          <String, Object?>{'asset': 'assets/images/factory.png'},
        ],
      });
      final bytes = utf8.encode(manifestJson);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }

    return _imageData;
  }
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

  testWidgets('EmptyScreenWidget renders with empty title', (tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: const MaterialApp(
          home: EmptyScreenWidget(title: '', gift: 'assets/images/factory.png'),
        ),
      ),
    );

    expect(find.byType(EmptyScreenWidget), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EmptyScreenWidget uses the provided asset image', (
    tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: const MaterialApp(
          home: EmptyScreenWidget(
            title: 'Vacio',
            gift: 'assets/images/factory.png',
          ),
        ),
      ),
    );

    final imageWidget = tester.widget<Image>(find.byType(Image));
    final imageProvider = imageWidget.image;
    expect(imageProvider, isA<ResizeImage>());
    final resizeImage = imageProvider as ResizeImage;
    final assetImage = resizeImage.imageProvider as AssetImage;
    expect(assetImage.assetName, 'assets/images/factory.png');
  });

  testWidgets('CustomTextformField shows validator error', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Form(
            key: formKey,
            child: CustomTextformField(
              label: 'Nombre',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );

    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Requerido'), findsOneWidget);
  });
}

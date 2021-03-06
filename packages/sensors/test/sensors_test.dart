// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:sensors/sensors.dart';
import 'package:test/test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('$accelerometerEvents are streamed', () async {
    const String channelName = 'plugins.flutter.io/sensors/accelerometer';
    const List<double> sensorData = <double>[1.0, 2.0, 3.0];

    const StandardMethodCodec standardMethod = StandardMethodCodec();

    void emitEvent(ByteData event) {
      // TODO(hterkelsen): Remove this when defaultBinaryMessages is in stable.
      // https://github.com/flutter/flutter/issues/33446
      // ignore: deprecated_member_use
      BinaryMessages.handlePlatformMessage(
        channelName,
        event,
        (ByteData reply) {},
      );
    }

    bool isCanceled = false;
    // TODO(hterkelsen): Remove this when defaultBinaryMessages is in stable.
    // https://github.com/flutter/flutter/issues/33446
    // ignore: deprecated_member_use
    BinaryMessages.setMockMessageHandler(channelName, (ByteData message) async {
      final MethodCall methodCall = standardMethod.decodeMethodCall(message);
      if (methodCall.method == 'listen') {
        emitEvent(standardMethod.encodeSuccessEnvelope(sensorData));
        emitEvent(null);
        return standardMethod.encodeSuccessEnvelope(null);
      } else if (methodCall.method == 'cancel') {
        isCanceled = true;
        return standardMethod.encodeSuccessEnvelope(null);
      } else {
        fail('Expected listen or cancel');
      }
    });

    final AccelerometerEvent event = await accelerometerEvents.first;
    expect(event.x, 1.0);
    expect(event.y, 2.0);
    expect(event.z, 3.0);

    await Future<void>.delayed(Duration.zero);
    expect(isCanceled, isTrue);
  });
}

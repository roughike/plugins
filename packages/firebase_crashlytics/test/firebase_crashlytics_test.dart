import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$Crashlytics', () {
    final List<MethodCall> log = <MethodCall>[];

    final Crashlytics crashlytics = Crashlytics.instance;

    setUp(() async {
      Crashlytics.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'Crashlytics#isDebuggable':
            return true;
          case 'Crashlytics#setUserEmail':
            return true;
          case 'Crashlytics#setUserIdentifier':
            return true;
          case 'Crashlytics#setUserName':
            return true;
          case 'Crashlytics#getVersion':
            return '0.0.0+1';
          default:
            return false;
        }
      });
      log.clear();
    });

    test('onError', () async {
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: 'foo exception',
        stack: StackTrace.current,
        library: 'foo library',
        context: ErrorDescription('foo context'),
      );
      crashlytics.enableInDevMode = true;
      crashlytics.log('foo');
      await crashlytics.onError(details);
      expect(log[0].method, 'Crashlytics#onError');
      expect(log[0].arguments['exception'], 'foo exception');
      expect(log[0].arguments['context'], 'foo context');
      expect(log[0].arguments['logs'], isNotEmpty);
      expect(log[0].arguments['logs'], contains('foo'));
      expect(log[0].arguments['keys'], isEmpty);
    });

    test('isDebuggable', () async {
      expect(await crashlytics.isDebuggable(), true);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'Crashlytics#isDebuggable',
            arguments: null,
          )
        ],
      );
    });

    test('crash', () {
      expect(() => crashlytics.crash(), throwsStateError);
    });

    test('getVersion', () async {
      await crashlytics.getVersion();
      expect(log,
          <Matcher>[isMethodCall('Crashlytics#getVersion', arguments: null)]);
    });

    test('setUserEmail', () async {
      await crashlytics.setUserEmail('foo');
      expect(log, <Matcher>[
        isMethodCall('Crashlytics#setUserEmail',
            arguments: <String, dynamic>{'email': 'foo'})
      ]);
    });

    test('setUserIdentifier', () async {
      await crashlytics.setUserIdentifier('foo');
      expect(log, <Matcher>[
        isMethodCall('Crashlytics#setUserIdentifier',
            arguments: <String, dynamic>{'identifier': 'foo'})
      ]);
    });

    test('setUserName', () async {
      await crashlytics.setUserName('foo');
      expect(log, <Matcher>[
        isMethodCall('Crashlytics#setUserName',
            arguments: <String, dynamic>{'name': 'foo'})
      ]);
    });

    test('getStackTraceElements with character index', () async {
      final List<String> lines = <String>[
        'package:flutter/src/widgets/framework.dart 3825:27  StatefulElement.build'
      ];
      final List<Map<String, String>> elements =
          crashlytics.getStackTraceElements(lines);
      expect(elements.length, 1);
      expect(elements.first, <String, String>{
        'class': 'StatefulElement',
        'method': 'build',
        'file': 'package:flutter/src/widgets/framework.dart',
        'line': '3825',
      });
    });

    test('getStackTraceElements without character index', () async {
      final List<String> lines = <String>[
        'package:flutter/src/widgets/framework.dart 3825  StatefulElement.build'
      ];
      final List<Map<String, String>> elements =
          crashlytics.getStackTraceElements(lines);
      expect(elements.length, 1);
      expect(elements.first, <String, String>{
        'class': 'StatefulElement',
        'method': 'build',
        'file': 'package:flutter/src/widgets/framework.dart',
        'line': '3825',
      });
    });
  });
}

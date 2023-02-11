import 'dart:async';
import 'dart:typed_data';

import 'package:fluttium_protocol/fluttium_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Emitter', () {
    test('emit announce', () async {
      await runWithPrint((printed) async {
        final emitter = Emitter();
        await emitter.announce('step');

        await printingDone;

        expect(
          printed,
          equals([
            '{"type":"start"}',
            r'{"type":"data","data":"\"{\\\"type\\\":\\\"announce\\\",\\\"data\\\":\\\"\\\\\\\"step\\\\\\\"\\\"}\""}',
            '{"type":"done"}'
          ]),
        );
      });
    });

    test('emit start', () async {
      await runWithPrint((printed) async {
        final emitter = Emitter();
        await emitter.start('step');

        await printingDone;

        expect(
          printed,
          equals([
            '{"type":"start"}',
            r'{"type":"data","data":"\"{\\\"type\\\":\\\"start\\\",\\\"data\\\":\\\"\\\\\\\"step\\\\\\\"\\\"}\""}',
            '{"type":"done"}'
          ]),
        );
      });
    });

    test('emit done', () async {
      await runWithPrint((printed) async {
        final emitter = Emitter();
        await emitter.done('step');

        await printingDone;

        expect(
          printed,
          equals([
            '{"type":"start"}',
            r'{"type":"data","data":"\"{\\\"type\\\":\\\"done\\\",\\\"data\\\":\\\"\\\\\\\"step\\\\\\\"\\\"}\""}',
            '{"type":"done"}'
          ]),
        );
      });
    });

    group('emit store', () {
      test('with empty bytes', () async {
        await runWithPrint((printed) async {
          final emitter = Emitter();
          await emitter.store('fileName', Uint8List(0));

          await printingDone;

          expect(
            printed,
            equals([
              '{"type":"start"}',
              r'{"type":"data","data":"\"{\\\"type\\\":\\\"store\\\",\\\"data\\\":\\\"[\\\\\\\"fileName\\\\\\\",[]]\\\"}\""}',
              '{"type":"done"}'
            ]),
          );
        });
      });

      test('with bytes', () async {
        await runWithPrint((printed) async {
          final emitter = Emitter();
          await emitter.store(
            'fileName',
            Uint8List.fromList(List.generate(1000, (i) => i)),
          );

          await printingDone;

          expect(
            printed,
            equals([
              '{"type":"start"}',
              r'{"type":"data","data":"\"{\\\"type\\\":\\\"store\\\",\\\"data\\\":\\\"[\\\\\\\"fileName\\\\\\\",[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217\""}',
              r'{"type":"data","data":"\",218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,1\""}',
              r'{"type":"data","data":"\"89,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160\""}',
              r'{"type":"data","data":"\",161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,1\""}',
              r'{"type":"data","data":"\"32,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231]]\\\"}\""}',
              '{"type":"done"}'
            ]),
          );
        });
      });
    });

    test('emit fail', () async {
      await runWithPrint((printed) async {
        final emitter = Emitter();
        await emitter.fail('step', reason: 'reason');

        await printingDone;

        expect(
          printed,
          equals([
            '{"type":"start"}',
            r'{"type":"data","data":"\"{\\\"type\\\":\\\"fail\\\",\\\"data\\\":\\\"[\\\\\\\"step\\\\\\\",\\\\\\\"reason\\\\\\\"]\\\"}\""}',
            '{"type":"done"}'
          ]),
        );
      });
    });
  });
}

Future<void> runWithPrint(
  Future<void> Function(List<String> printed) callback,
) async {
  final printed = <String>[];

  await runZoned(
    () => callback(printed),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) => printed.add(message),
    ),
  );
}

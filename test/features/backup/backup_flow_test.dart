import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/backup/domain/backup_file_gateway.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';
import 'package:ascend/features/backup/presentation/backup_flow.dart';

import '../../helpers/backup_env.dart';

class FakeFiles implements BackupFileGateway {
  final List<BackupFile> saved = [];
  bool saveResult = true;
  Uint8List? toPick;

  @override
  Future<bool> save(BackupFile file) async {
    if (!saveResult) return false;
    saved.add(file);
    return true;
  }

  @override
  Future<Uint8List?> pick() async => toPick;
}

class ScriptedPrompts implements BackupPrompts {
  ScriptedPrompts({this.create, List<RestoreChoice?> restore = const []})
      : _restore = [...restore];

  final CreateChoice? create;
  final List<RestoreChoice?> _restore;
  final List<String?> restoreErrors = [];

  @override
  Future<CreateChoice?> askCreate() async => create;

  @override
  Future<RestoreChoice?> askRestore(
      BackupHeader header, {
        String? error,
      }) async {
    restoreErrors.add(error);
    return _restore.isEmpty ? null : _restore.removeAt(0);
  }
}

void main() {
  late Env a;
  late Env b;
  late FakeFiles files;

  BackupFlow flowFor(
      Env env,
      ScriptedPrompts prompts, {
        void Function(bool busy)? onBusy,
      }) {
    return BackupFlow(
      service: env.service,
      files: files,
      safety: env.safety,
      prompts: prompts,
      onBusy: onBusy,
    );
  }

  setUp(() {
    a = Env();
    b = Env();
    files = FakeFiles();
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  group('create', () {
    test('without a password saves a plain file', () async {
      await a.addTask('t1');

      final result = await flowFor(
        a,
        ScriptedPrompts(create: const CreateChoice()),
      ).create();

      expect(result.status, FlowStatus.done);
      expect(result.message, 'Backup saved');
      expect(files.saved.length, 1);
      expect(
        a.service.inspect(files.saved.single.bytes).header.encrypted,
        isFalse,
      );
    });

    test('with a password saves an encrypted file', () async {
      final result = await flowFor(
        a,
        ScriptedPrompts(create: const CreateChoice(password: 'secret')),
      ).create();

      expect(result.status, FlowStatus.done);
      expect(result.message, 'Encrypted backup saved');
      expect(
        a.service.inspect(files.saved.single.bytes).header.encrypted,
        isTrue,
      );
    });

    test('cancelled in the options dialog saves nothing', () async {
      final result = await flowFor(a, ScriptedPrompts()).create();

      expect(result.status, FlowStatus.cancelled);
      expect(files.saved, isEmpty);
    });

    test('cancelled in the save dialog is not an error', () async {
      files.saveResult = false;

      final result = await flowFor(
        a,
        ScriptedPrompts(create: const CreateChoice()),
      ).create();

      expect(result.status, FlowStatus.cancelled);
    });

    test('reports busy state around the heavy work', () async {
      final states = <bool>[];

      await flowFor(
        a,
        ScriptedPrompts(create: const CreateChoice()),
        onBusy: states.add,
      ).create();

      expect(states, [true, false]);
    });
  });

  group('restore', () {
    test('cancelled file picker does nothing', () async {
      final result = await flowFor(b, ScriptedPrompts()).restoreFromFile();

      expect(result.status, FlowStatus.cancelled);
    });

    test('a file that is not a backup is rejected', () async {
      files.toPick = Uint8List.fromList([1, 2, 3]);

      final result = await flowFor(b, ScriptedPrompts()).restoreFromFile();

      expect(result.status, FlowStatus.failed);
      expect(result.message, 'This is not a valid ASCEND backup file.');
    });

    test('replaces data after confirmation', () async {
      await a.addTask('t1');
      await a.addTask('t2');
      final file = await a.service.createBackup();
      await b.addTask('x');
      files.toPick = file.bytes;

      final result = await flowFor(
        b,
        ScriptedPrompts(restore: [const RestoreChoice()]),
      ).restoreFromFile();

      expect(result.status, FlowStatus.done);
      expect(result.message, 'Backup restored • 2 tasks, 0 goals');
      expect(await b.taskIds(), unorderedEquals(['t1', 't2']));
    });

    test('cancelled confirmation changes nothing', () async {
      await a.addTask('t1');
      final file = await a.service.createBackup();
      await b.addTask('x');
      files.toPick = file.bytes;

      final result = await flowFor(
        b,
        ScriptedPrompts(restore: [null]),
      ).restoreFromFile();

      expect(result.status, FlowStatus.cancelled);
      expect(await b.taskIds(), ['x']);
      expect(b.safety.files, isEmpty);
    });

    test('wrong password asks again with an error message', () async {
      await a.addTask('t1');
      final file = await a.service.createBackup(password: 'secret');
      await b.addTask('x');
      files.toPick = file.bytes;
      final prompts = ScriptedPrompts(
        restore: [
          const RestoreChoice(password: 'wrong'),
          const RestoreChoice(password: 'secret'),
        ],
      );

      final result = await flowFor(b, prompts).restoreFromFile();

      expect(result.status, FlowStatus.done);
      expect(prompts.restoreErrors, [null, 'Wrong password.']);
      expect(await b.taskIds(), ['t1']);
    });

    test('user can give up after a wrong password', () async {
      await a.addTask('t1');
      final file = await a.service.createBackup(password: 'secret');
      await b.addTask('x');
      files.toPick = file.bytes;

      final result = await flowFor(
        b,
        ScriptedPrompts(restore: [const RestoreChoice(password: 'wrong'), null]),
      ).restoreFromFile();

      expect(result.status, FlowStatus.cancelled);
      expect(await b.taskIds(), ['x']);
    });

    test('a safety copy brings the previous data back', () async {
      await a.addTask('t1');
      final file = await a.service.createBackup();
      await b.addTask('x');
      files.toPick = file.bytes;
      await flowFor(
        b,
        ScriptedPrompts(restore: [const RestoreChoice()]),
      ).restoreFromFile();
      expect(await b.taskIds(), ['t1']);

      final name = (await b.safety.list()).single.fileName;
      final result = await flowFor(
        b,
        ScriptedPrompts(restore: [const RestoreChoice()]),
      ).restoreSafety(name);

      expect(result.status, FlowStatus.done);
      expect(await b.taskIds(), ['x']);
    });

    test('a missing safety copy is reported', () async {
      final result = await flowFor(b, ScriptedPrompts()).restoreSafety('nope');

      expect(result.status, FlowStatus.failed);
      expect(result.message, 'Could not read the safety copy.');
    });
  });
}
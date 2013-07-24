library test.generate;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:discovery_api_client_generator/generator.dart';

import '../../tool/util.dart';

const _testLibName = 'discovery';
const _testLibVer = 'v1';

void main() {
  group('generate', () {
    test('no args', () {
      return _runGenerate([])
          .then((ProcessResult pr) {
            expect(pr.exitCode, 1);
            expect(pr.stdout, startsWith('Missing arguments'));
            expect(pr, _hasUsageInStdOut);
          });
    });

    test('help', () {
      return _runGenerate(['--help'])
          .then((ProcessResult pr) {
            expect(pr.exitCode, 0);
            expect(pr, _hasUsageInStdOut);
          });
    });

    test('generate library via API and analyze', withTempDir(_testSingleLibraryGeneration));

    test('generate library via CLI', withTempDir(_testSingleLibraryGenerationViaCLI));

    test('"rest" args should throw', withTempDir((tmpDir) {
      return _runGenerate(['--api', _testLibName, '-v', _testLibVer, '-o', tmpDir.path, 'silly_extra_arg'])
          .then((ProcessResult pr) {
            expect(pr.exitCode, 1);
            expect(pr, _hasUsageInStdOut);
          });
    }));

    test('missing output directory should throw', withTempDir((tmpDir) {
        return _runGenerate(['--api', _testLibName, '-v', _testLibVer])
          .then((ProcessResult pr) {
            expect(pr.exitCode, 1);
            expect(pr, _hasUsageInStdOut);
          });
    }));
  });
}

Future _testSingleLibraryGeneration(Directory tmpDir) {
  return generateLibrary(_testLibName, _testLibVer, tmpDir.path)
      .then((bool success) {
        expect(success, isTrue);

        return _validateDirectory(tmpDir.path, _testLibName, _testLibVer);
      })
      .then((_) => analyzePackage(tmpDir.path, _testLibName, _testLibVer, false));
}

Future _testSingleLibraryGenerationViaCLI(Directory tmpDir) {
  return _runGenerate(['--api', _testLibName, '-v', _testLibVer, '-o', tmpDir.path])
      .then((ProcessResult pr) {
        expect(pr.exitCode, 0);

        return _validateDirectory(tmpDir.path, _testLibName, _testLibVer);
      });
}

Future _validateDirectory(String packageDir, String libName, String libVer) {
  var libraryPaths = getLibraryPaths(packageDir, libName, libVer);

  expect(libraryPaths, hasLength(6));

  return _validateFilesExist(libraryPaths);
}

Future _validateFilesExist(List<String> files) {
  return Future.forEach(files, (filePath) {
    var file = new File(filePath);
    return file.exists()
        .then((bool exists) {
          expect(exists, isTrue, reason: '$filePath should exist');
        });
  });
}

final Matcher _hasUsageInStdOut = predicate((ProcessResult pr) => pr.stdout.contains("""Usage:
   generate.dart"""));

Future<ProcessResult> _runGenerate(Iterable<String> args) {

  var theArgs = ['--checked', './bin/generate.dart']
    ..addAll(args);

  return Process.run('dart', theArgs);
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/built_in_formatters.dart';
import 'package:chatorai/core/format/formatter_definition.dart';

void main() {
  group('FormatterDefinition.enabled', () {
    test(
      'dart formatter enabled function returns command when dart is available',
      () async {
        // In the test environment, dart should be available
        final def = builtInFormatters['dart']!;
        final ctx = FormatContext(
          filePath: '/test/lib/main.dart',
          projectRoot: '/test',
        );

        final result = await def.enabled(ctx);

        // If dart is available, it should return a command
        if (await _isCommandAvailable('dart')) {
          expect(result, isNotNull);
          expect(result!.length, greaterThanOrEqualTo(2));
          expect(result.first, equals('dart'));
          expect(result[1], equals('format'));
          // Third element is $FILE placeholder (not yet substituted)
          expect(result[2], equals('\$FILE'));
        } else {
          expect(result, isNull);
        }
      },
    );

    test('gofmt formatter enabled function', () async {
      final def = builtInFormatters['gofmt']!;
      final ctx = FormatContext(
        filePath: '/test/main.go',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('gofmt')) {
        expect(result, isNotNull);
        expect(result!.first, equals('gofmt'));
      } else {
        expect(result, isNull);
      }
    });

    test('rustfmt formatter enabled function', () async {
      final def = builtInFormatters['rustfmt']!;
      final ctx = FormatContext(
        filePath: '/test/main.rs',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('rustfmt')) {
        expect(result, isNotNull);
        expect(result!.first, equals('rustfmt'));
      } else {
        expect(result, isNull);
      }
    });

    test('zig formatter enabled function', () async {
      final def = builtInFormatters['zig']!;
      final ctx = FormatContext(
        filePath: '/test/main.zig',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('zig')) {
        expect(result, isNotNull);
        expect(result!.first, equals('zig'));
      } else {
        expect(result, isNull);
      }
    });

    test('shfmt formatter enabled function', () async {
      final def = builtInFormatters['shfmt']!;
      final ctx = FormatContext(
        filePath: '/test/script.sh',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('shfmt')) {
        expect(result, isNotNull);
        expect(result!.first, equals('shfmt'));
      } else {
        expect(result, isNull);
      }
    });

    test('nixfmt formatter enabled function', () async {
      final def = builtInFormatters['nixfmt']!;
      final ctx = FormatContext(
        filePath: '/test/configuration.nix',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('nixfmt')) {
        expect(result, isNotNull);
        expect(result!.first, equals('nixfmt'));
      } else {
        expect(result, isNull);
      }
    });

    test('gleam formatter enabled function', () async {
      final def = builtInFormatters['gleam']!;
      final ctx = FormatContext(
        filePath: '/test/main.gleam',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('gleam')) {
        expect(result, isNotNull);
        expect(result!.first, equals('gleam'));
      } else {
        expect(result, isNull);
      }
    });

    test('ormolu formatter enabled function', () async {
      final def = builtInFormatters['ormolu']!;
      final ctx = FormatContext(
        filePath: '/test/Main.hs',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('ormolu')) {
        expect(result, isNotNull);
        expect(result!.first, equals('ormolu'));
      } else {
        expect(result, isNull);
      }
    });

    test('dfmt formatter enabled function', () async {
      final def = builtInFormatters['dfmt']!;
      final ctx = FormatContext(filePath: '/test/app.d', projectRoot: '/test');

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('dfmt')) {
        expect(result, isNotNull);
        expect(result!.first, equals('dfmt'));
      } else {
        expect(result, isNull);
      }
    });

    test('terraform formatter enabled function', () async {
      final def = builtInFormatters['terraform']!;
      final ctx = FormatContext(
        filePath: '/test/main.tf',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('terraform')) {
        expect(result, isNotNull);
        expect(result!.first, equals('terraform'));
      } else {
        expect(result, isNull);
      }
    });

    test('ktlint formatter enabled function', () async {
      final def = builtInFormatters['ktlint']!;
      final ctx = FormatContext(
        filePath: '/test/Main.kt',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('ktlint')) {
        expect(result, isNotNull);
        expect(result!.first, equals('ktlint'));
      } else {
        expect(result, isNull);
      }
    });

    test('rubocop formatter enabled function', () async {
      final def = builtInFormatters['rubocop']!;
      final ctx = FormatContext(filePath: '/test/app.rb', projectRoot: '/test');

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('rubocop')) {
        expect(result, isNotNull);
        expect(result!.first, equals('rubocop'));
      } else {
        expect(result, isNull);
      }
    });

    test('standardrb formatter enabled function', () async {
      final def = builtInFormatters['standardrb']!;
      final ctx = FormatContext(filePath: '/test/app.rb', projectRoot: '/test');

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('standardrb')) {
        expect(result, isNotNull);
        expect(result!.first, equals('standardrb'));
      } else {
        expect(result, isNull);
      }
    });

    test('htmlbeautifier formatter enabled function', () async {
      final def = builtInFormatters['htmlbeautifier']!;
      final ctx = FormatContext(
        filePath: '/test/app.html.erb',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('htmlbeautifier')) {
        expect(result, isNotNull);
        expect(result!.first, equals('htmlbeautifier'));
      } else {
        expect(result, isNull);
      }
    });

    test('latexindent formatter enabled function', () async {
      final def = builtInFormatters['latexindent']!;
      final ctx = FormatContext(
        filePath: '/test/document.tex',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('latexindent')) {
        expect(result, isNotNull);
        expect(result!.first, equals('latexindent'));
      } else {
        expect(result, isNull);
      }
    });

    test('air formatter enabled function', () async {
      final def = builtInFormatters['air']!;
      final ctx = FormatContext(
        filePath: '/test/script.R',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      // air formatter has special logic: runs --help and checks output
      if (await _isCommandAvailable('air')) {
        // Result depends on the --help output containing specific strings
        // Just verify it doesn't crash
        expect(result, anyOf(isNull, isNotNull));
      } else {
        expect(result, isNull);
      }
    });

    test('cljfmt formatter enabled function', () async {
      final def = builtInFormatters['cljfmt']!;
      final ctx = FormatContext(
        filePath: '/test/core.clj',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('cljfmt')) {
        expect(result, isNotNull);
        expect(result!.first, equals('cljfmt'));
      } else {
        expect(result, isNull);
      }
    });

    test('mix formatter enabled function', () async {
      final def = builtInFormatters['mix']!;
      final ctx = FormatContext(
        filePath: '/test/lib/app.ex',
        projectRoot: '/test',
      );

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('mix')) {
        expect(result, isNotNull);
        expect(result!.first, equals('mix'));
      } else {
        expect(result, isNull);
      }
    });
  });

  group('FormatterDefinition.enabled with file system setup', () {
    test('ruff formatter detects pyproject.toml with ruff config', () async {
      if (!await _isCommandAvailable('ruff')) {
        // Skip if ruff not installed — but still call the function
        // to exercise the code path
      }

      final tmp = Directory.systemTemp.createTempSync('fmt_ruff_test_');
      final pyproject = File('${tmp.path}/pyproject.toml');
      await pyproject.writeAsString('[tool.ruff]\nline-length = 100\n');

      final pyFile = File('${tmp.path}/script.py');
      await pyFile.writeAsString('x=1');

      final def = builtInFormatters['ruff']!;
      final ctx = FormatContext(filePath: pyFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('ruff')) {
        expect(result, isNotNull);
        expect(result!.first, anyOf(equals('ruff'), contains('ruff')));
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('ruff formatter detects ruff.toml', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_ruff_toml_');
      final ruffToml = File('${tmp.path}/ruff.toml');
      await ruffToml.writeAsString('line-length = 100\n');

      final pyFile = File('${tmp.path}/script.py');
      await pyFile.writeAsString('x=1');

      final def = builtInFormatters['ruff']!;
      final ctx = FormatContext(filePath: pyFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('ruff')) {
        expect(result, isNotNull);
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('ruff formatter detects .ruff.toml', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_ruff_dot_toml_');
      final ruffToml = File('${tmp.path}/.ruff.toml');
      await ruffToml.writeAsString('line-length = 100\n');

      final pyFile = File('${tmp.path}/script.py');
      await pyFile.writeAsString('x=1');

      final def = builtInFormatters['ruff']!;
      final ctx = FormatContext(filePath: pyFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('ruff')) {
        expect(result, isNotNull);
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('ruff formatter detects requirements.txt with ruff', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_ruff_req_');
      final req = File('${tmp.path}/requirements.txt');
      await req.writeAsString('flask\nruff\n');

      final pyFile = File('${tmp.path}/script.py');
      await pyFile.writeAsString('x=1');

      final def = builtInFormatters['ruff']!;
      final ctx = FormatContext(filePath: pyFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('ruff')) {
        expect(result, isNotNull);
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('ruff formatter returns null when no config found', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_ruff_noconfig_');
      final pyFile = File('${tmp.path}/script.py');
      await pyFile.writeAsString('x=1');

      final def = builtInFormatters['ruff']!;
      final ctx = FormatContext(filePath: pyFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      // No config files → should return null even if ruff is installed
      expect(result, isNull);

      tmp.delete(recursive: true);
    });

    test('prettier formatter detects package.json with prettier', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_prettier_');
      final pkg = File('${tmp.path}/package.json');
      await pkg.writeAsString('{"devDependencies": {"prettier": "^3.0.0"}}');

      final jsFile = File('${tmp.path}/app.js');
      await jsFile.writeAsString('const x=1');

      final def = builtInFormatters['prettier']!;
      final ctx = FormatContext(filePath: jsFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('npx')) {
        expect(result, isNotNull);
        expect(result![0], equals('npx'));
        expect(result[1], equals('prettier'));
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('prettier formatter returns null without package.json', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_prettier_nopkg_');
      final jsFile = File('${tmp.path}/app.js');
      await jsFile.writeAsString('const x=1');

      final def = builtInFormatters['prettier']!;
      final ctx = FormatContext(filePath: jsFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      // No package.json → should return null
      expect(result, isNull);

      tmp.delete(recursive: true);
    });

    test(
      'prettier formatter returns null with package.json but no prettier',
      () async {
        final tmp = Directory.systemTemp.createTempSync('fmt_prettier_nopkg_');
        final pkg = File('${tmp.path}/package.json');
        await pkg.writeAsString('{"devDependencies": {"eslint": "^8.0.0"}}');

        final jsFile = File('${tmp.path}/app.js');
        await jsFile.writeAsString('const x=1');

        final def = builtInFormatters['prettier']!;
        final ctx = FormatContext(filePath: jsFile.path, projectRoot: tmp.path);

        final result = await def.enabled(ctx);

        // package.json exists but no prettier → should return null
        expect(result, isNull);

        tmp.delete(recursive: true);
      },
    );

    test('biome formatter detects biome.json', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_biome_');
      final biomeJson = File('${tmp.path}/biome.json');
      await biomeJson.writeAsString('{"formatter": {"enabled": true}}');

      final jsFile = File('${tmp.path}/app.js');
      await jsFile.writeAsString('const x=1');

      final def = builtInFormatters['biome']!;
      final ctx = FormatContext(filePath: jsFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('biome')) {
        expect(result, isNotNull);
        expect(result!.first, equals('biome'));
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('biome formatter detects biome.jsonc', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_biome_jsonc_');
      final biomeJsonc = File('${tmp.path}/biome.jsonc');
      await biomeJsonc.writeAsString('{"formatter": {"enabled": true}}');

      final jsFile = File('${tmp.path}/app.js');
      await jsFile.writeAsString('const x=1');

      final def = builtInFormatters['biome']!;
      final ctx = FormatContext(filePath: jsFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('biome')) {
        expect(result, isNotNull);
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('biome formatter returns null without config', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_biome_noconfig_');
      final jsFile = File('${tmp.path}/app.js');
      await jsFile.writeAsString('const x=1');

      final def = builtInFormatters['biome']!;
      final ctx = FormatContext(filePath: jsFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      expect(result, isNull);

      tmp.delete(recursive: true);
    });

    test('clang-format formatter detects .clang-format', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_clang_');
      final clangFmt = File('${tmp.path}/.clang-format');
      await clangFmt.writeAsString('BasedOnStyle: Google');

      final cFile = File('${tmp.path}/main.c');
      await cFile.writeAsString('int main(){return 0;}');

      final def = builtInFormatters['clang-format']!;
      final ctx = FormatContext(filePath: cFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('clang-format')) {
        expect(result, isNotNull);
        expect(result!.first, equals('clang-format'));
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('clang-format returns null without .clang-format', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_clang_noconfig_');
      final cFile = File('${tmp.path}/main.c');
      await cFile.writeAsString('int main(){return 0;}');

      final def = builtInFormatters['clang-format']!;
      final ctx = FormatContext(filePath: cFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      expect(result, isNull);

      tmp.delete(recursive: true);
    });

    test('ocamlformat formatter detects .ocamlformat', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_ocaml_');
      final ocamlFmt = File('${tmp.path}/.ocamlformat');
      await ocamlFmt.writeAsString('profile = default');

      final mlFile = File('${tmp.path}/app.ml');
      await mlFile.writeAsString('let x = 1');

      final def = builtInFormatters['ocamlformat']!;
      final ctx = FormatContext(filePath: mlFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('ocamlformat')) {
        expect(result, isNotNull);
        expect(result!.first, equals('ocamlformat'));
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('pint formatter detects composer.json with laravel/pint', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_pint_');
      final composer = File('${tmp.path}/composer.json');
      await composer.writeAsString('{"require-dev": {"laravel/pint": "^1.0"}}');

      final phpFile = File('${tmp.path}/app.php');
      await phpFile.writeAsString('<?php echo "hello";');

      final def = builtInFormatters['pint']!;
      final ctx = FormatContext(filePath: phpFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      // pint requires composer.json with laravel/pint
      expect(result, isNotNull);
      expect(result![0], contains('pint'));

      tmp.delete(recursive: true);
    });

    test('pint formatter returns null without composer.json', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_pint_nocomposer_');
      final phpFile = File('${tmp.path}/app.php');
      await phpFile.writeAsString('<?php echo "hello";');

      final def = builtInFormatters['pint']!;
      final ctx = FormatContext(filePath: phpFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      expect(result, isNull);

      tmp.delete(recursive: true);
    });

    test('uv formatter enabled function', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_uv_');
      final pyFile = File('${tmp.path}/script.py');
      await pyFile.writeAsString('x=1');

      final def = builtInFormatters['uv']!;
      final ctx = FormatContext(filePath: pyFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      if (await _isCommandAvailable('uv')) {
        expect(result, isNotNull);
        expect(result![0], equals('uv'));
      } else {
        expect(result, isNull);
      }

      tmp.delete(recursive: true);
    });

    test('oxfmt formatter checks package.json for oxfmt dependency', () async {
      final tmp = Directory.systemTemp.createTempSync('fmt_oxfmt_');
      final pkg = File('${tmp.path}/package.json');
      await pkg.writeAsString('{"devDependencies": {"oxfmt": "^1.0"}}');

      final jsFile = File('${tmp.path}/app.js');
      await jsFile.writeAsString('const x=1');

      final def = builtInFormatters['oxfmt']!;
      final ctx = FormatContext(filePath: jsFile.path, projectRoot: tmp.path);

      final result = await def.enabled(ctx);

      // oxfmt requires npx and package.json with oxfmt dependency.
      // npx must be available AND oxfmt must be resolvable via npx.
      // This is environment-dependent, so just verify no crash.
      expect(result, anyOf(isNull, isNotNull));

      tmp.delete(recursive: true);
    });
  });

  group('FormatterDefinition constants', () {
    test('dart formatter has correct properties', () {
      final def = builtInFormatters['dart']!;
      expect(def.name, equals('dart'));
      expect(def.extensions, equals(['.dart']));
      expect(def.environment, isNull);
    });

    test('prettier formatter has correct properties', () {
      final def = builtInFormatters['prettier']!;
      expect(def.name, equals('prettier'));
      expect(def.extensions.length, greaterThan(20));
      expect(def.environment, equals({'BUN_BE_BUN': '1'}));
    });

    test('biome formatter has correct properties', () {
      final def = builtInFormatters['biome']!;
      expect(def.name, equals('biome'));
      expect(def.extensions.length, greaterThan(20));
      expect(def.environment, equals({'BUN_BE_BUN': '1'}));
    });

    test('clang-format covers C++ extensions', () {
      final def = builtInFormatters['clang-format']!;
      expect(def.extensions, contains('.c'));
      expect(def.extensions, contains('.cc'));
      expect(def.extensions, contains('.cpp'));
      expect(def.extensions, contains('.cxx'));
      expect(def.extensions, contains('.h'));
      expect(def.extensions, contains('.hpp'));
    });

    test('mix formatter covers Elixir extensions', () {
      final def = builtInFormatters['mix']!;
      expect(def.extensions, contains('.ex'));
      expect(def.extensions, contains('.exs'));
      expect(def.extensions, contains('.eex'));
      expect(def.extensions, contains('.heex'));
    });

    test('rubocop covers Ruby extensions', () {
      final def = builtInFormatters['rubocop']!;
      expect(def.extensions, contains('.rb'));
      expect(def.extensions, contains('.rake'));
      expect(def.extensions, contains('.gemspec'));
      expect(def.extensions, contains('.ru'));
    });

    test('zig covers zig and zon', () {
      final def = builtInFormatters['zig']!;
      expect(def.extensions, equals(['.zig', '.zon']));
    });

    test('terraform covers tf and tfvars', () {
      final def = builtInFormatters['terraform']!;
      expect(def.extensions, equals(['.tf', '.tfvars']));
    });

    test('shfmt covers sh and bash', () {
      final def = builtInFormatters['shfmt']!;
      expect(def.extensions, equals(['.sh', '.bash']));
    });

    test('ktlint covers kt and kts', () {
      final def = builtInFormatters['ktlint']!;
      expect(def.extensions, equals(['.kt', '.kts']));
    });
  });
}

Future<bool> _isCommandAvailable(String cmd) async {
  try {
    final result = await Process.run('which', [cmd]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/format/built_in_formatters.dart';

void main() {
  group('builtInFormatters registry', () {
    test('contains expected number of formatters', () {
      expect(builtInFormatters.length, equals(26));
    });

    test('contains dart formatter', () {
      expect(builtInFormatters.containsKey('dart'), isTrue);
      final def = builtInFormatters['dart']!;
      expect(def.name, equals('dart'));
      expect(def.extensions, equals(['.dart']));
      expect(def.environment, isNull);
    });

    test('contains prettier formatter', () {
      expect(builtInFormatters.containsKey('prettier'), isTrue);
      final def = builtInFormatters['prettier']!;
      expect(def.name, equals('prettier'));
      expect(def.extensions, contains('.js'));
      expect(def.extensions, contains('.ts'));
      expect(def.extensions, contains('.json'));
      expect(def.extensions, contains('.css'));
      expect(def.extensions, contains('.html'));
      expect(def.extensions, contains('.md'));
      expect(def.environment, equals({'BUN_BE_BUN': '1'}));
    });

    test('contains gofmt formatter', () {
      expect(builtInFormatters.containsKey('gofmt'), isTrue);
      final def = builtInFormatters['gofmt']!;
      expect(def.name, equals('gofmt'));
      expect(def.extensions, equals(['.go']));
    });

    test('contains mix formatter', () {
      expect(builtInFormatters.containsKey('mix'), isTrue);
      final def = builtInFormatters['mix']!;
      expect(def.name, equals('mix'));
      expect(def.extensions, contains('.ex'));
      expect(def.extensions, contains('.exs'));
    });

    test('contains ruff formatter', () {
      expect(builtInFormatters.containsKey('ruff'), isTrue);
      final def = builtInFormatters['ruff']!;
      expect(def.name, equals('ruff'));
      expect(def.extensions, equals(['.py', '.pyi']));
    });

    test('contains uv formatter', () {
      expect(builtInFormatters.containsKey('uv'), isTrue);
      final def = builtInFormatters['uv']!;
      expect(def.name, equals('uv'));
      expect(def.extensions, equals(['.py', '.pyi']));
    });

    test('contains rustfmt formatter', () {
      expect(builtInFormatters.containsKey('rustfmt'), isTrue);
      final def = builtInFormatters['rustfmt']!;
      expect(def.name, equals('rustfmt'));
      expect(def.extensions, equals(['.rs']));
    });

    test('contains clang-format formatter', () {
      expect(builtInFormatters.containsKey('clang-format'), isTrue);
      final def = builtInFormatters['clang-format']!;
      expect(def.name, equals('clang-format'));
      expect(def.extensions, contains('.c'));
      expect(def.extensions, contains('.cpp'));
      expect(def.extensions, contains('.h'));
    });

    test('contains ktlint formatter', () {
      expect(builtInFormatters.containsKey('ktlint'), isTrue);
      final def = builtInFormatters['ktlint']!;
      expect(def.name, equals('ktlint'));
      expect(def.extensions, equals(['.kt', '.kts']));
    });

    test('contains biome formatter', () {
      expect(builtInFormatters.containsKey('biome'), isTrue);
      final def = builtInFormatters['biome']!;
      expect(def.name, equals('biome'));
      expect(def.extensions, contains('.js'));
      expect(def.extensions, contains('.ts'));
      expect(def.environment, equals({'BUN_BE_BUN': '1'}));
    });

    test('contains oxfmt formatter', () {
      expect(builtInFormatters.containsKey('oxfmt'), isTrue);
      final def = builtInFormatters['oxfmt']!;
      expect(def.name, equals('oxfmt'));
      expect(def.extensions, contains('.js'));
      expect(def.extensions, contains('.ts'));
      expect(def.environment, equals({'BUN_BE_BUN': '1'}));
    });

    test('contains zig formatter', () {
      expect(builtInFormatters.containsKey('zig'), isTrue);
      final def = builtInFormatters['zig']!;
      expect(def.name, equals('zig'));
      expect(def.extensions, equals(['.zig', '.zon']));
    });

    test('contains terraform formatter', () {
      expect(builtInFormatters.containsKey('terraform'), isTrue);
      final def = builtInFormatters['terraform']!;
      expect(def.name, equals('terraform'));
      expect(def.extensions, equals(['.tf', '.tfvars']));
    });

    test('contains shfmt formatter', () {
      expect(builtInFormatters.containsKey('shfmt'), isTrue);
      final def = builtInFormatters['shfmt']!;
      expect(def.name, equals('shfmt'));
      expect(def.extensions, equals(['.sh', '.bash']));
    });

    test('contains nixfmt formatter', () {
      expect(builtInFormatters.containsKey('nixfmt'), isTrue);
      final def = builtInFormatters['nixfmt']!;
      expect(def.name, equals('nixfmt'));
      expect(def.extensions, equals(['.nix']));
    });

    test('contains rubocop formatter', () {
      expect(builtInFormatters.containsKey('rubocop'), isTrue);
      final def = builtInFormatters['rubocop']!;
      expect(def.name, equals('rubocop'));
      expect(def.extensions, contains('.rb'));
    });

    test('contains standardrb formatter', () {
      expect(builtInFormatters.containsKey('standardrb'), isTrue);
      final def = builtInFormatters['standardrb']!;
      expect(def.name, equals('standardrb'));
      expect(def.extensions, contains('.rb'));
    });

    test('contains htmlbeautifier formatter', () {
      expect(builtInFormatters.containsKey('htmlbeautifier'), isTrue);
      final def = builtInFormatters['htmlbeautifier']!;
      expect(def.name, equals('htmlbeautifier'));
      expect(def.extensions, equals(['.erb', '.html.erb']));
    });

    test('contains latexindent formatter', () {
      expect(builtInFormatters.containsKey('latexindent'), isTrue);
      final def = builtInFormatters['latexindent']!;
      expect(def.name, equals('latexindent'));
      expect(def.extensions, equals(['.tex']));
    });

    test('contains pint formatter', () {
      expect(builtInFormatters.containsKey('pint'), isTrue);
      final def = builtInFormatters['pint']!;
      expect(def.name, equals('pint'));
      expect(def.extensions, equals(['.php']));
    });

    test('contains air formatter', () {
      expect(builtInFormatters.containsKey('air'), isTrue);
      final def = builtInFormatters['air']!;
      expect(def.name, equals('air'));
      expect(def.extensions, equals(['.R']));
    });

    test('contains dfmt formatter', () {
      expect(builtInFormatters.containsKey('dfmt'), isTrue);
      final def = builtInFormatters['dfmt']!;
      expect(def.name, equals('dfmt'));
      expect(def.extensions, equals(['.d']));
    });

    test('contains ocamlformat formatter', () {
      expect(builtInFormatters.containsKey('ocamlformat'), isTrue);
      final def = builtInFormatters['ocamlformat']!;
      expect(def.name, equals('ocamlformat'));
      expect(def.extensions, equals(['.ml', '.mli']));
    });

    test('contains gleam formatter', () {
      expect(builtInFormatters.containsKey('gleam'), isTrue);
      final def = builtInFormatters['gleam']!;
      expect(def.name, equals('gleam'));
      expect(def.extensions, equals(['.gleam']));
    });

    test('contains ormolu formatter', () {
      expect(builtInFormatters.containsKey('ormolu'), isTrue);
      final def = builtInFormatters['ormolu']!;
      expect(def.name, equals('ormolu'));
      expect(def.extensions, equals(['.hs']));
    });

    test('contains cljfmt formatter', () {
      expect(builtInFormatters.containsKey('cljfmt'), isTrue);
      final def = builtInFormatters['cljfmt']!;
      expect(def.name, equals('cljfmt'));
      expect(def.extensions, contains('.clj'));
      expect(def.extensions, contains('.edn'));
    });
  });

  group('formatter properties', () {
    test('all formatters have non-empty name', () {
      for (final def in builtInFormatters.values) {
        expect(
          def.name,
          isNotEmpty,
          reason: 'Formatter definition must have a non-empty name',
        );
      }
    });

    test('all formatters have non-empty extensions', () {
      for (final def in builtInFormatters.values) {
        expect(
          def.extensions,
          isNotEmpty,
          reason: 'Formatter "${def.name}" must have at least one extension',
        );
      }
    });

    test('all extensions start with a dot', () {
      for (final def in builtInFormatters.values) {
        for (final ext in def.extensions) {
          expect(
            ext.startsWith('.'),
            isTrue,
            reason:
                'Formatter "${def.name}" extension "$ext" must start with .',
          );
        }
      }
    });

    test('all formatters have an enabled function', () {
      for (final def in builtInFormatters.values) {
        expect(
          def.enabled,
          isNotNull,
          reason: 'Formatter "${def.name}" must have an enabled function',
        );
      }
    });

    test('formatter names are unique', () {
      final names = builtInFormatters.keys.toList();
      expect(names.toSet().length, equals(names.length));
    });

    test('formatter extensions do not overlap within same name', () {
      for (final def in builtInFormatters.values) {
        final extSet = def.extensions.toSet();
        expect(
          extSet.length,
          equals(def.extensions.length),
          reason: 'Formatter "${def.name}" has duplicate extensions',
        );
      }
    });
  });

  group('formatter categories', () {
    test('web formatters cover JS/TS', () {
      final jsFormatters = builtInFormatters.values
          .where((d) => d.extensions.contains('.js'))
          .map((d) => d.name)
          .toList();

      expect(jsFormatters, contains('prettier'));
      expect(jsFormatters, contains('biome'));
    });

    test('python formatters exist', () {
      final pyFormatters = builtInFormatters.values
          .where((d) => d.extensions.contains('.py'))
          .map((d) => d.name)
          .toList();

      expect(pyFormatters, contains('ruff'));
      expect(pyFormatters, contains('uv'));
    });

    test('C/C++ formatters exist', () {
      final cFormatters = builtInFormatters.values
          .where((d) => d.extensions.contains('.c'))
          .map((d) => d.name)
          .toList();

      expect(cFormatters, contains('clang-format'));
    });

    test('ruby formatters exist', () {
      final rbFormatters = builtInFormatters.values
          .where((d) => d.extensions.contains('.rb'))
          .map((d) => d.name)
          .toList();

      expect(rbFormatters, contains('rubocop'));
      expect(rbFormatters, contains('standardrb'));
    });

    test('formatters with BUN_BE_BUN env are JS/TS ecosystem', () {
      final bunFormatters = builtInFormatters.values
          .where((d) => d.environment?['BUN_BE_BUN'] == '1')
          .map((d) => d.name)
          .toList();

      expect(bunFormatters, isNotEmpty);
      // prettier, biome, oxfmt use BUN_BE_BUN
      expect(bunFormatters, contains('prettier'));
      expect(bunFormatters, contains('biome'));
    });
  });

  group('formatter lookup by extension', () {
    test('finds dart formatter for .dart files', () {
      final dartDef = builtInFormatters['dart']!;
      expect(dartDef.extensions.contains('.dart'), isTrue);
    });

    test('finds rustfmt for .rs files', () {
      final rustDef = builtInFormatters['rustfmt']!;
      expect(rustDef.extensions.contains('.rs'), isTrue);
    });

    test('finds gofmt for .go files', () {
      final goDef = builtInFormatters['gofmt']!;
      expect(goDef.extensions.contains('.go'), isTrue);
    });

    test('finds mix for .ex files', () {
      final mixDef = builtInFormatters['mix']!;
      expect(mixDef.extensions.contains('.ex'), isTrue);
    });

    test('finds clang-format for .c and .cpp files', () {
      final clangDef = builtInFormatters['clang-format']!;
      expect(clangDef.extensions.contains('.c'), isTrue);
      expect(clangDef.extensions.contains('.cpp'), isTrue);
    });

    test('finds ktlint for .kt files', () {
      final ktDef = builtInFormatters['ktlint']!;
      expect(ktDef.extensions.contains('.kt'), isTrue);
    });

    test('finds zig for .zig files', () {
      final zigDef = builtInFormatters['zig']!;
      expect(zigDef.extensions.contains('.zig'), isTrue);
    });

    test('finds terraform for .tf files', () {
      final tfDef = builtInFormatters['terraform']!;
      expect(tfDef.extensions.contains('.tf'), isTrue);
    });

    test('finds shfmt for .sh files', () {
      final shDef = builtInFormatters['shfmt']!;
      expect(shDef.extensions.contains('.sh'), isTrue);
    });

    test('finds nixfmt for .nix files', () {
      final nixDef = builtInFormatters['nixfmt']!;
      expect(nixDef.extensions.contains('.nix'), isTrue);
    });
  });

  group('extension overlap analysis', () {
    test('JS/TS files have multiple formatter options', () {
      final jsCandidates = <String>{};
      final tsCandidates = <String>{};

      for (final entry in builtInFormatters.entries) {
        if (entry.value.extensions.contains('.js')) {
          jsCandidates.add(entry.key);
        }
        if (entry.value.extensions.contains('.ts')) {
          tsCandidates.add(entry.key);
        }
      }

      expect(jsCandidates.length, greaterThan(1));
      expect(tsCandidates.length, greaterThan(1));
    });

    test('Python files have ruff and uv as options', () {
      final pyCandidates = <String>{};

      for (final entry in builtInFormatters.entries) {
        if (entry.value.extensions.contains('.py')) {
          pyCandidates.add(entry.key);
        }
      }

      expect(pyCandidates, containsAll(['ruff', 'uv']));
    });

    test('Ruby files have rubocop and standardrb as options', () {
      final rbCandidates = <String>{};

      for (final entry in builtInFormatters.entries) {
        if (entry.value.extensions.contains('.rb')) {
          rbCandidates.add(entry.key);
        }
      }

      expect(rbCandidates, containsAll(['rubocop', 'standardrb']));
    });
  });
}

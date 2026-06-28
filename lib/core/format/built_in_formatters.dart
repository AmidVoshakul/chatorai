import 'package:chatorai/core/format/formatter_definition.dart';
import 'package:chatorai/core/format/format_utils.dart';

// Common helpers

// dart
const dartFormatter = FormatterDefinition(
  name: 'dart',
  extensions: ['.dart'],
  enabled: _enableDart,
);

Future<List<String>?> _enableDart(FormatContext ctx) async {
  final match = await which('dart');
  if (match == null) return null;
  return [match, 'format', '\$FILE'];
}

// prettier
const prettierFormatter = FormatterDefinition(
  name: 'prettier',
  extensions: [
    '.js',
    '.jsx',
    '.mjs',
    '.cjs',
    '.ts',
    '.tsx',
    '.mts',
    '.cts',
    '.html',
    '.htm',
    '.css',
    '.scss',
    '.sass',
    '.less',
    '.vue',
    '.svelte',
    '.json',
    '.jsonc',
    '.yaml',
    '.yml',
    '.toml',
    '.xml',
    '.md',
    '.mdx',
    '.graphql',
    '.gql',
  ],
  environment: {'BUN_BE_BUN': '1'},
  enabled: _enablePrettier,
);

Future<List<String>?> _enablePrettier(FormatContext ctx) async {
  final dir = ctx.projectRoot;
  for (final candidate in ['package.json']) {
    final found = await findFilesUp(candidate, dir);
    for (final path in found) {
      final content = await readText(path);
      final hasPrettier =
          content.contains('"prettier"') || content.contains("'prettier'");
      if (hasPrettier) {
        final bin = await which('npx');
        if (bin != null) return [bin, 'prettier', '--write', '\$FILE'];
      }
    }
  }
  return null;
}

// gofmt
const gofmtFormatter = FormatterDefinition(
  name: 'gofmt',
  extensions: ['.go'],
  enabled: _enableGofmt,
);

Future<List<String>?> _enableGofmt(FormatContext ctx) async {
  final match = await which('gofmt');
  if (match == null) return null;
  return [match, '-w', '\$FILE'];
}

// mix (Elixir)
const mixFormatter = FormatterDefinition(
  name: 'mix',
  extensions: ['.ex', '.exs', '.eex', '.heex', '.leex', '.neex', '.sface'],
  enabled: _enableMix,
);

Future<List<String>?> _enableMix(FormatContext ctx) async {
  final match = await which('mix');
  if (match == null) return null;
  return [match, 'format', '\$FILE'];
}

// ruff
const ruffFormatter = FormatterDefinition(
  name: 'ruff',
  extensions: ['.py', '.pyi'],
  enabled: _enableRuff,
);

Future<List<String>?> _enableRuff(FormatContext ctx) async {
  if (await which('ruff') == null) return null;

  final configNames = ['pyproject.toml', 'ruff.toml', '.ruff.toml'];
  for (final config in configNames) {
    final found = await findFilesUp(config, ctx.projectRoot);
    for (final path in found) {
      if (config == 'pyproject.toml') {
        final content = await readText(path);
        if (content.contains('[tool.ruff]')) {
          return ['ruff', 'format', '\$FILE'];
        }
      } else {
        return ['ruff', 'format', '\$FILE'];
      }
    }
  }

  final depFiles = ['requirements.txt', 'pyproject.toml', 'Pipfile'];
  for (final dep in depFiles) {
    final found = await findFilesUp(dep, ctx.projectRoot);
    for (final path in found) {
      final content = await readText(path);
      if (content.contains('ruff')) return ['ruff', 'format', '\$FILE'];
    }
  }

  return null;
}

// rustfmt
const rustfmtFormatter = FormatterDefinition(
  name: 'rustfmt',
  extensions: ['.rs'],
  enabled: _enableRustfmt,
);

Future<List<String>?> _enableRustfmt(FormatContext ctx) async {
  final match = await which('rustfmt');
  if (match == null) return null;
  return [match, '\$FILE'];
}

// clang-format
const clangFormatter = FormatterDefinition(
  name: 'clang-format',
  extensions: [
    '.c',
    '.cc',
    '.cpp',
    '.cxx',
    '.c++',
    '.h',
    '.hh',
    '.hpp',
    '.hxx',
    '.h++',
    '.ino',
    '.C',
    '.H',
  ],
  enabled: _enableClangFormat,
);

Future<List<String>?> _enableClangFormat(FormatContext ctx) async {
  final found = await findFilesUp('.clang-format', ctx.projectRoot);
  if (found.isEmpty) return null;
  final match = await which('clang-format');
  if (match == null) return null;
  return [match, '-i', '\$FILE'];
}

// ktlint
const ktlintFormatter = FormatterDefinition(
  name: 'ktlint',
  extensions: ['.kt', '.kts'],
  enabled: _enableKtlint,
);

Future<List<String>?> _enableKtlint(FormatContext ctx) async {
  final match = await which('ktlint');
  if (match == null) return null;
  return [match, '-F', '\$FILE'];
}

// biome
const biomeFormatter = FormatterDefinition(
  name: 'biome',
  extensions: [
    '.js',
    '.jsx',
    '.mjs',
    '.cjs',
    '.ts',
    '.tsx',
    '.mts',
    '.cts',
    '.html',
    '.htm',
    '.css',
    '.scss',
    '.sass',
    '.less',
    '.vue',
    '.svelte',
    '.json',
    '.jsonc',
    '.yaml',
    '.yml',
    '.toml',
    '.xml',
    '.md',
    '.mdx',
    '.graphql',
    '.gql',
  ],
  environment: {'BUN_BE_BUN': '1'},
  enabled: _enableBiome,
);

Future<List<String>?> _enableBiome(FormatContext ctx) async {
  for (final config in ['biome.json', 'biome.jsonc']) {
    final found = await findFilesUp(config, ctx.projectRoot);
    if (found.isNotEmpty) {
      final bin = await which('biome');
      if (bin != null) return [bin, 'format', '--write', '\$FILE'];
    }
  }
  return null;
}

// zig
const zigFormatter = FormatterDefinition(
  name: 'zig',
  extensions: ['.zig', '.zon'],
  enabled: _enableZig,
);

Future<List<String>?> _enableZig(FormatContext ctx) async {
  final match = await which('zig');
  if (match == null) return null;
  return [match, 'fmt', '\$FILE'];
}

// terraform
const terraformFormatter = FormatterDefinition(
  name: 'terraform',
  extensions: ['.tf', '.tfvars'],
  enabled: _enableTerraform,
);

Future<List<String>?> _enableTerraform(FormatContext ctx) async {
  final match = await which('terraform');
  if (match == null) return null;
  return [match, 'fmt', '\$FILE'];
}

// shfmt
const shfmtFormatter = FormatterDefinition(
  name: 'shfmt',
  extensions: ['.sh', '.bash'],
  enabled: _enableShfmt,
);

Future<List<String>?> _enableShfmt(FormatContext ctx) async {
  final match = await which('shfmt');
  if (match == null) return null;
  return [match, '-w', '\$FILE'];
}

// nixfmt
const nixfmtFormatter = FormatterDefinition(
  name: 'nixfmt',
  extensions: ['.nix'],
  enabled: _enableNixfmt,
);

Future<List<String>?> _enableNixfmt(FormatContext ctx) async {
  final match = await which('nixfmt');
  if (match == null) return null;
  return [match, '\$FILE'];
}

// rubocop
const rubocopFormatter = FormatterDefinition(
  name: 'rubocop',
  extensions: ['.rb', '.rake', '.gemspec', '.ru'],
  enabled: _enableRubocop,
);

Future<List<String>?> _enableRubocop(FormatContext ctx) async {
  final match = await which('rubocop');
  if (match == null) return null;
  return [match, '--autocorrect', '\$FILE'];
}

// standardrb
const standardrbFormatter = FormatterDefinition(
  name: 'standardrb',
  extensions: ['.rb', '.rake', '.gemspec', '.ru'],
  enabled: _enableStandardrb,
);

Future<List<String>?> _enableStandardrb(FormatContext ctx) async {
  final match = await which('standardrb');
  if (match == null) return null;
  return [match, '--fix', '\$FILE'];
}

// htmlbeautifier
const htmlbeautifierFormatter = FormatterDefinition(
  name: 'htmlbeautifier',
  extensions: ['.erb', '.html.erb'],
  enabled: _enableHtmlbeautifier,
);

Future<List<String>?> _enableHtmlbeautifier(FormatContext ctx) async {
  final match = await which('htmlbeautifier');
  if (match == null) return null;
  return [match, '\$FILE'];
}

// dfmt (D)
const dfmtFormatter = FormatterDefinition(
  name: 'dfmt',
  extensions: ['.d'],
  enabled: _enableDfmt,
);

Future<List<String>?> _enableDfmt(FormatContext ctx) async {
  final match = await which('dfmt');
  if (match == null) return null;
  return [match, '-i', '\$FILE'];
}

// ocamlformat
const ocamlformatFormatter = FormatterDefinition(
  name: 'ocamlformat',
  extensions: ['.ml', '.mli'],
  enabled: _enableOcamlformat,
);

Future<List<String>?> _enableOcamlformat(FormatContext ctx) async {
  if (await which('ocamlformat') == null) return null;
  final found = await findFilesUp('.ocamlformat', ctx.projectRoot);
  if (found.isEmpty) return null;
  return ['ocamlformat', '-i', '\$FILE'];
}

// gleam
const gleamFormatter = FormatterDefinition(
  name: 'gleam',
  extensions: ['.gleam'],
  enabled: _enableGleam,
);

Future<List<String>?> _enableGleam(FormatContext ctx) async {
  final match = await which('gleam');
  if (match == null) return null;
  return [match, 'format', '\$FILE'];
}

// ormolu (Haskell)
const ormoluFormatter = FormatterDefinition(
  name: 'ormolu',
  extensions: ['.hs'],
  enabled: _enableOrmolu,
);

Future<List<String>?> _enableOrmolu(FormatContext ctx) async {
  final match = await which('ormolu');
  if (match == null) return null;
  return [match, '-i', '\$FILE'];
}

// oxfmt (experimental JS/TS formatter)
const oxfmtFormatter = FormatterDefinition(
  name: 'oxfmt',
  extensions: ['.js', '.jsx', '.mjs', '.cjs', '.ts', '.tsx', '.mts', '.cts'],
  environment: {'BUN_BE_BUN': '1'},
  enabled: _enableOxfmt,
);

Future<List<String>?> _enableOxfmt(FormatContext ctx) async {
  final items = await findFilesUp('package.json', ctx.projectRoot);
  for (final path in items) {
    final json = await readJson(path);
    if ((json['dependencies'] as Map?)?.containsKey('oxfmt') == true ||
        (json['devDependencies'] as Map?)?.containsKey('oxfmt') == true) {
      final bin = await npmWhich('oxfmt');
      if (bin != null) return [bin, '\$FILE'];
    }
  }
  return null;
}

// uvformat (Python, fallback when ruff is unavailable)
const uvFormatter = FormatterDefinition(
  name: 'uv',
  extensions: ['.py', '.pyi'],
  enabled: _enableUv,
);

Future<List<String>?> _enableUv(FormatContext ctx) async {
  if (await which('uv') == null) return null;
  return ['uv', 'format', '--', '\$FILE'];
}

// latexindent
const latexindentFormatter = FormatterDefinition(
  name: 'latexindent',
  extensions: ['.tex'],
  enabled: _enableLatexindent,
);

Future<List<String>?> _enableLatexindent(FormatContext ctx) async {
  final match = await which('latexindent');
  if (match == null) return null;
  return [match, '-w', '-s', '\$FILE'];
}

// pint (PHP Laravel)
const pintFormatter = FormatterDefinition(
  name: 'pint',
  extensions: ['.php'],
  enabled: _enablePint,
);

Future<List<String>?> _enablePint(FormatContext ctx) async {
  final items = await findFilesUp('composer.json', ctx.projectRoot);
  for (final path in items) {
    try {
      final json = await readJson(path);
      final require = json['require'] as Map<String, dynamic>? ?? {};
      final requireDev = json['require-dev'] as Map<String, dynamic>? ?? {};
      if (require.containsKey('laravel/pint') ||
          requireDev.containsKey('laravel/pint')) {
        return ['./vendor/bin/pint', '\$FILE'];
      }
    } catch (_) {}
  }
  return null;
}

// air (R language formatter)
const airFormatter = FormatterDefinition(
  name: 'air',
  extensions: ['.R'],
  enabled: _enableAir,
);

Future<List<String>?> _enableAir(FormatContext ctx) async {
  final match = await which('air');
  if (match == null) return null;
  final result = await processText([match, '--help']);
  if (result.code != 0) return null;
  final firstLine = result.text.split('\n').first;
  if (firstLine.contains('R language') && firstLine.contains('formatter')) {
    return [match, 'format', '\$FILE'];
  }
  return null;
}

// cljfmt (Clojure)
const cljfmtFormatter = FormatterDefinition(
  name: 'cljfmt',
  extensions: ['.clj', '.cljs', '.cljc', '.edn'],
  enabled: _enableCljfmt,
);

Future<List<String>?> _enableCljfmt(FormatContext ctx) async {
  final match = await which('cljfmt');
  if (match == null) return null;
  return [match, 'fix', '--quiet', '\$FILE'];
}

// Registry
final builtInFormatters = <String, FormatterDefinition>{
  'dart': dartFormatter,
  'prettier': prettierFormatter,
  'gofmt': gofmtFormatter,
  'mix': mixFormatter,
  'ruff': ruffFormatter,
  'uv': uvFormatter,
  'rustfmt': rustfmtFormatter,
  'clang-format': clangFormatter,
  'ktlint': ktlintFormatter,
  'biome': biomeFormatter,
  'oxfmt': oxfmtFormatter,
  'zig': zigFormatter,
  'terraform': terraformFormatter,
  'shfmt': shfmtFormatter,
  'nixfmt': nixfmtFormatter,
  'rubocop': rubocopFormatter,
  'standardrb': standardrbFormatter,
  'htmlbeautifier': htmlbeautifierFormatter,
  'latexindent': latexindentFormatter,
  'pint': pintFormatter,
  'air': airFormatter,
  'dfmt': dfmtFormatter,
  'ocamlformat': ocamlformatFormatter,
  'gleam': gleamFormatter,
  'ormolu': ormoluFormatter,
  'cljfmt': cljfmtFormatter,
};

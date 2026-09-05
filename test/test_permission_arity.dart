import 'package:test/test.dart';
import 'package:chatorai/core/permission/arity.dart';

/// Tests for shellArity map and prefix() function.
void main() {
  group('shellArity', () {
    test('contains single-word commands with arity 1', () {
      expect(shellArity['cat'], equals(1));
      expect(shellArity['cd'], equals(1));
      expect(shellArity['echo'], equals(1));
      expect(shellArity['grep'], equals(1));
      expect(shellArity['ls'], equals(1));
      expect(shellArity['mkdir'], equals(1));
      expect(shellArity['pwd'], equals(1));
      expect(shellArity['rm'], equals(1));
      expect(shellArity['touch'], equals(1));
    });

    test('contains two-word prefixes with arity 2', () {
      expect(shellArity['git'], equals(2));
      expect(shellArity['npm'], equals(2));
      expect(shellArity['yarn'], equals(2));
      expect(shellArity['cargo'], equals(2));
      expect(shellArity['docker'], equals(2));
      expect(shellArity['kubectl'], equals(2));
      expect(shellArity['python'], equals(2));
      expect(shellArity['go'], equals(2));
    });

    test('contains three-word prefixes with arity 3', () {
      // 'git commit' is NOT in the map, only 'git config', 'git remote', 'git stash'
      expect(shellArity['git config'], equals(3));
      expect(shellArity['git remote'], equals(3));
      expect(shellArity['git stash'], equals(3));
      expect(shellArity['npm run'], equals(3));
      expect(shellArity['npm exec'], equals(3));
      expect(shellArity['yarn run'], equals(3));
      expect(shellArity['yarn dlx'], equals(3));
      expect(shellArity['docker compose'], equals(3));
      expect(shellArity['docker container'], equals(3));
      expect(shellArity['docker image'], equals(3));
      // 'aws s3' is NOT in the map, only 'aws' with arity 3
      expect(shellArity['aws'], equals(3));
      expect(shellArity['gcloud'], equals(3));
      expect(shellArity['gh'], equals(3));
    });

    test('contains four-word prefixes with arity 3', () {
      expect(shellArity['docker builder'], equals(3));
      expect(shellArity['docker network'], equals(3));
      expect(shellArity['docker volume'], equals(3));
      expect(shellArity['eksctl create'], equals(3));
      expect(shellArity['kubectl kustomize'], equals(3));
      expect(shellArity['kubectl rollout'], equals(3));
      expect(shellArity['podman container'], equals(3));
      expect(shellArity['podman image'], equals(3));
      expect(shellArity['ip addr'], equals(3));
      expect(shellArity['ip link'], equals(3));
      expect(shellArity['ip netns'], equals(3));
      expect(shellArity['ip route'], equals(3));
      expect(shellArity['mc admin'], equals(3));
      expect(shellArity['vault auth'], equals(3));
      expect(shellArity['vault kv'], equals(3));
      expect(shellArity['consul kv'], equals(3));
      expect(shellArity['terraform workspace'], equals(3));
      expect(shellArity['pulumi stack'], equals(3));
      expect(shellArity['openssl req'], equals(3));
      expect(shellArity['openssl x509'], equals(3));
      expect(shellArity['pnpm dlx'], equals(3));
      expect(shellArity['pnpm exec'], equals(3));
      expect(shellArity['pnpm run'], equals(3));
    });

    test('map is not empty', () {
      expect(shellArity, isNotEmpty);
      expect(shellArity.length, greaterThan(50));
    });

    test('all values are positive integers', () {
      for (final entry in shellArity.entries) {
        expect(
          entry.value,
          greaterThan(0),
          reason: 'Arity for "${entry.key}" must be positive',
        );
      }
    });

    test('keys are lowercase', () {
      for (final key in shellArity.keys) {
        expect(
          key,
          equals(key.toLowerCase()),
          reason: 'Key "$key" should be lowercase',
        );
      }
    });
  });

  group('prefix()', () {
    test('returns full arity tokens for single-word command', () {
      final result = prefix(['cat', 'file.txt']);
      expect(result, equals(['cat']));
    });

    test('returns full arity tokens for two-word prefix', () {
      final result = prefix(['git', 'status']);
      expect(result, equals(['git', 'status']));
    });

    test('returns full arity tokens for three-word prefix', () {
      // 'git config' has arity 3, 'git' has arity 2
      // With 4 tokens, finds 'git config' at len=2? No, 'git config' != 'git commit'
      // Actually 'git config' is in the map but 'git commit' is NOT.
      // So it falls back to 'git' with arity 2.
      final result = prefix(['git', 'config', 'user.name', 'Alice']);
      expect(result, equals(['git', 'config', 'user.name']));
    });

    test('returns only command when args exceed arity', () {
      final result = prefix(['ls', '-la', '/tmp']);
      expect(result, equals(['ls']));
    });

    test('stops at longest matching prefix', () {
      // "docker compose" has arity 3, "docker" has arity 2
      // With 3+ tokens, should return 3 tokens
      final result = prefix(['docker', 'compose', 'up', '-d']);
      expect(result, equals(['docker', 'compose', 'up']));
    });

    test('falls back to shorter prefix when no longer match', () {
      // "git" has arity 2, "git commit" has arity 3
      // With only 2 tokens, should return 2 tokens
      final result = prefix(['git', 'status']);
      expect(result, equals(['git', 'status']));
    });

    test('returns first token when no prefix matches', () {
      // "xyzunknown" is not in shellArity
      final result = prefix(['xyzunknown', 'arg1', 'arg2']);
      expect(result, equals(['xyzunknown']));
    });

    test('returns empty list for empty tokens', () {
      final result = prefix([]);
      expect(result, isEmpty);
    });

    test('handles single token that is in shellArity', () {
      final result = prefix(['cat']);
      expect(result, equals(['cat']));
    });

    test('handles single token not in shellArity', () {
      final result = prefix(['unknowncmd']);
      expect(result, equals(['unknowncmd']));
    });

    test('handles npm run with extra args', () {
      final result = prefix(['npm', 'run', 'build', '--', '--watch']);
      expect(result, equals(['npm', 'run', 'build']));
    });

    test('handles yarn dlx with extra args', () {
      final result = prefix(['yarn', 'dlx', 'turbo', 'run', 'build']);
      expect(result, equals(['yarn', 'dlx', 'turbo']));
    });

    test('handles docker compose with subcommand', () {
      final result = prefix(['docker', 'compose', 'up']);
      expect(result, equals(['docker', 'compose', 'up']));
    });

    test('handles kubectl with single arg', () {
      final result = prefix(['kubectl', 'get', 'pods']);
      expect(result, equals(['kubectl', 'get']));
    });

    test('handles python with script', () {
      // 'python' has arity 2, so returns first 2 tokens
      final result = prefix(['python', 'script.py', '--flag']);
      expect(result, equals(['python', 'script.py']));
    });

    test('handles cargo run with args', () {
      // 'cargo run' has arity 3, so returns first 3 tokens
      final result = prefix(['cargo', 'run', '--release']);
      expect(result, equals(['cargo', 'run', '--release']));
    });

    test('handles pip install with package', () {
      final result = prefix(['pip', 'install', 'package']);
      expect(result, equals(['pip', 'install']));
    });

    test('handles tokens with flags', () {
      final result = prefix(['grep', '-r', 'pattern', '/dir']);
      expect(result, equals(['grep']));
    });

    test('handles git config with key value', () {
      final result = prefix(['git', 'config', 'user.name', 'Alice']);
      expect(result, equals(['git', 'config', 'user.name']));
    });

    test('handles tokens where only prefix is present', () {
      // "git" alone — should return ["git"] since arity is 2 but only 1 token
      final result = prefix(['git']);
      expect(result, equals(['git']));
    });

    test('handles bun run with extra args', () {
      final result = prefix(['bun', 'run', 'dev', '--port', '3000']);
      expect(result, equals(['bun', 'run', 'dev']));
    });

    test('handles pnpm run with script name', () {
      final result = prefix(['pnpm', 'run', 'lint', '--fix']);
      expect(result, equals(['pnpm', 'run', 'lint']));
    });

    test('handles tokens with no matching multi-word prefix', () {
      // "echo" has arity 1, no multi-word prefix starts with "echo"
      final result = prefix(['echo', 'hello', 'world']);
      expect(result, equals(['echo']));
    });

    test('returns correct arity for ip addr', () {
      final result = prefix(['ip', 'addr', 'show']);
      expect(result, equals(['ip', 'addr', 'show']));
    });

    test('returns correct arity for ip link', () {
      final result = prefix(['ip', 'link', 'set', 'eth0', 'up']);
      expect(result, equals(['ip', 'link', 'set']));
    });

    test('returns correct arity for vault kv', () {
      final result = prefix(['vault', 'kv', 'get', 'secret/data']);
      expect(result, equals(['vault', 'kv', 'get']));
    });

    test('returns correct arity for terraform workspace', () {
      final result = prefix(['terraform', 'workspace', 'select', 'prod']);
      expect(result, equals(['terraform', 'workspace', 'select']));
    });

    test('returns correct arity for openssl req', () {
      final result = prefix(['openssl', 'req', '-new', '-x509']);
      expect(result, equals(['openssl', 'req', '-new']));
    });
  });
}

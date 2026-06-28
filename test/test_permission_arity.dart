import 'package:test/test.dart';
import 'package:chatorai/core/permission/arity.dart';

/// Tests for bashArity map and prefix() function.
void main() {
  group('bashArity', () {
    test('contains single-word commands with arity 1', () {
      expect(bashArity['cat'], equals(1));
      expect(bashArity['cd'], equals(1));
      expect(bashArity['echo'], equals(1));
      expect(bashArity['grep'], equals(1));
      expect(bashArity['ls'], equals(1));
      expect(bashArity['mkdir'], equals(1));
      expect(bashArity['pwd'], equals(1));
      expect(bashArity['rm'], equals(1));
      expect(bashArity['touch'], equals(1));
    });

    test('contains two-word prefixes with arity 2', () {
      expect(bashArity['git'], equals(2));
      expect(bashArity['npm'], equals(2));
      expect(bashArity['yarn'], equals(2));
      expect(bashArity['cargo'], equals(2));
      expect(bashArity['docker'], equals(2));
      expect(bashArity['kubectl'], equals(2));
      expect(bashArity['python'], equals(2));
      expect(bashArity['go'], equals(2));
    });

    test('contains three-word prefixes with arity 3', () {
      // 'git commit' is NOT in the map, only 'git config', 'git remote', 'git stash'
      expect(bashArity['git config'], equals(3));
      expect(bashArity['git remote'], equals(3));
      expect(bashArity['git stash'], equals(3));
      expect(bashArity['npm run'], equals(3));
      expect(bashArity['npm exec'], equals(3));
      expect(bashArity['yarn run'], equals(3));
      expect(bashArity['yarn dlx'], equals(3));
      expect(bashArity['docker compose'], equals(3));
      expect(bashArity['docker container'], equals(3));
      expect(bashArity['docker image'], equals(3));
      // 'aws s3' is NOT in the map, only 'aws' with arity 3
      expect(bashArity['aws'], equals(3));
      expect(bashArity['gcloud'], equals(3));
      expect(bashArity['gh'], equals(3));
    });

    test('contains four-word prefixes with arity 3', () {
      expect(bashArity['docker builder'], equals(3));
      expect(bashArity['docker network'], equals(3));
      expect(bashArity['docker volume'], equals(3));
      expect(bashArity['eksctl create'], equals(3));
      expect(bashArity['kubectl kustomize'], equals(3));
      expect(bashArity['kubectl rollout'], equals(3));
      expect(bashArity['podman container'], equals(3));
      expect(bashArity['podman image'], equals(3));
      expect(bashArity['ip addr'], equals(3));
      expect(bashArity['ip link'], equals(3));
      expect(bashArity['ip netns'], equals(3));
      expect(bashArity['ip route'], equals(3));
      expect(bashArity['mc admin'], equals(3));
      expect(bashArity['vault auth'], equals(3));
      expect(bashArity['vault kv'], equals(3));
      expect(bashArity['consul kv'], equals(3));
      expect(bashArity['terraform workspace'], equals(3));
      expect(bashArity['pulumi stack'], equals(3));
      expect(bashArity['openssl req'], equals(3));
      expect(bashArity['openssl x509'], equals(3));
      expect(bashArity['pnpm dlx'], equals(3));
      expect(bashArity['pnpm exec'], equals(3));
      expect(bashArity['pnpm run'], equals(3));
    });

    test('map is not empty', () {
      expect(bashArity, isNotEmpty);
      expect(bashArity.length, greaterThan(50));
    });

    test('all values are positive integers', () {
      for (final entry in bashArity.entries) {
        expect(
          entry.value,
          greaterThan(0),
          reason: 'Arity for "${entry.key}" must be positive',
        );
      }
    });

    test('keys are lowercase', () {
      for (final key in bashArity.keys) {
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
      // "xyzunknown" is not in bashArity
      final result = prefix(['xyzunknown', 'arg1', 'arg2']);
      expect(result, equals(['xyzunknown']));
    });

    test('returns empty list for empty tokens', () {
      final result = prefix([]);
      expect(result, isEmpty);
    });

    test('handles single token that is in bashArity', () {
      final result = prefix(['cat']);
      expect(result, equals(['cat']));
    });

    test('handles single token not in bashArity', () {
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

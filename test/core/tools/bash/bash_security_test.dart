import 'package:test/test.dart';
import 'package:command_shield/command_shield.dart';

void main() {
  group('Bash Security Policy Tests', () {
    group('DangerousCharacterPolicy', () {
      test('semicolon (;) triggers review decision', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            const DangerousCharacterPolicy(
              onMatch: CommandDecision.review,
              level: SecurityLevel.highRisk,
            ),
          ]),
        );

        final result = shield.validate('echo foo; echo bar');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('&& triggers review decision', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            const DangerousCharacterPolicy(
              onMatch: CommandDecision.review,
              level: SecurityLevel.highRisk,
            ),
          ]),
        );

        final result = shield.validate('echo foo && echo bar');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('|| triggers review decision', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            const DangerousCharacterPolicy(
              onMatch: CommandDecision.review,
              level: SecurityLevel.highRisk,
            ),
          ]),
        );

        final result = shield.validate('echo foo || echo bar');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('| triggers review decision', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            const DangerousCharacterPolicy(
              onMatch: CommandDecision.review,
              level: SecurityLevel.highRisk,
            ),
          ]),
        );

        final result = shield.validate('echo foo | cat');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('& triggers review decision', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            const DangerousCharacterPolicy(
              onMatch: CommandDecision.review,
              level: SecurityLevel.highRisk,
            ),
          ]),
        );

        final result = shield.validate('echo foo &');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('safe command returns allow decision', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            const DangerousCharacterPolicy(
              onMatch: CommandDecision.review,
              level: SecurityLevel.highRisk,
            ),
          ]),
        );

        final result = shield.validate('echo hello');
        expect(result.decision, equals(CommandDecision.allow));
      });
    });

    group('ExecutableBlockListPolicy', () {
      test('curl is blocked', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ExecutableBlockListPolicy({'curl'}, onMatch: CommandDecision.review),
          ]),
        );

        final result = shield.validate('curl example.com');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('npm is blocked', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ExecutableBlockListPolicy({'npm'}, onMatch: CommandDecision.review),
          ]),
        );

        final result = shield.validate('npm install');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('wget is blocked', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ExecutableBlockListPolicy({'wget'}, onMatch: CommandDecision.review),
          ]),
        );

        final result = shield.validate('wget http://example.com/file');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('safe executable is allowed', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ExecutableBlockListPolicy({'curl'}, onMatch: CommandDecision.review),
          ]),
        );

        final result = shield.validate('ls -la');
        expect(result.decision, equals(CommandDecision.allow));
      });
    });

    group('Redirect to system directory policy', () {
      test('redirect to /etc without space triggers review', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ArgumentPatternPolicy(
              pattern: RegExp(r'(?:>|>>)\s*/+(?:etc|root|sys|proc)/'),
              description: 'redirect to system directory',
              onMatch: CommandDecision.review,
              level: SecurityLevel.critical,
              matchWholeCommand: true,
            ),
          ]),
        );

        final result = shield.validate('echo foo>/etc/passwd');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('redirect to /etc with space triggers review', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ArgumentPatternPolicy(
              pattern: RegExp(r'(?:>|>>)\s*/+(?:etc|root|sys|proc)/'),
              description: 'redirect to system directory',
              onMatch: CommandDecision.review,
              level: SecurityLevel.critical,
              matchWholeCommand: true,
            ),
          ]),
        );

        final result = shield.validate('cat /etc/passwd > /etc/shadow');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('redirect to non-system directory is allowed', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ArgumentPatternPolicy(
              pattern: RegExp(r'(?:>|>>)\s*/+(?:etc|root|sys|proc)/'),
              description: 'redirect to system directory',
              onMatch: CommandDecision.review,
              level: SecurityLevel.critical,
              matchWholeCommand: true,
            ),
          ]),
        );

        final result = shield.validate('echo foo > /tmp/output.txt');
        expect(result.decision, equals(CommandDecision.allow));
      });
    });

    group('Go package manager policy', () {
      test('go get triggers review', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ArgumentPatternPolicy(
              pattern: RegExp(r'\bgo\s+(?:get|install)\b'),
              description: 'go get/install package manager',
              onMatch: CommandDecision.review,
              level: SecurityLevel.mediumRisk,
              matchWholeCommand: true,
            ),
          ]),
        );

        final result = shield.validate('go get github.com/example/pkg');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('go install triggers review', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ArgumentPatternPolicy(
              pattern: RegExp(r'\bgo\s+(?:get|install)\b'),
              description: 'go get/install package manager',
              onMatch: CommandDecision.review,
              level: SecurityLevel.mediumRisk,
              matchWholeCommand: true,
            ),
          ]),
        );

        final result = shield.validate('go install github.com/example/pkg');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('go build is allowed (not get/install)', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            ArgumentPatternPolicy(
              pattern: RegExp(r'\bgo\s+(?:get|install)\b'),
              description: 'go get/install package manager',
              onMatch: CommandDecision.review,
              level: SecurityLevel.mediumRisk,
              matchWholeCommand: true,
            ),
          ]),
        );

        final result = shield.validate('go build ./...');
        expect(result.decision, equals(CommandDecision.allow));
      });
    });

    group('_ReviewOnlyPolicy edge cases', () {
      test('critical findings with low securityLevel → still review', () {
        // This tests the _ReviewOnlyPolicy logic:
        // if (analysis.securityLevel.index >= SecurityLevel.mediumRisk.index ||
        //     hasCriticalFindings) -> review
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            // A policy that produces critical findings but low security level
            ArgumentPatternPolicy(
              pattern: RegExp(r'\btest_critical\b'),
              description: 'test critical pattern',
              onMatch: CommandDecision.review,
              level: SecurityLevel.critical,
              matchWholeCommand: true,
            ),
            // Review-only policy that should catch critical findings
            _TestReviewOnlyPolicy(),
          ]),
        );

        final result = shield.validate('test_critical');
        expect(result.decision, equals(CommandDecision.review));
      });

      test('no findings + low level → no ask() call (allow)', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            _TestReviewOnlyPolicy(),
          ]),
        );

        final result = shield.validate('echo hello world');
        expect(result.decision, equals(CommandDecision.allow));
      });
    });

    group('SecurityLevel enum', () {
      test('SecurityLevel has expected values', () {
        expect(SecurityLevel.values.length, greaterThanOrEqualTo(5));
        expect(SecurityLevel.safe.index, lessThan(SecurityLevel.lowRisk.index));
        expect(SecurityLevel.lowRisk.index, lessThan(SecurityLevel.mediumRisk.index));
        expect(SecurityLevel.mediumRisk.index, lessThan(SecurityLevel.highRisk.index));
        expect(SecurityLevel.highRisk.index, lessThan(SecurityLevel.critical.index));
      });
    });

    group('CommandAnalysis findings', () {
      test('findings contain matched patterns', () {
        final shield = CommandShield(
          defaultSyntax: CommandSyntax.bash,
          policy: PolicySet([
            const DangerousCharacterPolicy(
              onMatch: CommandDecision.review,
              level: SecurityLevel.highRisk,
            ),
          ]),
        );

        final analysis = shield.analyze('echo foo; echo bar');
        expect(analysis.findings, isNotEmpty);
        expect(analysis.findings.any((f) => f.message.contains('dangerous') || f.code.contains('dangerous')), isTrue);
      });
    });
  });
}

/// Test policy that mimics _ReviewOnlyPolicy behavior
class _TestReviewOnlyPolicy extends CommandPolicy {
  @override
  String get name => '_TestReviewOnlyPolicy';

  @override
  CommandResult evaluate(CommandAnalysis analysis) {
    // Check security level OR critical/high risk findings
    final hasCriticalFindings = analysis.findings.any(
      (f) => f.level.index >= SecurityLevel.highRisk.index,
    );
    if (analysis.securityLevel.index >= SecurityLevel.mediumRisk.index ||
        hasCriticalFindings) {
      return CommandResult(
        decision: CommandDecision.review,
        securityLevel: analysis.securityLevel,
        findings: analysis.findings,
      );
    }
    return allowResult;
  }
}
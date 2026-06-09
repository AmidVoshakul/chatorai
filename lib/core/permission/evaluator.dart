import 'package:collection/collection.dart';
import 'rule.dart';
import 'wildcard.dart';
import 'ruleset.dart';

PermissionRule evaluate(
  String permission,
  String pattern,
  List<PermissionRuleset> rulesets,
) {
  // Flat-map all rules from all rulesets
  final allRules = <PermissionRule>[];

  for (final ruleset in rulesets) {
    allRules.addAll(ruleset.rules);
    allRules.addAll(ruleset.sessionApproved);
  }

  // Find LAST matching rule (findLast)
  final matched = allRules.lastWhereOrNull((rule) {
    return match(permission, rule.permission) && match(pattern, rule.pattern);
  });

  if (matched != null) {
    return matched;
  }

  // Default if no match: ask
  return PermissionRule(
    permission: permission,
    pattern: '*',
    action: PermissionAction.ask,
  );
}

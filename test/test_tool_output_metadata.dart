import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/tool_output_metadata.dart';
import 'package:chatorai/core/tools/tool.dart';

ToolOutput _out(Map<String, dynamic>? meta) =>
    ToolOutput('result', metadata: meta);

void main() {
  group('ToolOutputMetadata — generic flags', () {
    test('isError true when metadata[error] == true', () {
      expect(_out({'error': true}).isError, isTrue);
    });

    test('isError false when metadata[error] is missing', () {
      expect(_out({}).isError, isFalse);
    });

    test('isError false when metadata[error] is non-true', () {
      expect(_out({'error': false}).isError, isFalse);
      expect(_out({'error': 'yes'}).isError, isFalse);
    });

    test('isAborted true when metadata[aborted] == true', () {
      expect(_out({'aborted': true}).isAborted, isTrue);
    });

    test('isAborted false when metadata[aborted] is missing', () {
      expect(_out(null).isAborted, isFalse);
    });

    test('all getters return null/false when metadata is null', () {
      final o = _out(null);
      expect(o.isError, isFalse);
      expect(o.isAborted, isFalse);
      expect(o.bashExitCode, isNull);
      expect(o.readTotalLines, isNull);
      expect(o.writePath, isNull);
      expect(o.globCount, isNull);
      expect(o.fetchTimedOut, isFalse);
      expect(o.patchContextMismatch, isFalse);
      expect(o.skillLoaded, isFalse);
    });
  });

  group('ToolOutputMetadata — bash', () {
    test('bashExitCode returns int value', () {
      expect(_out({'exit_code': 0}).bashExitCode, 0);
      expect(_out({'exit_code': 127}).bashExitCode, 127);
    });

    test('bashBannedCommand returns string', () {
      expect(_out({'banned': 'rm -rf'}).bashBannedCommand, 'rm -rf');
    });
  });

  group('ToolOutputMetadata — read', () {
    test('readTotalLines / readOffset / readLimit', () {
      final o = _out({'lines': 42, 'offset': 5, 'limit': 20});
      expect(o.readTotalLines, 42);
      expect(o.readOffset, 5);
      expect(o.readLimit, 20);
    });

    test('readIsBinary true when metadata[binary] == true', () {
      expect(_out({'binary': true}).readIsBinary, isTrue);
      expect(_out({'binary': false}).readIsBinary, isFalse);
    });

    test('readBinarySizeBytes returns int', () {
      expect(_out({'size': 1024}).readBinarySizeBytes, 1024);
    });

    test('readFilePath returns string', () {
      expect(_out({'file_path': '/tmp/x.txt'}).readFilePath, '/tmp/x.txt');
    });
  });

  group('ToolOutputMetadata — write', () {
    test('writePath / writeBytes', () {
      final o = _out({'path': '/tmp/out.txt', 'bytes': 256});
      expect(o.writePath, '/tmp/out.txt');
      expect(o.writeBytes, 256);
    });
  });

  group('ToolOutputMetadata — edit', () {
    test('editPath returns string', () {
      expect(_out({'path': '/tmp/e.dart'}).editPath, '/tmp/e.dart');
    });
  });

  group('ToolOutputMetadata — glob / grep', () {
    test('globCount / grepCount', () {
      expect(_out({'count': 7}).globCount, 7);
      expect(_out({'count': 99}).grepCount, 99);
    });
  });

  group('ToolOutputMetadata — webfetch', () {
    test('fetchMaxChars / fetchTimedOut', () {
      final o = _out({'max_chars': 5000, 'timeout': true});
      expect(o.fetchMaxChars, 5000);
      expect(o.fetchTimedOut, isTrue);
    });

    test('fetchTimedOut false when key missing', () {
      expect(_out({}).fetchTimedOut, isFalse);
    });
  });

  group('ToolOutputMetadata — websearch', () {
    test('searchCount / searchQuery / searchProvider', () {
      final o = _out({'count': 3, 'query': 'flutter', 'provider': 'exa'});
      expect(o.searchCount, 3);
      expect(o.searchQuery, 'flutter');
      expect(o.searchProvider, 'exa');
    });

    test('searchResults returns cast list', () {
      final o = _out({
        'results': [
          {'title': 'A', 'url': 'http://a'},
          {'title': 'B', 'url': 'http://b'},
        ],
      });
      final results = o.searchResults;
      expect(results, isNotNull);
      expect(results!.length, 2);
      expect(results[0]['title'], 'A');
    });

    test('searchResults null when key missing', () {
      expect(_out({}).searchResults, isNull);
    });
  });

  group('ToolOutputMetadata — apply_patch', () {
    test('patchOldCount / patchNewCount', () {
      final o = _out({'old_count': 2, 'new_count': 4});
      expect(o.patchOldCount, 2);
      expect(o.patchNewCount, 4);
    });

    test('patchContextMismatch / patchBoundsError / patchWarning', () {
      final o = _out({
        'context_mismatch': true,
        'bounds_error': true,
        'warning': true,
      });
      expect(o.patchContextMismatch, isTrue);
      expect(o.patchBoundsError, isTrue);
      expect(o.patchWarning, isTrue);
    });

    test('all patch flags false when keys missing', () {
      final o = _out({});
      expect(o.patchContextMismatch, isFalse);
      expect(o.patchBoundsError, isFalse);
      expect(o.patchWarning, isFalse);
    });
  });

  group('ToolOutputMetadata — todowrite', () {
    test('todoCount / todoSessionId', () {
      final o = _out({'count': 5, 'sessionId': 'ses_123'});
      expect(o.todoCount, 5);
      expect(o.todoSessionId, 'ses_123');
    });

    test('todoList returns nested list', () {
      final o = _out({
        'todos': {
          'todos': [
            {'id': '1', 'content': 'task one'},
          ],
        },
      });
      final list = o.todoList;
      expect(list, isNotNull);
      expect(list!.length, 1);
      expect((list[0] as Map)['id'], '1');
    });

    test('todoList null when structure missing', () {
      expect(_out({}).todoList, isNull);
    });
  });

  group('ToolOutputMetadata — question', () {
    test('questionList returns list', () {
      final o = _out({
        'questions': [
          {'id': 'q1', 'prompt': 'Continue?'},
        ],
      });
      expect(o.questionList, isNotNull);
      expect(o.questionList!.length, 1);
    });

    test('questionAwaitingResponse flag', () {
      expect(
        _out({'awaiting_response': true}).questionAwaitingResponse,
        isTrue,
      );
      expect(_out({}).questionAwaitingResponse, isFalse);
    });
  });

  group('ToolOutputMetadata — task', () {
    test(
      'taskSessionId / taskSubagentType / taskAgentName / taskDescription / taskId',
      () {
        final o = _out({
          'session_id': 'ses_9',
          'subagent_type': 'explore',
          'agent_name': 'code-reviewer',
          'description': 'Review PR',
          'task_id': 'task_42',
        });
        expect(o.taskSessionId, 'ses_9');
        expect(o.taskSubagentType, 'explore');
        expect(o.taskAgentName, 'code-reviewer');
        expect(o.taskDescription, 'Review PR');
        expect(o.taskId, 'task_42');
      },
    );
  });

  group('ToolOutputMetadata — skill', () {
    test('skillLoaded true when metadata[skill] == true', () {
      expect(_out({'skill': true}).skillLoaded, isTrue);
      expect(_out({}).skillLoaded, isFalse);
    });

    test('skillName returns string', () {
      expect(_out({'name': 'my-skill'}).skillName, 'my-skill');
    });
  });

  group('ToolOutputMetadata — persistence', () {
    test(
      'persistenceToolCallId / persistenceToolName / persistenceSessionId',
      () {
        final o = _out({
          'toolCallId': 'tc_1',
          'toolName': 'bash',
          'sessionId': 'ses_p',
          'durationMs': 120,
          'status': 'success',
        });
        expect(o.persistenceToolCallId, 'tc_1');
        expect(o.persistenceToolName, 'bash');
        expect(o.persistenceSessionId, 'ses_p');
        expect(o.persistenceDurationMs, 120);
        expect(o.persistenceStatus, 'success');
      },
    );
  });
}

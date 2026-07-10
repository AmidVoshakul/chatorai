# Chat Parts Widgets

Reusable widgets for rendering individual message parts in the chat interface.

## Directory Structure

```
widgets/
├── chat_message_bubble.dart  — Dispatcher widget (switch by message type)
├── parts/                    — Message part widgets
│   ├── text_part_widget.dart
│   ├── reasoning_part_widget.dart
│   ├── tool_result_part_widget.dart
│   ├── task_part_widget.dart
│   ├── question_part_widget.dart
│   ├── todo_part_widget.dart
│   ├── error_message_widget.dart
│   ├── bash_body.dart
│   ├── read_body.dart
│   ├── grep_body.dart
│   ├── write_body.dart
│   ├── edit_body.dart
│   ├── lsp_body.dart
│   ├── patch_body.dart
│   ├── generic_body_widget.dart
│   ├── webfetch_body.dart
│   ├── diff_line.dart
│   ├── assistant_header.dart
│   └── action_row.dart
```

## Public API

Only `ChatMessageBubble` and `ToolResultPartWidget` are exported as public widgets.

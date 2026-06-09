sealed class ToolError {
  final String toolName;
  const ToolError(this.toolName);
}

class ToolNotFoundError extends ToolError {
  const ToolNotFoundError(super.name);
}

class ToolTimeoutError extends ToolError {
  const ToolTimeoutError(super.name);
}

class ToolPermissionDeniedError extends ToolError {
  const ToolPermissionDeniedError(super.name);
}

class ToolExecutionError extends ToolError {
  final String message;
  const ToolExecutionError(super.name, this.message);
}

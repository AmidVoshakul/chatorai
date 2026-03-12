# Contributing to ChatORAI

Thank you for your interest in contributing to ChatORAI!

## Code of Conduct

By participating in this project, you are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- A quick summary and background
- Steps to reproduce
- What you expected vs what happened
- Notes (possibly including why you think this might be happening)

### Suggesting Features

Open an issue with a detailed description of the feature you'd like to see.

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes (`flutter test`)
5. Make sure your code lints (`flutter analyze`)
6. Write a clear commit message
7. Push your changes to your fork
8. Submit a pull request

## Development Setup

```bash
# Clone the repository
git clone https://github.com/AmidVoshakul/chatorai.git
cd chatorai

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run with code generation
flutter gen-l10n
```

## Style Guidelines

- Follow the Flutter style guide
- Use meaningful variable and function names
- Comment complex logic
- Keep functions small and focused

## Testing

All new features should include unit tests. Run tests with:

```bash
flutter test
```

For coverage report:

```bash
flutter test --coverage
```

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

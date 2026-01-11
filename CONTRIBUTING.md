# Contributing to StepComp

Thank you for your interest in contributing to StepComp! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs. actual behavior
- iOS version, device model, and Xcode version (if applicable)
- Screenshots or error messages (if applicable)

### Suggesting Features

Feature suggestions are welcome! Please open an issue with:
- A clear description of the feature
- Use cases and benefits
- Any mockups or design ideas (if applicable)

### Pull Requests

1. **Fork the repository** and create a new branch from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our coding standards:
   - Follow Swift style guidelines
   - Use meaningful variable and function names
   - Add comments for complex logic
   - Ensure code compiles without warnings

3. **Test your changes**:
   - Test on multiple iOS versions if possible
   - Test on different device sizes
   - Verify no regressions were introduced

4. **Commit your changes** with clear, descriptive commit messages:
   ```bash
   git commit -m "Add feature: description of what you did"
   ```

5. **Push to your fork** and open a Pull Request:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Update documentation** if your changes affect:
   - User-facing features
   - API or service interfaces
   - Setup or configuration

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/jerhunseservtrax/StepComp.git
   cd StepComp
   ```

2. **Open in Xcode**
   ```bash
   open StepComp.xcodeproj
   ```

3. **Configure Supabase** (see `docs/setup/SUPABASE_SETUP.md`)

4. **Build and run** the project

## Coding Standards

### Swift Style Guide

- Use Swift 5.7+ features
- Follow Swift API Design Guidelines
- Use meaningful names for variables, functions, and types
- Prefer `let` over `var` when possible
- Use guard statements for early returns
- Keep functions focused and single-purpose

### SwiftUI Best Practices

- Use `@State`, `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` appropriately
- Break down complex views into smaller, reusable components
- Use `@ViewBuilder` for view composition
- Follow MVVM architecture pattern

### File Organization

- Group related files in appropriate folders
- Use MARK comments to organize code sections
- Keep view models in `ViewModels/`
- Keep services in `Services/`
- Keep models in `Models/`

## Project Structure

```
StepComp/
├── App/              # App entry point and root views
├── Models/           # Data models
├── Services/         # Business logic (Auth, Challenges, HealthKit)
├── ViewModels/       # MVVM view models
├── Screens/          # SwiftUI views
├── Utilities/        # Helper functions and extensions
└── docs/             # Documentation
```

## Testing

- Test your changes thoroughly before submitting
- Consider edge cases and error scenarios
- Test on different iOS versions when possible
- Verify UI looks correct on different device sizes

## Documentation

- Update README.md if you add new features
- Add comments to complex code sections
- Update relevant documentation in `docs/` folder
- Include examples in code comments when helpful

## Questions?

If you have questions about contributing, feel free to:
- Open an issue with the `question` label
- Check existing documentation in the `docs/` folder

Thank you for contributing to StepComp! 🎉

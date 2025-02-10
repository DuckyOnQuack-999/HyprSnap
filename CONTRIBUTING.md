# Contributing to HyprSnap

First off, thank you for considering contributing to HyprSnap! It's people like you that make HyprSnap such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* Use a clear and descriptive title
* Follow the bug report template
* Include your system information
* Attach debug logs
* Provide clear steps to reproduce

### Suggesting Enhancements

If you have a suggestion for the project:

* Use a clear and descriptive title
* Follow the feature request template
* Provide a step-by-step description of the suggested enhancement
* Explain why this enhancement would be useful
* List any additional requirements

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code passes `shellcheck`
6. Follow the pull request template

## Development Process

1. Clone the repo
```bash
git clone https://github.com/DuckyOnQuack-999/HyprSnap.git
cd HyprSnap
```

2. Create a branch
```bash
git checkout -b feature/my-feature
# or
git checkout -b fix/my-fix
```

3. Make your changes
* Write meaningful commit messages
* Add tests for new features
* Update documentation as needed

4. Test your changes
```bash
# Run the test suite
./tests/run_tests.sh

# Test with debug output
./hyprsnap.sh record -d
```

5. Push and create a PR
```bash
git push origin feature/my-feature
```

## Styleguides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* Consider starting the commit message with an applicable emoji:
    * 🎨 `:art:` when improving the format/structure of the code
    * 🐛 `:bug:` when fixing a bug
    * ✨ `:sparkles:` when adding a new feature
    * 📝 `:memo:` when writing docs
    * 🚀 `:rocket:` when improving performance
    * ✅ `:white_check_mark:` when adding tests
    * 🔧 `:wrench:` when updating configs

### Shell Script Styleguide

* Use `shellcheck` to verify your code
* Follow Google's Shell Style Guide
* Use meaningful variable names
* Comment complex logic
* Use functions for reusable code
* Handle errors appropriately
* Use `set -euo pipefail`

### Documentation Styleguide

* Use Markdown
* Reference functions and variables in backticks
* Include code examples where appropriate
* Keep line length to 80 characters
* Use descriptive link texts

## Additional Notes

### Issue and Pull Request Labels

* `bug`: Something isn't working
* `enhancement`: New feature or request
* `documentation`: Improvements or additions to documentation
* `good first issue`: Good for newcomers
* `help wanted`: Extra attention is needed
* `invalid`: This doesn't seem right
* `question`: Further information is requested
* `wontfix`: This will not be worked on

## Recognition

Contributors will be recognized in:
* The project's README.md
* The CHANGELOG.md file
* GitHub's contributors page

Thank you for contributing to HyprSnap! 🚀 
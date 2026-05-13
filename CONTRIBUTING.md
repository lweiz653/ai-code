# Contributing Guidelines

Thank you for considering contributing to this project!

## Running Tests

The project uses **pytest** for its test suite. To run the tests locally:

```bash
pip install -r requirements.txt   # Install dependencies (if any)
pytest                           # Run all tests
```

If there are no tests yet, this command will simply exit without failures.

## Opening a Pull Request

1. Fork the repository.
2. Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b my-feature
   ```
3. Commit your changes with a clear and concise commit message.
4. Push the branch to your fork:
   ```bash
   git push origin my-feature
   ```
5. Open a pull request on the `main` branch of the original repository.

Please ensure that your PR:
- Includes any new or updated tests.
- Passes all existing tests.
- Follows the project's coding style.

Thank you for helping improve the project!

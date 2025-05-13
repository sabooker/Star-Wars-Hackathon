# Contributing to Star Wars Hackathon

First off, thank you for considering contributing to the Star Wars Hackathon project! It's people like you that make this project such a great tool for demonstrating ServiceNow Discovery capabilities.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* Use a clear and descriptive title
* Describe the exact steps which reproduce the problem
* Provide specific examples to demonstrate the steps
* Describe the behavior you observed after following the steps
* Explain which behavior you expected to see instead and why
* Include logs and error messages

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* Use a clear and descriptive title
* Provide a step-by-step description of the suggested enhancement
* Provide specific examples to demonstrate the steps
* Describe the current behavior and explain which behavior you expected to see instead
* Explain why this enhancement would be useful

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Terraform style guide
* Include thoughtfully-worded, well-structured commit messages
* Test your changes thoroughly
* Update documentation as needed

## Development Process

1. Fork the repo and create your branch from `main`
2. Make your changes following the coding standards
3. Test your changes locally
4. Ensure your code follows the existing style
5. Submit a pull request!

## Terraform Style Guide

### General Principles

* Use consistent indentation (2 spaces)
* Use meaningful resource names that follow the Star Wars theme
* Always include descriptions for variables and outputs
* Group related resources together
* Comment complex logic

### Resource Naming

Follow the Star Wars naming convention:
```hcl
resource "aws_instance" "millennium_falcon_db" {
  # Configuration
}
```

### Variable Naming

Use descriptive variable names:
```hcl
variable "windows_instance_types" {
  description = "Instance types for Windows servers"
  type        = map(string)
  default     = {}
}
```

### Module Structure

Each module should have:
* `main.tf` - Main resource definitions
* `variables.tf` - Input variables
* `outputs.tf` - Output values
* `README.md` - Module documentation

## Testing

Before submitting a PR:

1. Run `terraform fmt` to format your code
2. Run `terraform validate` to check syntax
3. Run `terraform plan` to verify changes
4. Test in a development environment if possible

## Documentation

* Update README.md if you change functionality
* Add comments for complex Terraform logic
* Update variable descriptions if you add new ones
* Include examples for new features

## Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

Example:
```
Add PostgreSQL support for Rebel database servers

- Configure PostgreSQL on RHEL instances
- Add backup configuration
- Include monitoring setup
- Update security groups for PostgreSQL port

Fixes #123
```

## Adding New Resources

When adding new resources:

1. Follow the Star Wars naming theme
2. Update the instance inventory in README.md
3. Add appropriate outputs
4. Update the cost optimization tracking
5. Include in ServiceNow discovery configuration

## Questions?

Feel free to open an issue for any questions about contributing.

May the Force be with your contributions!

import { danger, warn, fail } from "danger";

// Warn on big PRs
if (danger.github.pr.additions + danger.github.pr.deletions > 600) {
  warn("Big PR, consider splitting into smaller");
}

// Require a meaningful PR description
if (danger.github.pr.body.length < 5) {
  fail("Please provide a summary in the Pull Request description");
}

// Check for empty PRs
const allFiles = [
  ...danger.git.modified_files,
  ...danger.git.created_files,
  ...danger.git.deleted_files,
];
if (allFiles.length === 0) {
  fail("This PR has no changes at all, this is likely an issue during development.");
}

// Flag work in progress
if (danger.github.pr.title.includes("[WIP]")) {
  warn("PR is classed as Work in Progress");
}

// Warn on Package.swift changes
if (danger.git.modified_files.includes("Package.swift")) {
  warn("The `Package.swift` was updated");
}

warn "Big PR, consider splitting into smaller" if git.lines_of_code > 600
has_app_changes = !git.modified_files.grep(/ProjectName/).empty?

# Mainly to encourage writing up some reasoning about the PR, rather than
# just leaving a title
if github.pr_body.length < 5
  fail "Please provide a summary in the Pull Request description"
end

# If these are all empty something has gone wrong, better to raise it in a comment
if git.modified_files.empty? && git.added_files.empty? && git.deleted_files.empty?
  fail "This PR has no changes at all, this is likely an issue during development."
end

# if the PR is listed as a work in progress
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

podfile_updated = !git.modified_files.grep(/Podfile/).empty?
# Leave warning, if Podfile changes
warn("The `Podfile` was updated") if podfile_updated

# This is swiftlint plugin. More info: https://github.com/ashfurrow/danger-swiftlint
#
# This lints all Swift files and leave comments in PR if 
# there is any issue with linting
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files inline_mode: true

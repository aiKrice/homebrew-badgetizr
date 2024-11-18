# Badgetizr

## To read before going further: I need your star !
I would like to put this tool available with Homebrew and Apt-Get. Tu succeed, I need a maximum of star on this repository (according to the submission of Homebrew, min = 40stars). By using Homebrew or apt-get, I will be able to simplify the installation process by skipping the configure step below 🚀. Thank you for your help!

## Installation

```bash
$ ./configure && ./badgetizer.sh
```

## Configuration
You can look to the `.badgetizr.yml.example` file at the root of the repository to see the different configuration options available.

### Badge Ticket
Disabled by default.

The badge ticket is a badge that will be displayed on your pull request if you have a Jira ticket or a Youtrack ticket in your pull request title or overall, something you would like to extract from the pull request title.
To do so, you have to define a pattern that will be used to extract the data (ie: ticket id). This pattern will be used with the `sed` command with the `-n -E` options and the `p` flag and will extract the first occurrence of the pattern found in the string.

For example, consider the following pull request title: `[ABC-123] My Pull Request Title`.
If you set the pattern to `.*\(([^)]+)\).*`, the ticket id `ABC-123` will be extracted from the pull request title.
You can also use the url option to define the url of the badge by letting `%s` as a placeholder for the ticket id. `url: "https://yourproject.atlassian.net/browse/%s"` will be `https://yourproject.atlassian.net/browse/ABC-123`.
You don't need to escape the `-` and ` ` characters, they will be automatically escaped.

### Badge Wip
Enabled by default.
The badge wip is a badge that will be displayed on your pull request if the pull request title contains the word `WIP` whatever the case.

### Badge Dynamic
Disabled by default.
The badge dynamic is a badge that will be displayed on your pull request if the pull request body contains a pattern. You can define multiple patterns and each pattern will be displayed with a badge.

### Badge Base Branch
Enabled by default.
The badge base branch is a badge that will be displayed on your pull request to indicate the target branch of the pull request. The default value is `develop`.

example:
```yaml
- pattern: "- [ ] Task 1"
  label: "Task 1"
  value: "Not done"
  color: "orange"
```
will display:
![Static Badge](https://img.shields.io/badge/Task_1-Not_done-orange) if the checkbox is not checked.

In this case you can also use this to display a badge if the checkbox is checked.
example:
```yaml
- pattern: "- \\[[xX]\\] Task 1"
  label: "Task 1"
  value: "Done"
  color: "green"
```

will display:
![Static Badge](https://img.shields.io/badge/Task_1-Done-green) if the checkbox is checked.

You don't need to escape the `-` and ` ` characters, they will be automatically escaped.

⚠️ Beware currently the regex has limitations, it is not using sed regex but only bash regex by checking if the pattern is found in the string (like a `contains`). An opened issue has been created and you are welcome to contribute to fix this ❤️.

## Contributing

You are welcome to contribute to this project. The current rules to follow is that each time you are opening a pull request, you have to generate yourself the badge inside the pull request by running the script locally on your machine when your forked the repository.

example:
```bash
export GITHUB_TOKEN="your_github_token"
export BADGETIZR_BUILD_NUMBER="123"
export BADGETIZR_BUILD_URL="https://random.url%s"
export BADGETIZR_PR_DESTINATION_BRANCH="develop"
$ ./configure && ./badgetizer.sh
```
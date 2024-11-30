
<h1 align="center">
    Badgetizr
</h1>

<h2 align="center">
    Add badges to your pull requests and increase your productivity 🚀.
</h2>

<div id="header" align="center">
  <img src="badgetizr_screen.png" width="1000"/>
</div>

---

## To read before going further: I need your ⭐ !
_📣 I would like to put this tool available with Homebrew and Apt-Get. To succeed, I need a maximum of star on this repository (according to the submission of Homebrew, min = 40stars). By using Homebrew or apt-get, I will be able to simplify the installation process by skipping the configure step below 🚀. Thank you for your help!_

## Roadmap
- [x] Add option to use a custom configuration file
- [ ] Make the badge_ci badge dynamic (success, failure, pending)
- [ ] Add a beautiful icon for this repository
- [ ] Improve the Readme.md file
- [x] Add the tools to Homebrew tap
- [ ] Add the tool to Homebrew
- [ ] Add the tool to Apt-Get
- [ ] Add the tools to Github Actions
- [ ] Add the tools to Github Marketplace
- [ ] Support natively Gitlab with `glab` CLI

To see how to contribute, please refer to the section [Contributing](#contributing).

## I am 🇫🇷 and I love coffee ☕.
I am fully engaged to make this tool the best tool ever to add badges to your pull requests and increase your productivity 🚀. The roadmap is huge and I will do my best to achieve all of this and achieve my goal to make this the best tool to add badges to your pull requests. If you want to support me, you can buy me a coffee, you will be mentioned in the README.md file as a backer ❤️.

<a href='https://ko-fi.com/Q5Q7PPTYK' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

## Installation via Homebrew (MacOS)
For now, only Github Pull Requests are supported. You have to export the environment variables `GITHUB_TOKEN` such as:
```bash
export GITHUB_TOKEN="your_github_token"
```

Then you can run the configure script and the badgetizer script:
```bash
$ brew tap aiKrice/badgetizr
$ brew install aiKrice/badgetizr/badgetizr
# edit the .badgetizr.yml file to your needs
$ export GITHUB_TOKEN="your_github_token"
$ export BADGETIZR_BUILD_NUMBER="123" # the build number of your CI
$ export BADGETIZR_BUILD_URL="https://your-shiny-ci.io/app/build/123" # the build url of your CI
$ export BADGETIZR_PR_DESTINATION_BRANCH="develop" # the destination branch of your PR from the CI.
```

## Installation via Apt-Get (Linux)
Coming soon...

## Installation manually
```bash
$ git clone https://github.com/aiKrice/badgetizr.git --branch master
$ cd badgetizr
$ ./configure
```
In the rest of the documentation, I will consider that you have installed the tool in your `$PATH` and remove the `.sh` extension from the binary name.

## Usage
```bash
$ badgetizr 
```

By default, the configuration file used is `.badgetizr.yml`. You can also specify a configuration file to use by using the `-c` option.
```bash
$ badgetizer -c my_config.yml
```

## Configuration
You can look to the `.badgetizr.yml.example` file at the root of the repository to see the different configuration options available.

All icons are available at [simpleicons.org](https://simpleicons.org/).

## Badges

### Badge Ticket
`Disabled` by default.

The badge ticket is a badge that will be displayed on your pull request if you have a Jira ticket or a Youtrack ticket in your pull request title or overall, something you would like to extract from the pull request title.
To do so, you have to define a pattern that will be used to extract the data (ie: ticket id). This pattern will be used with the `sed` command with the `-n -E` options and the `p` flag and will extract the first occurrence of the pattern found in the string.

For example, consider the following pull request title: `[ABC-123] My Pull Request Title`.
If you set the pattern to `.*\(([^)]+)\).*`, the ticket id `ABC-123` will be extracted from the pull request title.
You can also use the url option to define the url of the badge by letting `%s` as a placeholder for the ticket id. `url: "https://yourproject.atlassian.net/browse/%s"` will be `https://yourproject.atlassian.net/browse/ABC-123`.
You don't need to escape the `-` and ` ` characters, they will be automatically escaped.

### Badge Wip
`Enabled` by default.

The badge wip is a badge that will be displayed on your pull request if the pull request title contains the word `WIP` whatever the case.

### Badge Dynamic
`Disabled` by default.

The badge dynamic is a badge that will be displayed on your pull request if the pull request body contains a pattern. You can define multiple patterns and each pattern will be displayed with a badge.

### Badge Base Branch
`Enabled` by default.

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
- pattern: "- [x] Task 2"
  label: "Task 2"
  value: "Done"
  color: "green"
```

will display:
![Static Badge](https://img.shields.io/badge/Task_1-Done-green) if the checkbox is checked.

You don't need to escape the `-` and ` ` characters, they will be automatically escaped.

⚠️ Beware currently the regex has limitations, it is not using sed regex but only bash regex by checking if the pattern is found in the string (like a `contains`). An opened issue has been created and you are welcome to contribute to fix this ❤️.

### Badge CI
`Disabled` by default.

The badge ci is a badge that will be displayed on your pull request to indicate the status of the CI pipeline, the build number and the build url. Currently the status is not dynamic but it will be in a short future.

You must define the build number and the build url in your environment variables such as 
```shell
export BADGETIZR_BUILD_NUMBER="123"
export BADGETIZR_BUILD_URL="https://random.url%s"
```

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

## Release (for maintainers)
To release the tool, you can run the `deploy-homebrew.sh` script by providing the version you want to release. Please respect the semantic versioning notation.
```bash
./deploy-homebrew.sh 1.1.3
```

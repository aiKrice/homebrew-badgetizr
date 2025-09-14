
<h1 align="center">
    <img src="logo.png" alt="Badgetizr Logo" width="120"/>
    <br/>
    Badgetizr

![Static Badge](https://img.shields.io/badge/1.5.5-darkgreen?logo=homebrew&logoColor=white&label=Homebrew-tap)
[![Static Badge](https://img.shields.io/badge/1.5.5-grey?logo=github&logoColor=white&label=Github-Action&labelColor=black)](https://github.com/marketplace/actions/badgetizr)
![Static Badge](https://img.shields.io/badge/passed-darkgreen?logo=github&logoColor=white&label=Github&labelColor=black)
![Static Badge](https://img.shields.io/badge/soon-pink?logo=gitlab&logoColor=orange&label=Gitlab&labelColor=white)

</h1>

<h2 align="center">
    Add badges to your pull requests and increase your productivity 🚀.
</h2>

<div id="header" align="center">
  <img src="badgetizr_screen.png" width="1000"/>
</div>

---

## What is Badgetizr ?
Badgetizr is a tool that will add badges to your pull requests to increase your team's productivity. It is fully customizable and you can add (almost) as many badges as you want. With Badgetizr on your CI, you will be able to save time by:
- Stop adding a link to your ticket in the description of the PR if you add the id of it in the title of the PR.
- Reminding that some tasks are still missing to do in the PR.
- Stop adding a visual indicator if your PR is a WIP.
- Having a badge to know the status of the CI pipeline without having to click on it, scrolling down to the bottom of the page _(coming soon)_.

## To read before going further: I need your ⭐ !
_📣 I would like to put this tool available with Homebrew and Apt-Get. To succeed, I need a maximum of star on this repository (according to the submission of Homebrew, min = 75stars). By using Homebrew or apt-get, I will be able to simplify the installation process by skipping the configure step below 🚀. Thank you for your help!_

## Roadmap
- [x] Add option to use a custom configuration file
- [ ] Make the badge_ci badge dynamic (success, failure, pending)
- [x] Add a beautiful icon for this repository
- [x] Improve the Readme.md file
- [x] Add the tools to Homebrew tap
- [ ] Add the tool to Homebrew
- [ ] Add the tool to Apt-Get
- [x] Add the tools to Github Actions
- [ ] Support natively Gitlab with `glab` CLI

To see how to contribute, please refer to the section [Contributing](#contributing).

## I like coffee ☕.
If your productivity has increased, my mission is done 🎉. This means I can go back to my coffee and enjoy it 🤤. If you want to support me, you can buy me a coffee, you will be mentioned in the README.md file as a backer ❤️. It will also motivate me to continue to work on this tool and improve it. 
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
```

## Installation via Apt-Get (Linux)
Coming soon...

## Installation manually (for MacOS and Linux)
```bash
$ git clone https://github.com/aiKrice/badgetizr.git --branch master
$ cd badgetizr
$ ./configure
```
In the rest of the documentation, I will consider that you have installed the tool in your `$PATH` and remove the `.sh` extension from the binary name.

## Usage (CLI)
```bash
$ badgetizr #[options]
```
To see the different options available, you can use the `--help` option:
```bash
$ badgetizr --help
```

## Usage GithubAction
Instead of using the CLI, you can directly use the github action in your workflow.
```yaml
jobs:
  badgetizr:
    runs-on: ubuntu-latest #works also on macos-latest

    steps:
      - name: Checkout the repository
        uses: actions/checkout@v3

      - name: Run Badgetizr
        uses: aiKrice/homebrew-badgetizr@1.5.5
        with:
          pr_id: ${{ github.event.pull_request.number }}
          configuration: .badgetizr.yml
          pr_destination_branch: ${{ github.event.pull_request.base.ref }}
          pr_build_number: ${{ github.run_id }}
          pr_build_url: "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```

## Configuration
By default, the configuration file used is `.badgetizr.yml`. You can also specify a configuration file to use by using the `-c` option.
```bash
$ badgetizr -c my_config.yml
```
You can look to the `.badgetizr.yml.example` file at the root of the repository to see the different configuration options available.

If you want to use a custom icon for your badges, you can use the `icon` option and specify the icon name (badge ci only). All icons are available at [simpleicons.org](https://simpleicons.org/).

## Badges

### Badge Ticket [![Static Badge](https://img.shields.io/badge/JIRA-GH--1234-blue?logo=jirasoftware&color=blue&labelColor=grey)](https://yourproject.atlassian.net/browse/badge)
#### Status
 `Disabled` by default.

#### Description 

The badge ticket is a badge that will be displayed on your pull request if you have a Jira ticket or a Youtrack ticket in your pull request title or overall, something you would like to extract from the pull request title.
To do so, you have to define a pattern that will be used to extract the data (ie: ticket id). This pattern will be used with the `sed` command with the `-n -E` options and the `p` flag and will extract the first occurrence of the pattern found in the string. Badgetizr will process the pattern like this: `sed -n -E "s/${ticket_badge_pattern}/\1/p"'`. You have to provide a regex group with ()

#### Configuration:
- `color`: The color of the badge (default: `blue`).
- `label`: The label of the badge (default: `JIRA`).
- `logo`: The logo of the badge (default: `jirasoftware`).
- `sed_pattern`: The pattern to use to extract the ticket id from the pull request title (default: `.*\(([^)]+)\).*`, will match something like `feat(ABC-123):  My Pull Request Title` -> `ABC-123`).
- `url`: The url of the badge (default: `https://yourproject.atlassian.net/browse/%s`, will be `https://yourproject.atlassian.net/browse/ABC-123`). You don't need to escape the `-` and ` ` characters, they will be automatically escaped.

### Badge Wip ![Static Badge](https://img.shields.io/badge/WIP-yellow?logo=vlcmediaplayer&logoColor=white)

#### Status
`Enabled` by default.

#### Description
The badge wip is a badge that will be displayed on your pull request if the pull request title contains the word `WIP` whatever the case.

example:
```yaml
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    logo: "vlcmediaplayer"
    labelized: "Work In Progress"
```

### Badge Dynamic ![Static Badge](https://img.shields.io/badge/Task_2-Done-grey?label=Task%202&labelColor=grey&color=darkgreen)
#### Status
`Disabled` by default.

#### Description
The badge dynamic is a badge that will be displayed on your pull request if the pull request body contains a pattern. You can define multiple patterns and each pattern will be displayed with a badge.

#### Configuration:
- `color`: The color of the badge (default: `grey`).
- `label`: The label of the badge (default: `Task 2`).
- `value`: The value of the badge (default: `Done`).
- `sed_pattern`: The pattern which will be applied against the pull request body (default: `no pattern`). A regex group `()` must be present or it will trigger a sed error. See .badgetizr.yml.example file.

example:
```yaml
- sed_pattern: "(- [ ] Task 1)"
  label: "Task 1"
  value: "Not done"
  color: "orange"
```
will display: ![Static Badge](https://img.shields.io/badge/Task_1-Not_done-orange) if the checkbox is not checked.

In this case you can also use this to display a badge if the checkbox is checked.
example:
```yaml
- sed_pattern: "(- [x] Task 2)"
  label: "Task 2"
  value: "Done"
  color: "green"
```

will display: ![Static Badge](https://img.shields.io/badge/Task_1-Done-green) if the checkbox is checked.

You don't need to escape the `-` and ` ` characters, they will be automatically escaped.

⚠️ Beware currently the regex has limitations, it is not using sed regex but only bash regex by checking if the pattern is found in the string (like a `contains`). An [opened issue](https://github.com/aiKrice/homebrew-badgetizr/issues/5) has been created and you are welcome to contribute to fix this ❤️.

### Badge Base Branch ![Static Badge](https://img.shields.io/badge/Base_Branch-master-orange?labelColor=grey&color=red)

#### Status
`Disabled` by default.

#### Description
The badge base branch is a badge that will be displayed on your pull request to indicate the target branch of the pull request. The default value is `develop`.

#### CLI Parameters
- `--pr-destination-branch`: The base branch to use to compare the pull request to.

### Badge CI [![Static Badge](https://img.shields.io/badge/My_CI-Build_number-purple?logo=bitrise&logoColor=white&labelColor=purple&color=green)](https://www.google.com)
#### Status
 `Disabled` by default.

#### Description 
The `badge ci` is a badge that will be displayed on your pull request to indicate the status of the CI pipeline, the build number and the build url. Currently the status is **static** but it will be **dynamic** in a short future.

#### CLI Parameters:
- `--pr-build-number`: The build number of the CI pipeline.
- `--pr-build-url`: The build url of the CI pipeline.

#### Configuration:
- `color`: The color of the badge (default: `purple`).
- `label`: The label of the badge (default: `Bitrise`).
- `logo`: The logo of the badge (default: `bitrise`).

#### Example
```yaml
badge_ticket:
  enabled: "true"
  settings:
    color: "black"
    label: "Github"
    sed_pattern: '.*\[GH-([0-9]+)\].*'
    url: "https://github.com/aiKrice/badgetizr/issues/%s"
    logo: "github"
```
will match feat(scope): implement stuff [GH-1234] #will extract 1234

## Contributing
You are welcome to contribute to this project. The current rules to follow is that each time you are opening a pull request, you have to generate yourself the badge inside the pull request by running the script locally on your machine when your forked the repository.

example:
```bash
export GITHUB_TOKEN="your_github_token"
$ ./configure #optional, just for dependencies
$ ./badgetizer.sh
```

## Publishing (for maintainers)
To publish the tool, you can run the `publish.sh` script by providing the version you want to release. Please respect the semantic versioning notation.
```bash
./publish.sh 1.1.3
```
This script will bump everything possible to keep everything up-to-date.
name: Update README with ABOUT.md and INSTALL.md

on:
  schedule:
    - cron: '0 6 * * 1'   # every Monday at 06:00 UTC
  workflow_dispatch:       # manual trigger

jobs:
  call-shared:
    if: ${{ hashFiles('README.template.md') != '' }}   # only run if the file exists
    uses: control-toolbox/CTActions/.github/workflows/update-readme.yml@main
    with:
      template_file: README.template.md
      output_file: README.md
      package_name: OptimalControl   # package for INSTALL.md
      repo_name: OptimalControl.jl   # repository for CONTRIBUTING.md links
      citation_badge: "[![DOI](https://zenodo.org/badge/541187171.svg)](https://zenodo.org/doi/10.5281/zenodo.16753152)" # example, can be empty
      assignee: "ocots"
    secrets: inherit

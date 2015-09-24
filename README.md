[![Build Status](https://snap-ci.com/snap-ci/snap-deploy/branch/master/build_image)](https://snap-ci.com/snap-ci/snap-deploy/branch/master)

# SnapDeploy

A deploy tool for continuous deployment. Used by [Snap CI](https://snap-ci.com)

## Installation

Add this line to your application's Gemfile:

    gem 'snap_deploy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snap_deploy

## Usage

Currently, it supports aws and heroku deploy. You can use the commands below for more informations:

    $ snap-deploy heroku --help
    $ snap-deploy aws --help

## Contributing

1. Fork it ( https://github.com/[my-github-username]/snap_deploy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

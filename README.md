[![Build Status](https://snap-ci.com/snap-ci/snap-deploy/branch/master/build_image)](https://snap-ci.com/snap-ci/snap-deploy/branch/master)

# SnapDeploy

A simple cli tool to help with Heroku and AWS deployments. Used by [Snap CI](https://snap-ci.com). To report any issues, [please contact the Snap.ci support team.](https://snap-ci.com/contact-us)

## Installation

SnapDeploy is already available in the Snap CI build environment. You can simply start using it in your builds by invoking the `snap-deploy` command.

If you want to use `snap-deploy` outside the Snap CI environment, you can add this line to your application's Gemfile:

    gem 'snap_deploy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snap_deploy

> Ruby version support: We will supporting this gem only with ruby 2.2.4. If there is reason you would like to use this gem with some other version of ruby, please get in touch with us by writing to support@snap-ci.com

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

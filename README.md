# README

## Prerequisites

This project uses rbenv to manage the Ruby version the `.ruby-version` file.
Please make sure that's installed and configured and you will automatically
use the correct Ruby version when working with this project.

You will also need the `libpq` library installed (on a Mac, use Homebrew to
install it `brew install libpq` and then configure Bundler to use the Homebrew
version with `bundle config build.pg --with-pg-config=/opt/homebrew/opt/libpq/bin/pg_config`).

You can now run `bundle` to have a copy of your dependencies available in
your local environment.

If you would like to run commands locally, then it's worth creating a `.env`
file with the correct environment variables set:

```shell
cat >.env <<EOF
SEARCH_DB_HOST=localhost
SEARCH_DB_PORT=5460
SEARCH_DB_USER=local_office_search_api
SEARCH_DB_PASSWORD=develop
SEARCH_DB_NAME=local_office_search_api
EOF
```

If you're not on the Citizens Advice network, you should add the following

```yaml
version: '3'

services:
  local-office-search-api:
    build:
      args:
        cab_gem_mirror: 'false'
```

Finally, you must now add the following to your hosts file:

```
127.0.0.1	local-office-search-api.test
```

## Starting a local copy

The easiest way to start a local copy of the app is to use Docker. Run
`bin/docker/start` to do this. Once you're done, `bin/docker/stop` does ends
the application!

You should then be able to visit the app at http://local-office-search-api.test:3060/.

## Running tests

This repo uses Rails' Minitest framework. To quickly run all the tests:
`bundle exec rake test`.

Linting is also available, and this is done using Rubocop, following
[Citizens' Advice code style](https://github.com/citizensadvice/citizens-advice-style-ruby).

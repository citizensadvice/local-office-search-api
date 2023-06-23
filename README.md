# Local Office Search API

This is a codebase which provides an API that allows users to find a local Citizens Advice
bureaux which serves their geographic area. It powers the Find Your Local Citizens Advice
function on www.citizensadvice.org.uk.

It loads a copy of the Citizens Advice network and geographic data into a PostgreSQL database
to allow for fast searching. It also provides a partial implementation of the old Bureau
Details API for our legacy CMS EPiServer, to support the functions which have not yet been
migrated from EPiServer to the Content Platform.

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
LOCAL_OFFICE_SEARCH_DB_HOST=localhost
LOCAL_OFFICE_SEARCH_DB_PORT=5460
LOCAL_OFFICE_SEARCH_DB_USER=local_office_search_api
LOCAL_OFFICE_SEARCH_DB_PASSWORD=develop
LOCAL_OFFICE_SEARCH_DB_NAME=local_office_search_api
LOCAL_OFFICE_SEARCH_EPISERVER_USER=episerver
LOCAL_OFFICE_SEARCH_EPISERVER_PASSWORD=development
LSS_DATA_BUCKET=test-network-data-advice-locations-raw-eu-west-1
EOF
```

Finally, you must now add the following to your hosts file:

```
127.0.0.1	local-office-search-api.test
```

## Starting a local copy

The easiest way to start a local copy of the app is to use Docker. Run
`bin/docker/start` to do this.

You should then be able to visit the app at http://local-office-search-api.test:3060/.

Once you're done, `bin/docker/stop` ends the application!

## Running tests

This repo uses RSpec for testing. To quickly run all the tests:
`bundle exec rake spec`.

Linting is also available, and this is done using Rubocop, following
[Citizens' Advice code style](https://github.com/citizensadvice/citizens-advice-style-ruby).
IDE integration is best for this, alternatively, you can run `bundle exec rubocop`.

You can also run these in Docker if there are any environmental issues
locally using `bin/docker/lint` and `bin/docker/test`.

## Loading data in

You will need to have [AWS set up and be authorised locally](https://github.com/citizensadvice/ca-dev-setup).

If you are logged in as ContentPlatformDeveloper you should now be able to run `bin/docker/rake sync_database`,
or `bin/rake sync_database` to load data in from the data science buckets.

## API documentation

This repo uses [RSwag](https://github.com/rswag/rswag) to produce Swagger API
documentation from tests which have been written against an endpoint.

In order to edit the API documentation, you should write appropriate tests in
`spec/requests/` folder, and once they are green, run `bin/rails rswag` to
update the documentation files.

# 6. Use simple matching for office search

Date: 2023-08-17

## Status

Accepted

## Context

User research has discovered that users who search for a local Citizens Advice do so because they want
to find one which can help them. As such, postcode search is preferred as postcode search will only
show local offices in the same local authority as the entered postcode, and therefore which ones can help
you.

Existing usage data shows 80% of current users search using postcodes, the remaining 20% use place names.
Of that 20%, a further 80% of the freetext search strings that were used will match against the name of
a local office.

Integration of a full geolocation API and design impact of that is only necessary to deal with the long 
tail of searches. A design hypothesis is that users will try again with a different term or use a
postcode, which suggests that the work required to integrate this will deliver a low return for the
initial and ongoing maintenance effort of such a third-party integration.

## Decision

Place name search will be a simple text-matching search against office names and local authority names.

Search results will only show the information necessary to allow a user to select the local
office that is the best way in for them, rather than return full office objects.

## Consequences

The search results API is heavily tied to the front-end behaviour of Find Your Local Citizens Advice,
and it has not been engineered to be a more general API - but this decision may be revisited later if
concrete further use cases are identified.

The search results API will also behave differently than the Local Service Search API when entering a
place name, as it uses a naive algorithm for search.

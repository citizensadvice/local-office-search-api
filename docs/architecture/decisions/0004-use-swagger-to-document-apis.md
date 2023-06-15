# 4. Use Swagger to document APIs

Date: 2023-06-12

## Status

Accepted

## Context

Citizens Advice technical requirements include a requirement that APIs must
be self-documenting.[1](https://github.com/citizensadvice/technical-requirements/blob/master/docs/service_design/apis.md#apis)

However, there is not a standard approach currently across the technical
estate. content-api had previously used Swagger to document their APIs. This
is now replaced with documentation in Markdown after the previous Gem being
used was incompatible with a Rails upgrade.[2](https://github.com/citizensadvice/content-api/pull/955)

The Gem previously being used by content-api was a fork of another Gem (RSwag),
due to the lack of OpenAPI support in the upstream. The upstream now
natively supports OpenAPI.

## Decision

Local Office Search API will use the [RSwag Gem](https://github.com/rswag/rswag)
to allow the API to publish its own documentation following the OpenAPI
standards with a compatible API.

## Consequences

This sets a soft precedent for future Citizens Advice projects over the use
of RSwag and OpenAPI as a documentation format.

Tests for endpoints are to be written using rswag-specs to allow API
documentation to be automatically generated.

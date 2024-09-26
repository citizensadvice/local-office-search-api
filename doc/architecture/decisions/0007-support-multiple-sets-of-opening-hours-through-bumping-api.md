# 7. Support multiple sets of opening hours through bumping API

Date: 2023-11-20

## Status

Accepted

## Context

The previous data model assumed that each office would only have one set of opening times per day,
but this is not the case (Leighton Linslade is an example of one that has a lunch break where they
are not open). 

## Decision

The major version of the API will be bumped to v2, and then the v1 API shortly discontinued once
public-website has been updated to use the v2 API, as this would require a breaking change to the
API to turn the field into a list.

## Consequences

This decision makes it easier to update the API interface to support multiple open/close times.

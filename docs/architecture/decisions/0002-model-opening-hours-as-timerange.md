# 2. Model opening hours as timerange

Date: 2023-06-05

## Status

Proposed

## Context

Previous discovery work settled on an approach to the Find Your Local Citizens
Advice rebuild to load data from S3 into a Postgres database managed by Rails[1](https://docs.google.com/document/d/1qeUYvFeTEVVdWHqOpGzUn3l_XwpCKRROKuOxqXTXCTQ/edit#heading=h.6f1fffwlblo0).

The nature of the data to be loaded has various native data types, including
geographical point data and times (that is, clock times without a date).

## Decision

The data will be stored in the database using data types that represent the data.

## Consequences

The PostGIS extension to Postgres will be used to store the geographical information.

Opening hours will be represented as timeranges. Postgres does not have a native
time range type but a recipe for creating one is documented in its manual[2](https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-DEFINING).
Ruby (and subsequently Rails) does also not have a stdlib way of representing times
that are detached from any dates. The tod Gem[3](https://rubygems.org/gems/tod/) ("Time Of Day")
is a third-party library that adds this concept and supports time ranges through
the "Shift" class. This will require a custom type to be made for ActiveRecord.

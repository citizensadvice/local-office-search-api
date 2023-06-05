# 3. Use Salesforce IDs as natural keys

Date: 2023-06-05

## Status

Proposed

## Context

Previous discovery work settled on an approach to the Find Your Local Citizens
Advice rebuild to load data from S3 into a Postgres database managed by Rails[1](https://docs.google.com/document/d/1qeUYvFeTEVVdWHqOpGzUn3l_XwpCKRROKuOxqXTXCTQ/edit#heading=h.6f1fffwlblo0).

Records in Salesforce are identified using a 15 or 18-character string[2](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/field_types.htm#i1435616).
Use of the 15 character version is deprecated in favour of the "type safe" 18-character one.

## Decision

The ID field of models which are imported from Salesforce should use the 18-character
Salesforce ID  as its ID field. This assists in maintaining integrity between systems
and does not  introduce a new ID that a local Citizens Advice office could have.

## Consequences

Rails' automated ID field for relevant models should be overridden to an 18 character char field. 

The downside is that using non-integer ID fields is unusual within Rails and may be
surprising to developers.

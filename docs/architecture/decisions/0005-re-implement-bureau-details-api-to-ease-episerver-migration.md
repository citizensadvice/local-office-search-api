# 5. Re-implement Bureau Details API to ease EPiServer migration

Date: 2023-06-28

## Status

Accepted

## Context

Resource Directory must be decommissioned by 1st September 2023. EPiServer, our legacy CMS, currently
has a dependency on Resource Directory through the Bureau Details web service.[1](https://github.com/citizensadvice/rd-bureau-details-web-service/blob/master/docs/local-citizens-advice-search.png)

There are three areas of EPiServer where this dependency is used: local Citizens Advice search,
volunteering, and template sites used by a small number of members. All 3 areas are due to be 
migrated from EPiServer before EPiServer's decommission.

Find Your Local Citizens Advice has been  identified as the one with the highest return on
investment from a rebuild/redesign, and this is achievable in the window before the decommission deadline.

The volunteering team are investigating procuring a third-party volunteer management system. A significant
rebuild is therefore has a high risk of delivering a poor return on investment.  The work involved to
migrate the template sites off EPiServer is also not achievable at current staffing levels before the
deadline, therefore these need to be left on EPiServer.

## Decision

We will re-implement the parts of the Bureau Details web service that are used by the member templates
and volunteering parts of EPiServer in a like-for-like manner, and EPiServer will use these APIs.

The APIs used by the local office search will not be reimplemented and left as stubs, with that
functionality moved to public-website, and those endpoints routed away from EPiServer.

## Consequences

A "version 0" API will be built in the Local Office Search API which matches the API design of the 
Bureau Details service. This service will only be used by EPiServer. All other users of the Local
Office Search API will integrate against the v1 API.

This reduces the development work needed on EPiServer to remove the dependency on Bureau Details. It
also eliminates the work needed to rebuild a like-for-like volunteering signup form in public-website
until there is organisational direction on the future of volunteering.

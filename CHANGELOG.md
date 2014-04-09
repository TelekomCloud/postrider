# Changelog

## 0.2.0

* feature: query packages with a selected repository
* feature: added repositoryconfiguration menu
* feature: added comparison function to compare local package versions to those of an upstream repo
* improvement: close the repo selection dropdown when one of its items is clicked
* improvement: nicer styling of repository selection dropdown dialog
* improvement: for repository editing use an object copy, which updates the current state after the server confirms at save
* improvement: align top nav bar to container width
* bugfix: show outdated info only if it is defined
* bugfix: when fetching packages, empty the list of all packages at the beginning
* bugfix: pagination requests must correctly propagate query options when iterating
* bugfix: correct the jquery path that is currently installed from bower
* bugfix: fix random bower build failures

## 0.1.1

* improvement: configure the default host (pony-express) to be the current host + '/api'
* improvement: separate unpaginated and paginated queries (better readability)
* bugfix: stop infinite pagination when the response is empty
* bugfix: add sass compilation to grunt serve

## 0.1.0

* feature: query nodes by selected packages
* feature: fetch all data on a specific package when it is selected
* feature: query packages subset depending on the selected nodes
* feature: make package clicks select the package
* feature: make node clicks select the node
* feature: show pack versions when clicking on it
* feature: show packages summary below each node
* feature: updated /package/xyz requests, it should now include the list of nodes where the package is installed
* feature: query information of one node
* improvement: unified paginated fetch method + bugfixes for nodes and packages fetching
* improvement: add pagination to fetching nodes
* improvement: add pagination to fetching packages (i.e. fetch all packages at once)
* improvement: add a package fetching indicator
* improvement: separate results from querying /nodes and /packages into separate lists, to enable queries on subset
* improvement: move loading icon into the header line of a node when it is clicked
* improvement: add rotating loading icon when no content is there yet
* improvement: querying /packages will also fill all package objects with entries
* improvement: persist host configuration via cookie
* improvement: isolated bower modules in their regular form (not minimized) to one minimization block
* improvement: add jQuery and $ to jshint global configuration to disable such warnings
* improvement: call json names via dot-notation instead of ['..']-notation
* improvement: switch js calls to camelCase instead of under_score (jshint)
* improvement: fix double quotes in test according to jshint
* improvement: make default url configurable at runtime (not just initialization time)
* improvement: unified error reporting in restangular fetches
* bugfix: fix infinite pagination of packages
* bugfix: copy gif and png files from styles to the build directory
* bugfix: execute sass build step earlier
* bugfix: execute coffee build step earlier
* bugfix: make sure the  build step compresses all styles with dependencies
* bugfix: make sure all calls to the http backend are finished before verifying their contents
* bugfix: make sure all tests query the nodes list instead of node[xzy]
* bugfix: add missing lodash to js dependencies for restangular


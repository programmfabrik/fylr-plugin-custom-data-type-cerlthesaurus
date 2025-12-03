> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# custom-data-type-cerlthesaurus

This is a plugin for [fylr](https://docs.fylr.io/) with Custom Data Type `CustomDataTypeCERLThesaurus` for references to entities of the [CERL-Thesaurus](<https://data.cerl.org/>).

The Plugins uses <https://ws.gbv.de/suggest/cerl_thesaurus/> for the autocomplete-suggestions and informations about CERL-thesaurus-entities.

## installation

The latest version of this plugin can be found [here](https://github.com/programmfabrik/fylr-plugin-custom-data-type-cerlthesaurus/releases/latest/download/customDataTypeCERLThesaurus.zip).

The ZIP can be downloaded and installed using the plugin manager, or used directly (recommended).

Github has an overview page to get a list of [all releases](https://github.com/programmfabrik/fylr-plugin-custom-data-type-cerlthesaurus/releases/).

## requirements
This plugin requires https://github.com/programmfabrik/fylr-plugin-commons-library. In order to use this Plugin, you need to add the [commons-library-plugin](https://github.com/programmfabrik/fylr-plugin-commons-library) to your pluginmanager.

## configuration

As defined in `manifest.yml` this datatype can be configured:

### Mask options

* allow_placename
* allow_imprintname
* allow_personalname
* allow_corporatename

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptFulltext
    * fulltext-string which contains variantNames etc.
* frontendLanguage
    * the frontendlanguage of the entering user
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## updater
Note: The automatic updater is implemented and can be configured in the baseconfig. You need to enable the "custom-data-type"-update-service globally too.



## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/fylr-plugin-custom-data-type-cerlthesaurus>.

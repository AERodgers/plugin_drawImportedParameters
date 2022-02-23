# plugin_drawImportedParameters Change Log

## 1.2.3
* Fixed bug which failed to catch all undefined time values in CompareUtterances time warping.

## 1.2.2
* Improvements to compareUtterances:
    * User has the option to use formatted/unformatted versions of y-axis names.
* Improvements to compareParameters:
    * Y axis text will automatically be processed to avoid accidental reformatting.

## 1.2.1
* Fixed bugs in CompareUtterances
    * Fixed error where list of utterance display names were not saving.
    * Fixed error where time normalization was returning undefined time values.
    * Fixed error where the number of textgrid intervals could be miscounted.

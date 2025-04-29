# enduro-autosplit
LiveSplit autosplitter for Enduro Racer on emulator

## Supported Emulators

* BizHawk 2.10

This only supports BizHawk at present, though extending to other emulators should be possible and maybe even straightforward.

## Supported Games

* Enduro Racer (SMS U/E/B)
* Enduro Racer (SMS J) - for either 10 or 20 stage speedrunning

## Timing Method

This is designed for IGT timing.  Enduro Racer has some lazy programming around the handling of fractional seconds.  While within a track the timer will count up, and then "flip" to the erroneous second count when splitting after crossing the finish line.  All split times should match what is shown on the end screen.

## Splits

Splitting happens when crossing the finish line.  For the Japanese version of the game, setting up either 10 or 20 splits depending on whether you are racing both loops should work as expected.

The splitter expects to see the transition from title screen into stage 1, so you may need to reset the game after the autosplitter has been loaded.

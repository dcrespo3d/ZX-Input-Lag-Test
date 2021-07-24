# ZX-Input-Lag-Test
An input lag test for ZX Spectrums, real machine or emulated

[Try it online on QAOP emulator. *](http://torinak.com/qaop#l=https://dcrespo3d.github.io/ZX-Input-Lag-Test/DAPR_Input_Lag_Test.tap)

[![ZX-Input-Lag-Test](https://dcrespo3d.github.io/ZX-Input-Lag-Test/screenshot.png)](http://torinak.com/qaop#l=https://dcrespo3d.github.io/ZX-Input-Lag-Test/DAPR_Input_Lag_Test.tap)

This test is intended to measure input lag
on a ZX Spectrum machine, real or emulated
  
When pressing any key, a sound tone is produced,
and a visual cue (border + column tally) is shown.
 
A real spectrum should react almost immediately
(just the clock cycles between keypress detection
and sound and video reaction, which sould be really low;
due to the fact that keypresses are checked in a
high frequency loop, so the input lag for a real machine
should be below 100 us.
 
For an FPGA or an emulator, your mileage may vary.

You may build the test from assembler source (.asm) or use the tape image (.tap) or snapshots (.z80, .sna).

This test will be featured in an oncoming video in my [youtube channel, DavidPrograma](https://www.youtube.com/c/DavidPrograma).

*Note: tested on Firefox, Chrome and Edge. Visuals works on all three browsers, but audio only works in Firefox and Edge, no sound on Chrome. This is due to Chrome's [autoplay policy](https://developer.chrome.com/blog/autoplay/#webaudio) preventing [QAOP emulator](http://torinak.com/qaop/info) from starting its Audio Context without an explicit user intervention (ex: pressing a button).

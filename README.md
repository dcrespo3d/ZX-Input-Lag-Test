# ZX-Input-Lag-Test
An input lag test for ZX Spectrums, real machine or emulated

This file is intended to measure input lag
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


# MC10_1-bit_music
Various 1 bit music source, binaries and snapshots for the 6803 driven Tandy MC10 8-bit computer.

At the time of writing, the only engine ported so far is 'The Music Studio', modified for MC10 by Utz and Simon Jonassen. All credit to both of these gentleman.  Various music tunes taken from the 1-bit music editor tracker 'Beepola' by Chris Cowley ( http://freestuff.grok.co.uk/beepola/ ).  Use DASM assembler to assemble.   "DASM SRC.ASM -f3 -oOUT.BIN"


Tested and works on VMC10 emulator.

Load .BIN binaries:   Util --> Load Binary File -->  All load and Exec at $5000.  Select .BIN file. At prompt type:   'EXEC'

Load .C10 snapshots:   Type 'CLOADM'.   File --> Play Cassette File --> Select .C10 file. At prompt type:   'EXEC'






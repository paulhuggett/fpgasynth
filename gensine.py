#!/usr/bin/env python3
import math

WIDTH = 16 # The number of bits for each stored value.
WAVETABLE_N = 11 # 2^N wavetable entries.

OUT_MAX = 2 ** WIDTH - 1
HALF_OUT = OUT_MAX / 2 # DC offset we apply to the amplitudes

ENTRIES = 2**WAVETABLE_N # The ROM contains 2^WAVETABLE_N values.0

samples = [ round (math.sin(float(w) / ENTRIES * math.tau) * HALF_OUT + HALF_OUT) for w in range(0, ENTRIES) ]
assert (all ([ x >= 0 and x <= OUT_MAX for x in samples ]))
sep = ''
n = 0
for x in samples:
  print ("{0}0x{1:04x}".format(sep, x), end='')
  if n >= math.trunc(80/7-1):
    sep = ',\n'
    n = 0
  else:
    sep = ','
    n += 1 # comma, zero X, four digits.
print ('')
#  sep = ',\n' if col > 80 else
#  assert ()
  #print ("{0:x}".format(round (samp)))

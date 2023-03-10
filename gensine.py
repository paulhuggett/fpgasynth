#!/usr/bin/env python3
import math

MEMFILE = True
HEX_PREFIX = '' if MEMFILE else '0x'
SEPARATOR = ' ' if MEMFILE else ','

WIDTH = 24 # The number of bits for each stored value.
WAVETABLE_N = 11 # 2^N wavetable entries.

OUT_MAX_WIDTH = 80
OUT_VALUE_WIDTH = 1 + len(HEX_PREFIX) + (WIDTH / 4) # separator, 0x, hex characters.

OUT_MAX = 2 ** WIDTH - 1
HALF_OUT = OUT_MAX / 2 # DC offset we apply to the amplitudes

ENTRIES = 2**WAVETABLE_N # The ROM contains 2^WAVETABLE_N values.0

samples = [ round (math.sin(float(w) / ENTRIES * math.tau) * HALF_OUT + HALF_OUT) for w in range(0, ENTRIES) ]
assert (all ([ x >= 0 and x <= OUT_MAX for x in samples ]))
sep = ''
n = 0
for x in samples:
  print ("{0}{1}{2:06x}".format(sep, HEX_PREFIX, x), end='')
  if n >= math.trunc(OUT_MAX_WIDTH/OUT_VALUE_WIDTH-1):
    sep = SEPARATOR + '\n'
    n = 0
  else:
    sep = SEPARATOR
    n += 1 # comma, zero X, four digits.
print ('')


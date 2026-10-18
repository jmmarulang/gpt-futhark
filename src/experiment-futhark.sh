#!/bin/sh
#
# Run the various experiments.
#
# Currently has some stuff specific to the cluster the script was written for.

export CC=gcc
export CFLAGS="-O3 -std=c99 -ffast-math -march=native -mtune=native"
# export CFLAGS="-O3 -ffast-math -march=native -mtune=native"
export UR_L0_ENABLE_SYSMAN_ENV_DEFAULT=0

futhark c -v --server futhark/microgpt.fut

python main.py

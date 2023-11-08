#!/bin/bash
COPYS=16

while ((COPYS<=32))
do
    echo "./run_spec2017.sh --iterations 1 --copies $COPYS --nobuild --action run intrate"
    ./run_spec2017.sh --iterations 1 --copies $COPYS --nobuild --action run 502.gcc_r 505.mcf_r
    ((COPYS *= 2))
done

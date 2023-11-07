#!/bin/bash
COPYS=1

while ((COPYS<=32))
do
    echo "./run_spec2017.sh --iterations 1 --copies $COPYS --nobuild --action run intrate"
    ./run_spec2017.sh --iterations 1 --copies $COPYS --nobuild --action run intrate
    ((COPYS *= 2))
done

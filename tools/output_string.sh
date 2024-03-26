#!/bin/bash

RES="["
for((i=0;i<40;i++))
do
    let pcpu=$i+3
    RES=$RES"$i@[$pcpu],"
done
echo $RES

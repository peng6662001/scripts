#!/bin/bash

kill `ps aux | grep "perf stat -C 81" -m 1| awk '{print $2}'`

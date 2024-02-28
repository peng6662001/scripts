#!/bin/bash

kill `ps aux | grep "perf stat -C 41" -m 1| awk '{print $2}'`

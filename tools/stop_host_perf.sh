#!/bin/bash

kill `ps aux | grep "perf stat -C 1" -m 1| awk '{print $2}'`

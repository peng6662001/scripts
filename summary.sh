#!/bin/bash

python parse_spec2017.py workloads/current/ && cat workloads/current/current.csv | grep instruction && cat workloads/current/summary.txt | grep -iE "cloud-hypervisor|log_dir"

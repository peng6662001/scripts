#!/bin/bash

perf stat -C 1 -e cycles,instructions,stall_backend,stall_frontend,STALL_BACKEND_TLB,STALL_BACKEND_CACHE,STALL_BACKEND_MEM,mem_access,l1d_tlb,l1d_tlb_refill,l2d_tlb,l2d_tlb_refill,dtlb_walk,rd80d,stall_slot_backend,op_spec,op_retired,STALL_BACKEND_RESOURCE -I 1000 -x , -o /temp/host_perf.csv &

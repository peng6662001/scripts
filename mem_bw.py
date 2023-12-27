import csv, sys, os
import re

csv_data = []
perf_data = {}

file_name = sys.argv[1]
duration = int(sys.argv[2])
count = int(sys.argv[3])

if duration < 1:
    duration = 1

csv_file = open(file_name)
reader_obj = csv.reader(csv_file)
csv_data = list(reader_obj)

for row in csv_data:
    if (len(row) <= 1):
        continue
    a = perf_data.get(row[3], {}) # Note, get() returns a value not ref
    a['val'] = a.get('val', 0) + float(row[1])
    perf_data[row[3]] = a # adam: we have to assign it back to dict

pattern_num = r'\d+'
wr_bw_s0 = 0
wr_bw_s1 = 0
rd_bw_s0 = 0
rd_bw_s1 = 0

for k in perf_data.keys():
    num = int(re.findall(pattern_num, k)[0])
    if 'wr_wra_sent' in str(k):
        if num < 16:
            wr_bw_s0 += perf_data[k].get('val')
        else:
            wr_bw_s1 += perf_data[k].get('val')
    if 'rd_rda_sent' in str(k):
        if num < 16:
            rd_bw_s0 += perf_data[k].get('val')
        else:
            rd_bw_s1 += perf_data[k].get('val')

wr_bw_s0 = wr_bw_s0*64/1024/1024/duration
print(f"wr_bw_s0: {wr_bw_s0:.2f} MiBs")
if count == 31:
    wr_bw_s1 = wr_bw_s1*64/1024/1024/duration
    print(f"wr_bw_s1: {wr_bw_s1:.2f} MiBs")
rd_bw_s0 = rd_bw_s0*64/1024/1024/duration
print(f"rd_bw_s0: {rd_bw_s0:.2f} MiBs")
if count == 31:
    rd_bw_s1 = rd_bw_s1*64/1024/1024/duration
    print(f"rd_bw_s1: {rd_bw_s1:.2f} MiBs")


import csv, sys, os
import pandas as pd
#import matplotlib.pyplot as plt
pd.set_option('display.float_format', '{:.2g}'.format)

csv_data = []

full_list = {}

dir = sys.argv[1]


def read_csv(file):
    perf_data = {}

    csv_file = open(file)
    reader_obj = csv.reader(csv_file)
    csv_data = list(reader_obj)
    for row in csv_data:
        if len(row) < 4:
            continue;
        a = perf_data.get(row[0], {})  # Note, get() returns a value not ref
        a['time'] = float(row[0])
        if row[3] == 'cycles' or row[3] == 'cycles:G':
            a['cycles'] = int(row[1])
        elif row[3] == 'instructions' or row[3] == 'instructions:G':
            a['instructions'] = int(row[1])
        elif row[3] == 'STALL_BACKEND_TLB' or row[3] == 'STALL_BACKEND_TLB:G':
            a['stall_be_tlb'] = int(row[1])
        elif row[3] == 'l2d_tlb' or row[3] == 'l2d_tlb:G':
            a['l2d_tlb'] = int(row[1])
        elif row[3] == 'l2d_tlb_refill' or row[3] == 'l2d_tlb_refill:G':
            a['l2d_tlb_refill'] = int(row[1])
        elif row[3] == 'dtlb_walk' or row[3] == 'dtlb_walk:G':
            a['dtlb_walk'] = int(row[1])
        elif row[3] == 'rd80d' or row[3] == 'rd80d:G':
            a['walk_steps'] = int(row[1])
        elif row[3] == 'op_spec' or row[3] == 'op_spec:G':
            a['op_spec'] = int(row[1])
        elif row[3] == 'op_retired' or row[3] == 'op_retired:G':
            a['op_retired'] = int(row[1])
        elif row[3] == 'stall_slot_backend' or row[3] == 'stall_slot_backend:G':
            a['stall_slot_backend'] = int(row[1])
        elif row[3] == 'STALL_BACKEND_CACHE' or row[3] == 'STALL_BACKEND_CACHE:G':
            a['stall_be_cache'] = int(row[1])
        elif row[3] == 'STALL_BACKEND_MEM' or row[3] == 'STALL_BACKEND_MEM:G':
            a['stall_be_mem'] = int(row[1])
        elif row[3] == 'STALL_BACKEND_RESOURCE' or row[3] == 'STALL_BACKEND_RESOURCE:G':
            a['stall_be_resource'] = int(row[1])
        elif row[3] == 'stall_backend' or row[3] == 'stall_backend:G':
            a['stall_backend'] = int(row[1])
        elif row[3] == 'inst_spec' or row[3] == 'inst_spec:G':
            a['inst_spec'] = int(row[1])
        elif row[3] == 'inst_retired' or row[3] == 'inst_retired:G':
            a['inst_retired'] = int(row[1])
        elif row[3] == 'cycles:H':
            a['cycles_H'] = int(row[1])

        perf_data[row[0]] = a  # adam: we have to assign it back to dict
    return perf_data


def cal_diff(line_host, line_vm):
    line = {}
    line['cycles'] = ''
    line['instructions'] = ''
    line['stall_slot_backend'] = ''
    line['op_spec'] = ''
    line['op_retired'] = ''
    line['stall_be'] = ''
    line['stall_be_tlb'] = ''
    line['stall_be_mem'] = ''
    line['stall_be_cache'] = ''
    line['stall_be_resource'] = ''
    line['CPI'] = line_vm['CPI'] - line_host['CPI']
    line['fe_stall/IR'] = line_vm['fe_stall/IR'] - line_host['fe_stall/IR']
    line['be_stall/IR'] = line_vm['be_stall/IR'] - line_host['be_stall/IR']
    if 'stall_slot_backend' in line_host:
        line['retiring/IR'] = line_vm['retiring/IR'] - line_host['retiring/IR']
        line['lost/IR'] = line_vm['lost/IR'] - line_host['lost/IR']
        line['_be_core/IR'] = line_vm['_be_core/IR'] - line_host['_be_core/IR']
        line['_be_memory/IR'] = line_vm['_be_memory/IR'] - line_host['_be_memory/IR']
        line['__be_cache/IR'] = line_vm['__be_cache/IR'] - line_host['__be_cache/IR']
        line['__be_tlb/IR'] = line_vm['__be_tlb/IR'] - line_host['__be_tlb/IR']
        line['be_stall_mem/IR'] = line_vm['be_stall_mem/IR'] - line_host['be_stall_mem/IR']
        line['be_stall_resource/IR'] = line_vm['be_stall_resource/IR'] - line_host['be_stall_resource/IR']
    else:
        line['retiring/IR'] = ''
        line['lost/IR'] = ''
        line['_be_core/IR'] = ''
        line['_be_memory/IR'] = ''
        line['__be_cache/IR'] = ''
        line['__be_tlb/IR'] = ''
        line['be_stall_mem/IR'] = ''
        line['be_stall_resource/IR'] = ''

    if 'inst_spec/IR' in line_host:
        line['inst_spec/IR'] = line_vm['inst_spec/IR'] - line_host['inst_spec/IR']
        line['inst_retired/IR'] = line_vm['inst_retired/IR'] - line_host['inst_retired/IR']
    else:
        line['inst_spec/IR'] = ''
        line['inst_retired/IR'] = ''


    line['cycles_H'] = ''
    line['cycles_H/cycles'] = ''
    return line


def cal_data(full_data):
    cycles_sum = 0.0
    cycles_H_sum = 0.0
    instructions_sum = 0.0
    stall_slot_backend_sum = 0.0
    op_spec_sum = 0.0
    op_retired_sum = 0.0
    stall_be_sum = 0.0
    stall_be_tlb_sum = 0.0
    stall_be_mem_sum = 0.0
    stall_be_cache_sum = 0.0
    stall_be_resource_sum = 0.0
    inst_spec_sum = 0.0
    inst_retired_sum = 0.0

    for k in full_data.keys():
        a = full_data[k]
        if a['cycles'] < 2900000000:
            continue

        cycles_sum += a['cycles']
        if 'cycles_H' in a:
            cycles_H_sum += a['cycles_H']
        instructions_sum += a['instructions']
        if 'stall_slot_backend' in a:
            stall_slot_backend_sum += a['stall_slot_backend']
            op_spec_sum += a['op_spec']
            op_retired_sum += a['op_retired']
            stall_be_tlb_sum += a['stall_be_tlb']
            stall_be_mem_sum += a['stall_be_mem']
            stall_be_cache_sum += a['stall_be_cache']
            stall_be_resource_sum += a['stall_be_resource']

        stall_be_sum += a['stall_backend']

        if 'inst_spec' in a:
            inst_spec_sum += a['inst_spec']
            inst_retired_sum += a['inst_retired']


    # print(ret_file.read(), file=f)

    str_sum = 'cycles_sum,' + str(cycles_sum)
    if cycles_H_sum != 0:
        str_sum += ',cycles_H_sum,' + str(cycles_H_sum)
    str_sum += ',instructions_sum,' + str(instructions_sum) + ',stall_slot_backend_sum,' + str(stall_slot_backend_sum) + \
               ',op_spec_sum,' + str(op_spec_sum) + ',op_retired_sum,' + str(op_retired_sum) + \
               ',stall_be_tlb_sum,' + str(stall_be_tlb_sum) + ',stall_be_mem_sum,' + str(stall_be_mem_sum) + \
               ',stall_be_cache_sum,' + str(stall_be_cache_sum) + ',stall_be_resource_sum,' + str(stall_be_resource_sum) + \
               ',stall_be_sum,' + str(stall_be_sum) + '\n'
    # print(str_sum, file=f)

    line = {}
    line['cycles'] = cycles_sum
    line['instructions'] = instructions_sum
    line['stall_be'] = stall_be_sum

    line['CPI'] = float(cycles_sum) / instructions_sum
    line['be_stall/IR'] = float(stall_be_sum) / 4 / instructions_sum

    if stall_slot_backend_sum == 0:
        line['stall_slot_backend'] = ''
        line['stall_be_tlb'] = ''
        line['stall_be_mem'] = ''
        line['stall_be_cache'] = ''
        line['stall_be_resource'] = ''
        line['op_spec'] = ''
        line['op_retired'] = ''
        line['retiring/IR'] = ''
        line['lost/IR'] = ''
        line['_be_core/IR'] = ''
        line['_be_memory/IR'] = ''
        line['__be_cache/IR'] = ''
        line['__be_tlb/IR'] = ''
        line['be_stall_mem/IR'] = ''
        line['be_stall_resource/IR'] = ''
        line['fe_stall/IR'] = ''
    else:
        line['stall_slot_backend'] = stall_slot_backend_sum
        line['stall_be_tlb'] = stall_be_tlb_sum
        line['stall_be_mem'] = stall_be_mem_sum
        line['stall_be_cache'] = stall_be_cache_sum
        line['stall_be_resource'] = stall_be_resource_sum
        line['op_spec'] = op_spec_sum
        line['op_retired'] = op_retired_sum
        line['retiring/IR'] = float(op_retired_sum) / 4 / instructions_sum
        line['lost/IR'] = float(op_spec_sum - op_retired_sum) / 4 / instructions_sum
        line['_be_core/IR'] = float(stall_be_sum) / 4 / instructions_sum - float(stall_be_cache_sum) / instructions_sum - float(stall_be_tlb_sum) / instructions_sum
        line['_be_memory/IR'] = float(stall_be_cache_sum) / instructions_sum + float(stall_be_tlb_sum) / instructions_sum
        line['__be_cache/IR'] = float(stall_be_cache_sum) / instructions_sum
        line['__be_tlb/IR'] = float(stall_be_tlb_sum) / instructions_sum
        line['be_stall_mem/IR'] = float(stall_be_mem_sum) / instructions_sum
        line['be_stall_resource/IR'] = float(stall_be_resource_sum) / instructions_sum
        line['fe_stall/IR'] = line['CPI'] - float(stall_be_sum) / 4 / instructions_sum - line['retiring/IR'] - line['lost/IR']

    if inst_spec_sum == 0:
        line['inst_spec/IR'] = ''
        line['inst_retired/IR'] = ''
    else:
        line['inst_spec/IR'] = float(stall_be_mem_sum) / instructions_sum
        line['inst_retired/IR'] = float(stall_be_resource_sum) / instructions_sum

    if cycles_H_sum != 0:
        line['cycles_H'] = cycles_H_sum
        line['cycles_H/cycles'] = cycles_H_sum / cycles_sum
    else:
        line['cycles_H'] = ''
        line['cycles_H/cycles'] = ''

    return line


def parse_dir(dir):
    if not os.path.exists(os.path.join(dir, 'host.csv')):
        return

    data_host = read_csv(os.path.join(dir, 'host.csv'))
    res_host = cal_data(data_host)
    full_list['host'] = res_host
    data_qemu = read_csv(os.path.join(dir, 'qemu.csv'))
    res_qemu = cal_data(data_qemu)
    full_list['qemu'] = res_qemu
    data_clh = read_csv(os.path.join(dir, 'clh.csv'))
    res_clh = cal_data(data_clh)
    full_list['clh'] = res_clh
    host_qemu_diff = cal_diff(res_host, res_qemu)
    full_list['Host_Qemu_Diff'] = host_qemu_diff
    host_clh_diff = cal_diff(res_host, res_clh)
    full_list['Host_CLH_Diff'] = host_clh_diff
    return full_list

def parse_all(dir):
    for root, dirs, files in os.walk(dir):
        for path in dirs:
            parse_dir(os.path.join(root,path))

    df = pd.DataFrame(full_list)

    print(df)
    return df

df = parse_all(dir)

#plt.rcParams.update({'figure.subplot.bottom': 0.35})

#fig1, ax1 = plt.subplots()
#df.iloc[:10, :2].plot(kind='bar', ax=ax1)

#fig2, ax2 = plt.subplots()
#df.iloc[11:-2, :2].plot(kind='bar', ax=ax2)
#plt.show()
if df is not None:
    df.to_csv('perf_data.csv', encoding='utf-8')

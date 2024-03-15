#!/bin/python3
import csv, sys, os
import pandas as pd

import parse_perf

full_list = {}
host_all_data = {}
qemu_all_data = {}
clh_all_data = {}
compat_data = True

spec2017_cases = ['500.perlbench_r', '502.gcc_r', '505.mcf_r', '520.omnetpp_r', '523.xalancbmk_r',
                  '525.x264_r', '531.deepsjeng_r', '541.leela_r', '548.exchange2_r', '557.xz_r']


def get_value(df, column ,name):
    if len(df[df['A'].str.contains(name)]) == 0:
        return ""
    value = df[df['A'].str.contains(name)][column].iloc[0]
    return round(float(value),2)


def set_value(res, key, value):
    if key in res:
        res[key] = res[key] + '\n' + value
    else:
        res[key] = value


def read_interation(df, res):
    iter = 1
    testcases = ['500.perlbench_r','502.gcc_r','505.mcf_r','520.omnetpp_r','523.xalancbmk_r',
                 '525.x264_r','531.deepsjeng_r','541.leela_r','548.exchange2_r','557.xz_r']
    copies = 1
    seconds = 0;
    while(True):
        if len(df[df['L'].str.contains('iteration #' + str(iter))]) == 0:
            break
        df_temp = df[df['L'].str.contains('iteration #' + str(iter))]

        for case in testcases:
            set_value(res, case, get_value(df_temp, 'D', case))
            case_df = df_temp[df_temp['A'].str.contains(case)]
            if len(case_df) != 0:
                copies = get_value(case_df, 'B', case)
                seconds = get_value(df_temp, 'C', case)

        iter += 1
    return copies, seconds


def getCaseValue(list_data, title, cases_data):
    global copy_count
    for case in spec2017_cases:
        if cases_data[case] != '':
            if title not in list_data:
                list_data[title] = cases_data.copy()
            list_data[title][case] = cases_data[case]
            # case_key = case[:3] + "_" + copy_count
            # if case_key in cases_data:
            #     list_data[title][case_key] = cases_data[case_key]
            break
    # list_data[title]['Seconds'] = ''
    # list_data[title]['SPECrate2017_int_base'] = ''
    # list_data[title]['copies'] = ''


old_clh_res = {}
old_qemu_res = {}
clh_childs = 0
qemu_childs = 0
value_detail = {}


def sum_res(old_res, res, copy_count, index):
    if len(old_res) == 0:
        old_res = res
    else:
        for case in spec2017_cases:
            if res[case] != "":
                if old_res[case] == "":
                    old_res[case] = 0

                separate = ",\t\t"
                # if case_key in old_res:
                #     if old_res[case_key].endswith("\n"):
                #         old_res[case_key] = old_res[case_key] + str(res[case])
                #     else:
                #         old_res[case_key] = old_res[case_key] + separate + str(res[case])
                #     if (index + 1) % 4 == 0:
                #         old_res[case_key] = old_res[case_key] + "\n"
                # else:
                #     old_res[case_key] = str(old_res[case]) + separate + str(res[case])
                old_res[case] = round(old_res[case] + res[case], 2)

        #old_res['Seconds'] = old_res['Seconds'] + res['Seconds']
        #old_res['SPECrate2017_int_base'] = old_res['SPECrate2017_int_base'] + res['SPECrate2017_int_base']
    return old_res


def compactData(key, res):
    if key == "qemu_32":
        print(key)
    if compat_data:
        if 'clh_' in key:
            getCaseValue(clh_all_data, key, res)
        elif 'qemu_' in key:
            print("qemu compactData:key = " + key + ",res = " + str(res))
            getCaseValue(qemu_all_data, key, res)
        else:
            getCaseValue(host_all_data, key, res)


def record_details(copies, index, stype, res):
    for case in spec2017_cases:
        if res[case] != "":
            group = copies + "_" + str(index)
            if group not in value_detail:
                value_detail[group] = {}
            key = case[:3] + "_" + stype
            if key not in value_detail[group]:
                value_detail[group][key] = res[case]


copy_count = ""
def parse_spec2017_csv(pardir, f):
    global old_clh_res
    global old_qemu_res
    global clh_childs
    global qemu_childs
    global copy_count

    with open(f, encoding='UTF-8') as temp_f:
        # get No of columns in each line
        col_count = [len(l.split(",")) for l in temp_f.readlines()]
    print("Path file:" + str(f))
    column_names = [chr(i + 65) for i in range(max(col_count))]

    datas = pd.read_csv(f, header=None, skip_blank_lines=True, names=column_names)
    df = datas.loc[:, 'A':'L'].iloc[0:100].fillna(' ')
    res = {}
    copies, seconds = read_interation(df, res)
    res['Seconds'] = round(float(seconds),2)
    res['SPECrate2017_int_base'] = get_value(df, 'B', 'SPECrate2017_int_base')
    res['copies'] = copies

    path = os.path.dirname(f)
    base_name = os.path.basename(path)
    pardir_name = os.path.basename(os.path.abspath(os.path.join(path, os.pardir)))
    copy_count = os.path.basename(os.path.abspath(os.path.join(path, os.pardir, os.pardir)))[-2:]

    # key = copy_count + "_" + pardir_name.split(".")[0] + "_" + base_name.split("-")[0]
    key = copy_count + "_" + pardir_name.split(".")[0] + "_" + base_name

    compact_key = "host_" + copy_count

    if 'clh' in pardir_name or 'qemu' in pardir_name:
        if base_name[-7:] == "_single":
            full_list[key] = res
            if "clh" in pardir_name:
                compact_key = "clh_" + copy_count
                record_details(copy_count, 0, "clh", res)
            elif "qemu" in pardir_name:
                compact_key = "qemu_" + copy_count
                record_details(copy_count, 0, "qemu", res)
            compactData(compact_key, res)
        else:
            key = copy_count + "_" + pardir_name.split(".")[0] + "_" + base_name.split("_")[0]
            nCopy = int(copy_count)
            if "clh" in pardir_name:
                record_details(copy_count, clh_childs, "clh", res)
                old_clh_res = sum_res(old_clh_res, res, copy_count, clh_childs)                # Add scores of multi
                clh_childs += 1
                if nCopy == clh_childs:
                    clh_childs = 0
                    compact_key = "clh_" + copy_count
                    compactData(compact_key, old_clh_res)
                    old_clh_res = {}
                else:
                    full_list[key] = old_clh_res

            if "qemu" in pardir_name:
                print("'SPECrate2017_int_base' = " + str(res['SPECrate2017_int_base']))
                record_details(copy_count, qemu_childs, "qemu", res)
                old_qemu_res = sum_res(old_qemu_res, res, copy_count, qemu_childs)                # Add scores of multi
                qemu_childs += 1
                if nCopy == qemu_childs:
                    qemu_childs = 0
                    compact_key = "qemu_" + copy_count
                    compactData(compact_key, old_qemu_res)
                    old_qemu_res = {}
                else:
                    full_list[key] = old_qemu_res
    else:
        record_details(copy_count, 0, "host", res)
        full_list[key] = res
        compactData(compact_key, res)


dir_name = sys.argv[1]
if not os.path.isdir(dir_name):
    print("Please provide a directory")
    exit(0)

files = list()


def dirAll(pathname):                                                           # Get all files in the directory
    if os.path.exists(pathname):
        filelist = os.listdir(pathname)
        for f in filelist:
            f = os.path.join(pathname, f)
            if os.path.isdir(f):
                dirAll(f)
            else:
                dirname = os.path.dirname(f)
                baseName = os.path.basename(f)
                if dirname.endswith(os.sep):
                    files.append(dirname + baseName)
                else:
                    files.append(dirname + os.sep + baseName)


def get_array(list_data):
    arrays = []
    for item in list_data.items():
        arrays.append(item[0])
        arrays.append(item[1])
    return arrays


def save_cases_result(spath):
    cases_result = {}
    host_array = get_array(host_all_data)
    qemu_array = get_array(qemu_all_data)
    clh_array = get_array(clh_all_data)

    n_size = len(host_all_data)
    if n_size == 0:
        n_size = len(qemu_all_data)
        if n_size == 0:
            n_size = len(clh_all_data)
            if n_size == 0:
                return

    for i in range(n_size):
        if len(host_array) > 0:
            cases_result[host_array[i * 2]] = host_array[i * 2 + 1]
        if len(qemu_array) > 0:
            cases_result[qemu_array[i * 2]] = qemu_array[i * 2 + 1]
        if len(clh_array) > 0:
            cases_result[clh_array[i * 2]] = clh_array[i * 2 + 1]

    cases_df = pd.DataFrame(cases_result)
    #cases_df = cases_df[:10]
    #cases_df['sum'] = cases_df.sum(axis=1)
    #cases_df['average'] = cases_df.mean(axis=1)
    cases_df[:10].to_csv(spath + '_compact.csv', encoding='utf-8')


clh_perf = None
qemu_perf = None
host_perf = None


def collect_perf(parent_dir):
    global clh_perf
    global host_perf
    global qemu_perf

    if host_perf is not None:
        full_list['host_' + parent_dir] = host_perf

    if qemu_perf is not None:
        full_list['qemu_' + parent_dir] = qemu_perf

    if clh_perf is not None:
        full_list['clh_' + parent_dir] = clh_perf

    if host_perf is not None and clh_perf is not None:
        host_clh_diff = parse_perf.getDiff(host_perf, clh_perf)
        full_list['H_C_' + parent_dir] = host_clh_diff

    if host_perf is not None and qemu_perf is not None:
        host_qemu_diff = parse_perf.getDiff(host_perf, qemu_perf)
        full_list['H_Q_' + parent_dir] = host_qemu_diff

    host_perf = None
    qemu_perf = None
    clh_perf = None


def file_parse(parent_dir,file_array):
    global clh_perf
    global host_perf
    global qemu_perf
    for case in spec2017_cases:
        for f in file_array:
            path = os.path.abspath(f)
            if case in path:
                if "clh.csv" in path:
                    clh_perf = parse_perf.parse_dir(".", os.path.dirname(path))  # Parse perf log
                elif "qemu.csv" in path:
                    qemu_perf = parse_perf.parse_dir(".", os.path.dirname(path))
                elif "host.csv" in path:
                    host_perf = parse_perf.parse_dir(".", os.path.dirname(path))
                else:
                    parse_spec2017_csv(parent_dir, f)


def resortArray(array):
    file_array = []
    keys = ['host_', 'qemu_', 'clh_']
    for key in keys:
        for file in array:
            if key in file:
                file_array.append(file)
    return file_array


def parse_unit(dir_name):                                                       # Parse a log directory
    files.clear()
    parent_dir = os.path.basename(dir_name)
    dirAll(dir_name)

    for case in spec2017_cases:
        print("Path case " + case + " for " + dir_name[-6:])
        file_arrary = []
        count = 0
        for f in files:
            base_name = os.path.basename(f)
            # if base_name.endswith(".csv") and base_name.startswith("CPU2017"):
            if base_name.endswith(".csv") and case in f:
                file_arrary.append(f)
                count += 1

        if len(file_arrary) != 0:
            sortedFiles = resortArray(file_arrary)
            file_parse(parent_dir, sortedFiles)
            collect_perf(case[0:3]+"_" + parent_dir[-2:])


for temp in os.listdir(dir_name):
    file_path = os.path.join(dir_name, temp)
    print("Path top:" + file_path)
    if os.path.isdir(file_path):
        parse_unit(file_path)
    # else:
    #     perf_list = parse_perf.parse_dir(".", dir_name)  # Parse perf log
    #     if perf_list is not None:
    #         full_list.update(perf_list)

print("Complete")

full_df = pd.DataFrame(full_list)

if dir_name.endswith("/"):
    dir_name = dir_name[:-1]
if dir_name.endswith("\\"):
    dir_name = dir_name[:-1]

base_name = os.path.basename(dir_name)
if base_name.startswith("log_202"):
    spath = os.path.join(dir_name, base_name[4:])
else:
    spath = os.path.join(dir_name, base_name)
print("spath = " + spath)
full_df.round(2).to_csv(spath + '.csv', encoding='utf-8')

detail_df = pd.DataFrame(value_detail)
detail_df.to_csv(spath + "_detail.csv", encoding='utf-8')

if compat_data:
    save_cases_result(spath)

print(full_df)

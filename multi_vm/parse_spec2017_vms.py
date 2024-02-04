#!/bin/python3
import csv, sys, os
import pandas as pd

import parse_perf_vms

full_list = {}
host_all_data = {}
qemu_all_data = {}
clh_all_data = {}
compat_data = False

spec2017_cases = ['500.perlbench_r', '502.gcc_r', '505.mcf_r', '520.omnetpp_r', '523.xalancbmk_r',
                  '525.x264_r', '531.deepsjeng_r', '541.leela_r', '548.exchange2_r', '557.xz_r']

#test_data = {'one_6.6.0-rc6_1': {'500.perlbench_r': '4.668362', '502.gcc_r': '5.099748', '505.mcf_r': '9.127965', '520.omnetpp_r': '4.220373', '523.xalancbmk_r': '6.960487', '525.x264_r': '8.768577', '531.deepsjeng_r': '4.160553', '541.leela_r': '4.655915', '548.exchange2_r': '12.588069', '557.xz_r': '2.939434', 'Seconds': '', 'SPECrate2017_int_base': '', 'copies': ''}, 'one_6.6.0-rc6_2': {'500.perlbench_r': '9.032392', '502.gcc_r': '8.451308', '505.mcf_r': '13.654452', '520.omnetpp_r': '7.31921', '523.xalancbmk_r': '13.821534', '525.x264_r': '17.192006', '531.deepsjeng_r': '8.230088', '541.leela_r': '9.297256', '548.exchange2_r': '25.155246', '557.xz_r': '5.388034', 'Seconds': '', 'SPECrate2017_int_base': '', 'copies': ''}, 'one_6.6.0-rc6_4': {'500.perlbench_r': '17.86614', '502.gcc_r': '16.097644', '505.mcf_r': '26.78334', '520.omnetpp_r': '11.8162', '523.xalancbmk_r': '27.510784', '525.x264_r': '34.2496', '531.deepsjeng_r': '16.368368', '541.leela_r': '18.587368', '548.exchange2_r': '50.335388', '557.xz_r': '9.903152', 'Seconds': '', 'SPECrate2017_int_base': '', 'copies': ''}, 'one_6.6.0-rc6_8': {'500.perlbench_r': '32.883784', '502.gcc_r': '29.959568', '505.mcf_r': '53.131752', '520.omnetpp_r': '20.381888', '523.xalancbmk_r': '54.582488', '525.x264_r': '68.464008', '531.deepsjeng_r': '32.560608', '541.leela_r': '37.135728', '548.exchange2_r': '100.6518', '557.xz_r': '18.090224', 'Seconds': '', 'SPECrate2017_int_base': '', 'copies': ''}, 'one_6.6.0-rc6_16': {'500.perlbench_r': '63.858272', '502.gcc_r': '55.935792', '505.mcf_r': '105.630048', '520.omnetpp_r': '37.332656', '523.xalancbmk_r': '108.147888', '525.x264_r': '136.648432', '531.deepsjeng_r': '62.24584', '541.leela_r': '74.145552', '548.exchange2_r': '201.0256', '557.xz_r': '33.692912', 'Seconds': '', 'SPECrate2017_int_base': '', 'copies': ''}, 'one_6.6.0-rc6_32': {'500.perlbench_r': '120.763136', '502.gcc_r': '104.474752', '505.mcf_r': '208.070592', '520.omnetpp_r': '70.615776', '523.xalancbmk_r': '212.46624', '525.x264_r': '272.752064', '531.deepsjeng_r': '128.0808', '541.leela_r': '148.011072', '548.exchange2_r': '402.435392', '557.xz_r': '63.209376', 'Seconds': '', 'SPECrate2017_int_base': '', 'copies': ''}}


def get_value(df, column ,name):
    if len(df[df['A'].str.contains(name)]) == 0:
        return ''
    value = df[df['A'].str.contains(name)][column].iloc[0]
    return float(value)


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
    for case in spec2017_cases:
        if cases_data[case] != '':
            if title not in list_data:
                list_data[title] = cases_data.copy()
            list_data[title][case] = cases_data[case]
            break
    list_data[title]['Seconds'] = ''
    list_data[title]['SPECrate2017_int_base'] = ''
    list_data[title]['copies'] = ''


def parse_spec2017_csv(pardir, f):
    with open(f, encoding='UTF-8') as temp_f:
        # get No of columns in each line
        col_count = [len(l.split(",")) for l in temp_f.readlines()]
    column_names = [chr(i + 65) for i in range(max(col_count))]

    datas = pd.read_csv(f, header=None, skip_blank_lines=True, names=column_names)
    df = datas.loc[:, 'A':'L'].iloc[0:100].fillna(' ')
    res = {}
    copies, seconds = read_interation(df, res)
    res['Seconds'] = seconds
    res['SPECrate2017_int_base'] = get_value(df, 'B', 'SPECrate2017_int_base')
    #res['SPECrate2017_int_peak'] = get_value(df, 'B', 'SPECrate2017_int_peak')
    res['copies'] = copies

    path = os.path.dirname(f)
    base_name = os.path.basename(path)
    pardir_name = os.path.basename(os.path.abspath(os.path.join(path, os.pardir)))
    copy_count = os.path.basename(os.path.abspath(os.path.join(path, os.pardir, os.pardir)))[-2:]

    key = copy_count + "_" + pardir_name.split(".")[0] + "_" + base_name.split("-")[0] + "_" + base_name[-2:]
    full_list[key] = res

    if compat_data:
        if '_clh_' in base_name:
            getCaseValue(clh_all_data, base_name + "_" + str(copies), res)
        elif '_qemu_' in base_name:
            getCaseValue(qemu_all_data, base_name + "_" + str(copies), res)
        else:
            getCaseValue(host_all_data, base_name, res)


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


def save_cases_result():
    cases_result = {}
    host_array = get_array(host_all_data)
    qemu_array = get_array(qemu_all_data)
    clh_array = get_array(clh_all_data)

    for i in range(len(host_all_data)):
        cases_result[host_array[i * 2]] = host_array[i * 2 + 1]
        if len(qemu_array) > 0:
            cases_result[qemu_array[i * 2]] = qemu_array[i * 2 + 1]
        if len(clh_array) > 0:
            cases_result[clh_array[i * 2]] = clh_array[i * 2 + 1]

    cases_df = pd.DataFrame(cases_result)
    cases_df = cases_df[:10]
    cases_df['sum'] = cases_df.sum(axis=1)
    cases_df['average'] = cases_df.mean(axis=1)
    cases_df.to_csv('full_cases_data.csv', encoding='utf-8')


clh_perf = None
host_perf = None


def file_parse(parent_dir,file_array):
    global clh_perf
    global host_perf
    for case in spec2017_cases:
        for f in file_array:
            path = os.path.abspath(f)
            if case in path:
                if "clh.csv" in path:
                    clh_perf = parse_perf_vms.parse_dir(".", os.path.dirname(path))  # Parse perf log
                elif "host.csv" in path:
                    host_perf = parse_perf_vms.parse_dir(".", os.path.dirname(path))
                    diff_perf = parse_perf_vms.getDiff(host_perf, clh_perf)
                    full_list['host_' + parent_dir] = host_perf
                    full_list['clh_' + parent_dir] = clh_perf
                    full_list['diff' + parent_dir] = diff_perf
                else:
                    parse_spec2017_csv(parent_dir[-15:], f)


def parse_unit(dir_name):                                                       # Parse a log directory
    files.clear()
    dirAll(dir_name)
    parent_dir = os.path.basename(dir_name)

    file_arrary = []
    count = 0
    for f in files:
        base_name = os.path.basename(f)
        # if base_name.endswith(".csv") and base_name.startswith("CPU2017"):
        if base_name.endswith(".csv"):
            file_arrary.append(f)
            count += 1

    if count == 3:
        tmp = file_arrary[1]
        file_arrary[1] = file_arrary[2]
        file_arrary[2] = tmp

    file_parse(parent_dir, file_arrary)


for temp in os.listdir(dir_name):
    file_path = os.path.join(dir_name, temp)
    if os.path.isdir(file_path):
        parse_unit(file_path)
    # else:
    #     perf_list = parse_perf.parse_dir(".", dir_name)  # Parse perf log
    #     if perf_list is not None:
    #         full_list.update(perf_list)

print("Complete")

full_df = pd.DataFrame(full_list)
# full_df['mean'] = full_df.mean(axis=1)
full_df.round(2).to_csv('full_data.csv', encoding='utf-8')

if compat_data:
    save_cases_result()

print(full_df)

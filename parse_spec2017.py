#!/bin/python3
import csv, sys, os
import pandas as pd

import parse_perf

full_list = {}


def get_value(df, column ,name):
    if len(df[df['A'].str.contains(name)]) == 0:
        return ''
    return df[df['A'].str.contains(name)][column].iloc[0]


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


def parse_spec2017_csv(pardir, f):
    with open(f, encoding='UTF-8') as temp_f:
        # get No of columns in each line
        col_count = [len(l.split(",")) for l in temp_f.readlines()]
    column_names = [chr(i + 65) for i in range(max(col_count))]

    datas = pd.read_csv(f, header=None, skip_blank_lines=True, names=column_names)
    df = datas.loc[:, 'A':'L'].iloc[0:100].fillna(' ')
    res = {}
    copies,seconds = read_interation(df, res)
    res['Seconds'] = seconds
    res['SPECrate2017_int_base'] = get_value(df, 'B', 'SPECrate2017_int_base')
    #res['SPECrate2017_int_peak'] = get_value(df, 'B', 'SPECrate2017_int_peak')
    res['copies'] = copies

    path = os.path.dirname(f)
    full_list[os.path.basename(path) + '_' + pardir + '_' + str(copies)] = res


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


def parse_unit(dir_name):                                                       # Parse a log directory
    files.clear()
    dirAll(dir_name)
    parentDir=os.path.basename(dir_name)
    for f in files:
        base_name = os.path.basename(f)
        if base_name.endswith(".csv") and base_name.startswith("CPU2017"):
            parse_spec2017_csv(parentDir[-15:], f)

    perf_list = parse_perf.parse_dir(parentDir[-15:],dir_name)                  # Parse perf log
    if perf_list is not None:
        full_list.update(perf_list)
    print(perf_list)


for temp in os.listdir(dir_name):
    file_path = os.path.join(dir_name,temp)
    if os.path.isdir(file_path):
        parse_unit(file_path)

print("Complete")

full_df = pd.DataFrame(full_list)
full_df.to_csv('full_data.csv', encoding='utf-8')

print(full_df)

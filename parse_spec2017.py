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
    while(True):
        if len(df[df['L'].str.contains('iteration #' + str(iter))]) == 0:
            break
        df_temp = df[df['L'].str.contains('iteration #' + str(iter))]

        for case in testcases:
            set_value(res, case, get_value(df_temp, 'D', case))
            case_df = df_temp[df_temp['A'].str.contains(case)]
            if len(case_df) != 0:
                copies = get_value(case_df, 'B', case)

        iter += 1
    return copies


def parse_spec2017_csv(pardir, f):
    with open(f, encoding='UTF-8') as temp_f:
        # get No of columns in each line
        col_count = [len(l.split(",")) for l in temp_f.readlines()]
    column_names = [chr(i + 65) for i in range(max(col_count))]

    datas = pd.read_csv(f, header=None, skip_blank_lines=True, names=column_names)
    df = datas.loc[:, 'A':'L'].iloc[0:100].fillna(' ')
    res = {}
    res['dir'] = pardir[-15:]
    copies = read_interation(df, res)
    res['SPECrate2017_int_base'] = get_value(df, 'B', 'SPECrate2017_int_base')
    #res['SPECrate2017_int_peak'] = get_value(df, 'B', 'SPECrate2017_int_peak')
    res['copies'] = copies

    path = os.path.dirname(f)
    full_list[os.path.basename(path) + '_' + str(copies)] = res


# def parse_dir(dir):
#     for f in os.walk():
#         name = os.path.basename(f)
#         if name.endswith(".csv") and name.startswith("CPU2017"):
#             parse_spec2017_csv(dir, os.path.join(os.path.abspath(dir), name))


dir_name = sys.argv[1]
if not os.path.isdir(dir_name):
    print("Please provide a directory")
    exit(0)

files = list()


def dirAll(pathname):
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


# dirAll(dir_name)
# for f in files:
#     baseName = os.path.basename(f)
#     if baseName.endswith(".csv") and baseName.startswith("CPU2017"):
#         parse_spec2017_csv(f)


# for dirpath, dirnames, filenames in os.walk(dir_name):
#     for file in filenames:
#         if file.endswith(".csv") and file.startswith("CPU2017"):
#             parse_spec2017_csv(dir, os.path.join(os.path.abspath(dir), file))

def parse_unit(dir_name):
    dirAll(dir_name)
    for f in files:
        base_name = os.path.basename(f)
        if base_name.endswith(".csv") and base_name.startswith("CPU2017"):
            parse_spec2017_csv(os.path.basename(dir_name), f)

    perf_list = parse_perf.parse_dir(dir_name)
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

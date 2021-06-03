import sys
import matplotlib.pyplot as plt
import tkinter
import subprocess
import shlex
import glob
import statistics

from numpy.lib.shape_base import split
from concurrent.futures import ThreadPoolExecutor

def splitlist(v):
    r = tkinter.Tk()
    t = r.splitlist(v)
    r.destroy()

    return t

def splitdict(l):
    dictionary = {}

    for pair in l:
        lis = splitlist(pair)
        dictionary[lis[0]] = lis[1]

    return dictionary

def tcl(command):
    command_line = shlex.split(command)
    output = subprocess.check_output(command_line)
    return output

def braveOpt(dfg, max_area):
    res = tcl('tclsh ./tcl_scripts/eval_plot_helper.tcl {} {}'.format(dfg, max_area))

    marker_found = False
    true_res = []
    for line in res.split("\n"):
        if line == "## EVAL PLOT HELPER ##":
            marker_found = True
            continue

        if marker_found:
            true_res.append(line)

    return true_res


def exec_bench(area, dfg_name):

    results = []
    for i in range(0, 3):
        results.append(braveOpt(dfg_name, area))
        
    result = results[0]

    exec_time = int((int(results[0][0]) + int(results[1][0]) + int(results[2][0]))/3)
    latency = int(result[1])
    latency_min = int(result[2])
    score = int(float(result[3]))

    return (area, exec_time, latency, latency_min, score);


# print(braveOpt(1000))
# result = splitdict(splitlist(braveOpt(1000)[0]))
# print(result)
# print(result["N29"])

for dfg in glob.glob("./data/DFGs/*.dot"):
    pass

area_x = []
exectime_y = []
latency_y = []
score_y = []

dfg_name = "./data/DFGs/jpeg_fdct_islow_dfg__6.dot"

counts = 0
latency_min = 0
for area_constraint in range(10, 20000, 80):
    #print("exec with", area_constraint)
    # results = []
    # for i in range(0, 3):
    #     results.append(braveOpt(dfg_name, area_constraint))
        
    # result = results[0]

    # exec_time = int((int(results[0][0]) + int(results[1][0]) + int(results[2][0]))/3)
    # latency = int(result[1])
    # latency_min = int(result[2])
    # # score = int.from_bytes(result[3])
    # score = int(float(result[3]))


    args = ((area, dfg_name) for area in range(area_constraint, area_constraint + 80, 20))
    # for arg in args:
    #     print("exec with {}".format(arg))

    with ThreadPoolExecutor() as executor:
        exec_results = executor.map(lambda p: exec_bench(*p), args)
        results = [result for result in exec_results]

    stop_it = False
    for res in results:

        latency = res[2]
        latency_min = res[3]

        area_x.append(res[0])
        exectime_y.append(res[1])
        latency_y.append(latency)
        score_y.append(res[4])

        # area_x.append(area_constraint)
        # exectime_y.append(exec_time)
        # latency_y.append(latency)
        # score_y.append(score)

        if latency == latency_min:
            counts += 1

        if counts == 10:
            stop_it = True
            break
        
        perc = 0
        if latency > 0:
            perc = latency_min / float(latency) * 100

        sys.stdout.write('\rExecuting benchmarks using {} threads: {:.2f}% completed ..'.format(len(results), perc))
        sys.stdout.write(' (latency = {}, goal = {}, input area = {}) '.format(latency, latency_min, res[0]))

        if counts > 0:
            sys.stdout.write(' {} of 10 '.format(counts + 1))
        
        sys.stdout.flush()


    if stop_it:
        break

    #print("found", exec_time)

print

# area_x2, exectime_y = zip(*sorted(zip(area_x, exectime_y), reverse=False))
# area_x, latency_y = zip(*sorted(zip(area_x, latency_y), reverse=True))

starting_idx = 0
for lat_idx in range(1, len(latency_y) - 1):
    if latency_y[lat_idx - 1] > 1 and latency_y[lat_idx] > 1 and latency_y[lat_idx + 1] > 1:
        starting_idx = lat_idx
        break

mean = int(statistics.mean(exectime_y[starting_idx:]))

area_x.reverse()
exectime_y.reverse()
latency_y.reverse()
score_y.reverse()


fig, ((axs0, axs1), (axs2, axs3)) = plt.subplots(2, 2)
fig.suptitle(dfg_name)

axs0.grid()
axs0.set_title('Execution Time')
axs0.set_xlabel('Area')
axs0.set_ylabel('Exec Time')

axs0.set_yticks(range(int(min(exectime_y)), int(max(exectime_y)) + 5, 20))
axs0.axhline(int(mean), color='green', linewidth=2.5)
axs0.plot(area_x, exectime_y, linewidth=1.5)

  
axs1.grid()
axs1.set_title('Latency')
axs1.set_xlabel('Area')
axs1.set_ylabel('Latency')
axs1.plot(area_x, latency_y, linewidth=2.5, marker = 'o', markerfacecolor='yellow')
axs1.axhline(latency_min, color='red', linewidth=0.5)
# axs1.plot(area_x, latency_y, color='green', linewidth = 1,
#          marker='o', markerfacecolor='blue', markersize=5)

axs2.grid()
axs2.set_title('Score')
axs2.set_xlabel('Area')
axs2.set_ylabel('Score')
axs2.plot(area_x, score_y, linewidth=1.5)

latency_diff_y_tmp = list(filter(lambda x: x >= 0, ((lat - latency_min) for lat in latency_y)))

axs3.grid()
axs3.set_title('ASAP Distance')
axs3.set_xlabel('|braveOpt - ASAP|')
axs3.set_ylabel('Count')
axs3.hist(latency_diff_y_tmp, bins = 200, color = 'green')

plt.show()
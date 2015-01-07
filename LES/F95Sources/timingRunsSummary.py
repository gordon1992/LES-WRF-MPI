import os
import re
import sys

# Known Limitations:
# 1. Doesn't deal with multiple hosts
# 2. Doesn't deal with multiple MPI Versions on a single host
# 3. Only supports les_main.txt, les_main_ifbf=0.txt, MPI_SharedMemory/*.txt, and MPI_SharedMemoryExpandingArea/*.txt

fileList = []
rootDir = sys.argv[1] # For example, timingRuns/<hostname>
originalRuntime = 0.0
originalIFBF0Runtime = 0.0
mpiRuns = {}
mpiExpandingAreaRuns = {}

for root, subFolders, files in os.walk(rootDir):
    for filename in files:
        if filename.lower().endswith(".txt"):
            fileList.append(os.path.join(root, filename))

for path in fileList:
    runLog = open(path, "r")
    filename = path.split("/")[-1]
    runtime = 0.0
    processCount = 1
    processes = re.findall("\d+", filename)
    for i in processes:
        processCount *= int(i)
    for line in runLog:
        if re.match(" Total time:", line):
            floats = re.search("\d+.\d+", line)
            runtime = max(runtime, float(floats.group()))
    # Found the runtime for the original code
    if path.endswith("les_main.txt"):
        if originalRuntime != 0.0:
            print("Error, two original runs found")
            sys.exit(-1)
        originalRuntime = runtime
    # Found the runtime for the original code but with IFBF=0
    if path.endswith("les_main_ifbf0.txt"):
        if originalIFBF0Runtime != 0.0:
            print("Error, two ifbf=0 runs found")
            sys.exit(-1)
        originalIFBF0Runtime = 0.0
    # Found a runtime for the MPI code where total area is 150x150x90
    if "/MPI_SharedMemory/" in path:
        try:
            mpiRuns[processCount] = min(mpiRuns[processCount], runtime)
        except KeyError:
            mpiRuns[processCount] = runtime
    # Found a runtime for the MPI code where each process has its own 150x150x90 area
    if "/MPI_SharedMemoryExpandingArea/" in path:
        try:
            mpiExpandingAreaRuns[processCount] = min(mpiExpandingAreaRuns[processCount], runtime)
        except KeyError:
            mpiExpandingAreaRuns[processCount] = runtime

if originalRuntime != 0.0:
    print("Original single threaded code, " + str(originalRuntime))

if originalIFBF0Runtime != 0.0:
    print("Original single threaded ifbf=0 code, " + str(originalIFBF0Runtime))

print("\nMPI_SharedMemory Runs")
for key in mpiRuns.keys():
    print(str(key) + ", " + str(mpiRuns[key]))

print("\nMPI_SharedMemoryExpandingArea Runs")
for key in mpiExpandingAreaRuns.keys():
    print(str(key) + ", " + str(mpiExpandingAreaRuns[key]))

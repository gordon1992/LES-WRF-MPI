#!/bin/sh
scons ocl=0 mpi=0
scons ocl=1 mpi=0
scons ocl=0 mpi=1 verbose=1


#!/bin/bash
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin

# unzip the package bundle
chmod 777 unzip
./unzip bundle.zip

# make a directory to install packages locally
mkdir rLibs

# put stream_metab.yaml in ~/.R/stream_metab.yaml
# mkdir ~/.R
# mv stream_metab.yaml ~/.R

# make a directory to store results in
mkdir job

# run the Rscript run_job.R
Rscript $1 $2

# package the output into a single zip file
zip job.zip job


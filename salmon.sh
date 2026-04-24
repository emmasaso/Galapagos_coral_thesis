#!/bin/bash

#################################################################
# Salmon Mapping
# with QuantSeq 3' TagSeq data
#
#################################################################

# script will stop if something breaks:
set -euo pipefail

# logs what time script starts to calculate run time later
start=$(date +%s)

# prints out me where the code is running
echo "Running in: ${HOSTNAME}"

# load conda and activate environment
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate salmon_env

samples_file="samples.txt"

# this if clause notifies me if the samples_test.txt file can't be found:
if [[ ! -f "${samples_file}" ]]; then
    echo "ERROR: ${samples_file} not found"
    exit 1
fi

# where my preprocessed data is stored
inpath="01-HTS_Preproc"
# where my data files should end up
outpath="02-Salmon_alignment"
# make sure sample_file ends with a new line!

while IFS= read -r sample || [[ -n "$sample" ]]; do

    if [[ -z "$sample" ]]; then
    continue
    fi

    infile="${inpath}/${sample}/${sample}.stats_SE.fastq.gz"

    if [[ ! -f "${infile}" ]]; then
        echo "ERROR: No preprocessed FASTQ file found for sample ${sample}"
        continue
    fi

    echo "---------------------------------------------------"
    echo "------- Mapping [${sample}] -------"
    echo "INPUT FILE: ${infile}"

    echo "Completed mapping for ${sample}"


    salmon quant \
        -i /projects/GLPScorals/Pavona/salmon_drapindex_k23 \
        -l A \
        -r "${infile}" \
        -p 8 \
        -o "${outpath}/salmon_${sample}"

log_file="${outpath}/salmon_${sample}/logs/salmon_quant.log"

if [[ -f "${log_file}" ]]; then
    rate=$(grep "Mapping rate" "${log_file}" | awk '{print $NF}')
    echo -e "${sample}\t${rate}" >> mapping_rates.txt
fi


done < "${samples_file}"

end=$(date +%s)
runtime=$((end - start))
echo "Runtime: ${runtime} seconds"

#!/bin/bash

#################################################################
# QuantSeq 3' TagSeq preprocessing pipeline
#
# This script will:
# 1. Run initial stats with hts_Stats
# 2. Screen for PhiX hits with hts_SeqScreener
# 3. Extract UMIs (6bp) with hts_ExtractUMI
# 4. Remove spacer (4bp) with hts_CutTrim
# 5. Trim adapters with hts_AdapterTrimmer
#    Trim PolyA tails with hts_PolyATTrim
#    Trim end of reads with hts_QWindowT$
# 6. Remove remaining N bases with hts_NTrimmer
# 7. Remove reads < 50 bp with hts_LengthFilter
# 8. Run final stats with hts_Stats
#################################################################

# script will stop if something breaks:
set -euo pipefail

# logs what time script starts to calculate run time later
start=$(date +%s)

# prints out me where the code is running
echo "Running in: ${HOSTNAME}"

# load conda and activate environment
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate htstream_env

samples_file="samples.txt"

# this if clause notifies me if the samples_test.txt file can't be found:
if [[ ! -f "${samples_file}" ]]; then
    echo "ERROR: ${samples_file} not found"
    exit 1
fi

# where my raw data is stored
inpath="00-RawData"
# where my data files should end up
outpath="01-HTS_Preproc"

while IFS= read -r sample <&3; do

    if [[ -z "$sample" ]]; then
    continue
    fi

    infile="${inpath}/${sample}.fastq.gz"

    if [[ ! -f "${infile}" ]]; then
        echo "ERROR: No FASTQ file found for sample ${sample}"
        continue
    fi

    mkdir -p "${outpath}/${sample}"

    log_out="${outpath}/${sample}/${sample}.out"
    log_err="${outpath}/${sample}/${sample}.err"

    echo "--------------------------------------------------"
    echo "------- Processing [${sample}] -------"
    echo "INPUT FILE: ${infile}"

{
    hts_Stats \
        -U "${infile}" \
        -L "${outpath}/${sample}/${sample}.json" \
        -N "initial stats" | \
    hts_SeqScreener \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "screen phix" | \
    hts_ExtractUMI \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "extract UMI sequence and palce in header" | \
    hts_CutTrim \
        -a 4 \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "trim first 4 bases" | \
    hts_AdapterTrimmer \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "trim adapters" | \
    hts_PolyATTrim \
        --no-left \
        --skip_polyT \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "remove polyA tails" | \
    hts_QWindowTrim \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "quality trim the ends of reads" | \
    hts_NTrimmer \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "remove any remaining N bases" | \
    hts_LengthFilter \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "remove reads < 50 bp" \
        -n \
        -m 50 | \
    hts_Stats \
        -A "${outpath}/${sample}/${sample}.json" \
        -N "final stats" \
        -f "${outpath}/${sample}/${sample}.stats" \
        -F
	} > "${log_out}" 2> "${log_err}"

	 echo "Completed preprocessing for ${sample}"

done 3< "${samples_file}"

end=$(date +%s)
runtime=$((end - start))
echo "Runtime: ${runtime} seconds"


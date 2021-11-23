#!/usr/bin/env bash
set -euo pipefail

help () {
    echo "$(basename "$0") [-h|i|t|c] SPECIES"
    echo
    echo "Download a FASTA file from UniProt."
    echo
    echo "Uses wget to download the FASTA file using the UniProt API."
    echo
    echo "Positional Arguments"
    echo "  SPECIES    The species to download. One of 'human' or 'yeast'."
    echo
    echo "Options"
    echo "  -h         Print this help message."
    echo "  -i         Include isoforms."
    echo "  -t         Include unreviewed sequences from TrEMBL."
    echo "  -c         Append contaminant sequences."
    echo
    echo "Ouput"
    echo "  The FASTA file from the current release."
}

setParams () {
    isoforms=""
    isolabel="canonical"
    reviewed=" AND reviewed:yes"
    revlabel="sp"
    crap=""
    while getopts ":hitc" option; do
        case "${option}" in
            h)
                help
                exit;;
            i)
                isoforms="&include=yes"
                isolabel="isoforms";;
            t)
                reviewed=""
                revlabel="sp-tr";;
            c)
                crap="_crap"
        esac
    done

    shift $(( OPTIND - 1 ))
    if [ $# -ne 1 ]; then
        help
        exit
    fi

    species=$1
    case $species in
        "human")
            proteome="up000005640";;
        "yeast")
            proteome="UP000002311";;
        \?)
            help
            exit;;
    esac
}

download () {
    url="https://www.uniprot.org/uniprot/?query=(proteome:${proteome}${reviewed})${isoforms}&format=fasta"
    outfile="uniprot_${species}_${revlabel}_${isolabel}_$(date -I)${crap}.fasta"
    wget -O ${outfile} "${url}"
    if [ ! -z "${crap}" ]; then
        cat "$(dirname "$0")/../fasta/crap.fasta" >> ${outfile}
    fi
}

main () {
    setParams $@
    download
    echo ${outfile}
}

main $@

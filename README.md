# How to create a Prosit DLIB

Prosit is a machine learning tool that we use to create predicted spectral
libraries for EncyclopeDIA---a DLIB. This repository contains instructions on
how to do so and helper scripts to make it a bit easier.

## Prerequisites

You'll need to have EncyclopeDIA installed. If you want to run EncyclopeDIA
exactly as I've written the commands, you'll need to make it callable as
`encyclopedia`. The easiest way to do this is to install it from Bioconda:

``` sh
conda install -c bioconda encyclopedia
```

Otherwise you can create a bash `alias` to do it.

You'll also need `wget`.

## Step 1: Download a FASTA file

You first need to download an appropriate FASTA file, which contains the
proteins sequences that will be used to create your DLIB. Primarily, we obtain
these from Uniprot. I've written simple bash script to help download the ones
that we commonly use,
[`scripts/download-fasta.sh`](scripts/download-fasta.sh):

``` sh
download-fasta.sh [-h|i|t|c] SPECIES

Download a FASTA file from UniProt.

Uses wget to download the FASTA file using the UniProt API.

Positional Arguments
  SPECIES    The species to download. One of 'human' or 'yeast'.

Options
  -h         Print this help message.
  -i         Include isoforms.
  -t         Include unreviewed sequences from TrEMBL.
  -c         Append contaminant sequences.

Ouput
  The FASTA file from the current release.
```

Note that we typically do not want to use the `-i` option. This will 
download a file with the following naming scheme:

``` sh
uniprot_{SPECIES}_{sp|sp-tr}_{canonical|isoforms}_{YYYY-MM-DD}{_crap|}.fasta
```

Here, `sp` indicates reviewed sequences from "SwissProt" and `sp-tr` indicates
both revised and unreviewed sequences from "SwissProt" and "TrEMBL". Both 
SwissProt and TrEMBL are subsets of Uniprot. We add `_crap` to the end to 
indicate if the FASTA file also contains contaminant sequences.

We'll use the canonical yeast FASTA with contaminants as an example:

``` sh
FASTA=$(path/to/talus-dlib-utils/scripts/download-fasta.sh -c yeast)
```

## Step 2. Create a input CSV for Prosit

Prosit uses a CSV format to specify peptides for which it should predict
mass spectra. You can create this using a FASTA file with EncyclopeDIA:

``` sh
encyclopedia -convert -fastaToPrositCSV -defaultCharge 2 -i ${FASTA} 
```

This command will result in a new CSV file which will be the name of your FASTA
file, appended with `trypsin.z2_nce33.csv`. These indicate that the predictions
will be made with a default charge (`z`) of 2 and a normalized collision energy
(`nce`) of 33 and using the enzyme `trypsin`.

## Step 3. Upload the CSV to the Prosit web server

Prosit predictions are made using a web server which regrettably does not have
a programmatic API. Thus you have to do some clicking:

1. Navigate to https://www.proteomicsdb.org/prosit/
2. Click the `SPECTRAL LIBRARY` tab.
3. For "How would you like to provide the list of peptides?" choose `CSV` and
   click `Next`.
4. Upload the CSV file we created. Then click `Next`.
5. For the "Intensity prediction model", choose `Prosit_2020_intensity_hcd` and
   click `Next`.
6. For the "Output format" choose `Generic text (Spectronaut compatible). All
   fragments are reported`. Then click `SUBMIT`

Now grab some coffee and wait, because it will be awhile. 

When your download is ready, download it and unzip the archive. For the next
step, I'll assume that this unzipped directory is `./download`.


## Step 4. Create the DLIB from the Prosit output CSV.

We can now use EncyclopeDIA again to create the DLIB:

``` sh
encyclopedia -convert -prositCSVToLibrary \
    -i ./download/myPrositLib.csv \
    -f ${FASTA} \
    -o ${FASTA}.trypsin.z2_nce33.dlib
```

## Step 5. Upload the DLIB to our S3 bucket.

Once you've created a DLIB, upload both the FASTA file and the DLIB to 
the `data-pipeline-metadata-bucket` S3 bucket. Using the AWS command line 
interface, you can do this with:

``` sh
aws s3 cp ${FASTA} s3://data-pipeline-metadata-bucket/${FASTA}
aws s3 cp ${FASTA}.trypsin.z2_nce33.dlib s3://data-pipeline-metadata-bucket/${FASTA}.trypsin.z2_nce33.dlib
```


# GATK4 SNV (SNP/INDEL) germline pipeline

This the variant calling pipeline [WUSTL's][0] [CCDG][1] [group][2] has been using as of February 2020.

This pipeline is based upon [Broad's  gatk-workflows/gatk4-germline-snps-indels repository][3].  We started with the WDL based on [commit 3bee02b5e843a83edc7f7dc25d8c10d3b06043bb][4], and started adjusting things from there.  This WDL was used for an approximately 34,000 sample cohort Joint Genotyping call set.  

# Main Alterations

## Removal of fingerprinting checks

The Broad pipeline had tasks related to fingerprinting.  The fingerprinting tasks appear to be a regression test to check if the GenomicsDB mixed up samples if more than one gvcf batch was used to import data. This was not an issue for us.  To simplify things we removed those tasks.

## Removal of the SplitIntervalList task

We noticed some non-intuitive behavior from the SplitIntervals task.  After discussing with @ldgauthier, and to keep things simple, we ended up deciding to use the 20,000 hand curated interval list (`gs://gcp-public-data--broad-references/hg38/v0/hg38.even.handcurated.20k.intervals`) created by @eitanbanks at the Broad Institute.

## Addition of the CollectGVCFs task

The WUSTL GVCF inputs are in a slightly different format from the other centers.  Most centers make one GVCF per sample; however, due to historical reasons, WUSTL additionally shards its GVCFs by chromosome.  WUSTL GVCFs are partitioned by sample and chromosome and generally have a structure like so:

    sample1.chr1.g.vcf.gz
    sample1.chr2.g.vcf.gz
    ...
    sample1.chrX.g.vcf.gz
    sample1.chrY.g.vcf.gz

    sample2.chr1.g.vcf.gz
    sample2.chr2.g.vcf.gz
    ...
    sample2.chrX.g.vcf.gz
    sample2.chrY.g.vcf.gz
    ...

Given a genomic interval, the CollectGVCFs task will create a sample map file that will identify the correct GVCF files of interest for the subsequent ImportGVCFs task that creates the relevant GenomicsDB for the interval.

## GnarlyGenotyper _(kept in, but not used)_

The GnarlyGenotyper is a new approach to genotyping that's scalable for large cohorts (>25,000 samples). We ended up not using the GnarlyGenotyper, but deferring to the older but slower GenotypeGVCFs task.  The GnarlyGenotyper will require us to re-band/re-block all of our GVCFs as described in the [ReblockGVCF WDL][5].  

Due to time constraints, we decided to persue this approach in the future.  Our initial GVCF generation parameters from HaplotypeCaller are described below.

## Various CPU, Disk &amp; Memory Adjustments

As with each unique call set, we adjusted the task CPU, Disk and Memory parameters as needed.

# GVCF inputs

The GVCF inputs to this pipeline are based on the outputs of the following two GATK (version 3.5) commands:

## HaplotypeCaller

```bash
java -Xmx16g \
     -jar /opt/GenomeAnalysisTK.jar \
     -T HaplotypeCaller \
     -R ${refFasta} \
     -I ${sampleCram} \
     -o "${sampleName}.${chr}.g.vcf.gz" \
     -ERC GVCF \
     --max_alternate_alleles 3 \
     -variant_index_type LINEAR \
     -variant_index_parameter 128000 \
     -L ${chromosome} \
     -contamination ${freemix} \
     --read_filter OverclippedRead
```

### Notes

* The `${freemix}` value was obtained from running [verifyBamID][6] on the respective input sample cram.
* The reference fasta file was [human build 38][7]
* HaplotypeCaller's implicit [default banding][8] of `[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 70, 80, 90, 99]` was used.


## CombineGVCFs

When uploading a GVCF from our local compute cluster to the cloud we run the following GATK 3.5 command on the GVCF, and upload its resulting output:

```bash
java -Xmx3500M \
     -Xms3500M \
     -jar /opt/GenomeAnalysisTK-3.5-0-g36282e4.jar \
     -T CombineGVCFs \
     -R {refFasta} \
     --breakBandsAtMultiplesOf 1000000 \
     -V local.${sampleName}.${chromosome}.g.vcf.gz \
     -o ${sampleName}.${chromosome}.g.vcf.gz
```

### Notes

* The reference fasta file was [human build 38][7]
* reference bands will be broken up at genomic positions that are multiples of 1000000

[0]: https://www.wustl.edu
[1]: https://www.genome.gov/Funded-Programs-Projects/NHGRI-Genome-Sequencing-Program/Centers-for-Common-Disease-Genomics
[2]: https://github.com/hall-lab
[3]: https://github.com/gatk-workflows/gatk4-germline-snps-indels
[4]: https://github.com/gatk-workflows/gatk4-germline-snps-indels/tree/3bee02b5e843a83edc7f7dc25d8c10d3b06043bb
[5]: https://github.com/indraniel/gatk4-germline-snv-pipeline/blob/master/ReblockGVCF.wdl
[6]: https://github.com/statgen/verifyBamID
[7]: https://www.ncbi.nlm.nih.gov/assembly/GCF_000001405.26/
[8]: https://github.com/broadinstitute/gatk-docs/blob/master/gatk3-tooldocs/3.6-0/org_broadinstitute_gatk_tools_walkers_haplotypecaller_HaplotypeCaller.json#L584

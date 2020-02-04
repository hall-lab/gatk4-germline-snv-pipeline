workflow ReblockGVCF {

  File gvcf
  
  Int small_disk
  Int medium_disk
  Int huge_disk

  String sub_strip_path = "gs://.*/"
  String sub_strip_gvcf = ".g.vcf.gz" + "$"
  String sub_sub = sub(sub(gvcf, sub_strip_path, ""), sub_strip_gvcf, "")

  call Reblock {
      input:
        gvcf = gvcf,
        gvcf_index = gvcf + ".tbi",
        output_vcf_filename = sub_sub + ".vcf.gz",
        disk_size = medium_disk
    }
  output {
    Reblock.output_vcf
    Reblock.output_vcf_index
  }
}

task Reblock {
  File gvcf
  File gvcf_index
  String output_vcf_filename

  Int disk_size

  command <<<

  gatk --java-options "-Xms3g -Xmx3g" \
     ReblockGVCF \
     -V ${gvcf} \
     -drop-low-quals \
     -do-qual-approx \
      --floor-blocks -GQB 10 -GQB 20 -GQB 30 -GQB 40 -GQB 50 -GQB 60 \
     -O ${output_vcf_filename}

   >>>
  runtime {
    memory: "3 GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: 3
    docker: "gcr.io/broad-dsde-methods/reblock_gvcf:correctedASCounts"
  }
  output {
    File output_vcf = "${output_vcf_filename}"
    File output_vcf_index = "${output_vcf_filename}.tbi"
  }
} 

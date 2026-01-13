#Set file names
PLR="PGS001921_(portability-PLR_fracture_5y).txt.gz"
LDP="PGS002137_(portability-ldpred2_fracture_5y).txt.gz"

REF_FA="GRCh37.primary_assembly.genome.fa"   # hg19/GRCh37 fasta



./harmonise_pgs_alt_effect_full.py --pgs "$PLR" --ref-fa "$REF_FA" --out PLR.harm.full.tsv.gz --drop-ambiguous
./harmonise_pgs_alt_effect_full.py --pgs "$LDP" --ref-fa "$REF_FA" --out LDP.harm.full.tsv.gz --drop-ambiguous

#2) Merge both into merged.harmonised.long.tsv.gz (with REF/ALT + PGS alleles)

(
  echo -e "varid\tchr\tpos\tref\talt\tA1\tbeta\tmodel"
  zcat PLR.harm.full.tsv.gz | awk 'NR>1{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tPLR"}'
  zcat LDP.harm.full.tsv.gz | awk 'NR>1{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tLDpred2"}'
) | gzip -c > merged.harmonised.long.clean.tsv.gz


zcat  merged.harmonised.long.clean.tsv.gz \
| awk 'BEGIN{FS=OFS="\t"}
  NR==1{print $0,"chr_pos_ref_alt"; next}
  {print $0, $2"-"$3"-"$4"-"$5}
' | gzip -c > merged.harmonised.long.with_id.tsv.gz

zcat merged.harmonised.long.with_id.tsv.gz \
| awk 'BEGIN{FS=OFS="\t"} NR==1{next} {print $2"-"$3"-"$4"-"$5}' \
| sort -u > panel.chr-pos-ref-alt.txt


./run_turkish_bone_fraction.py \
  --weights /home/projectadmin/isky20/01.projects/04.spor/Fitness_genomics/bon_fracture_downloads/merged.harmonised.long.with_id.tsv.gz \
  --tgd /home/projectadmin/isky20/01.projects/04.spor/01.prs/genrisk/bone_fracture_PGP000263.csv \
  --out turkish_bone_panel.tsv.gz \
  --bad mismatches.tsv.gz

====================================================================
singularity exec ~/isky20/02.software/sifs/plink2.sif plink2 \
  --vcf 203357_wgs_22799-gatk-haplotype.final.vcf \
  --snps-only just-acgt \
  --max-alleles 2 \
  --set-all-var-ids @-#-\$r-\$a \
  --make-pgen \
  --out 203357
=========================================================================
MODEL="PLR"   # change this to LDpred2, PLR, etc.

zcat turkish_bone_panel.tsv.gz | \
awk -v MODEL="$MODEL" 'BEGIN{FS=OFS="\t"}
NR==1{
  for(i=1;i<=NF;i++){
    if($i=="variant_id") vid=i;
    if($i=="A1") a1=i;
    if($i=="beta") b=i;
    if($i=="model") m=i;
  }
  print "ID","A1",MODEL;
  next
}
toupper($m)==toupper(MODEL) {print $vid,$a1,$b}' \
> "${MODEL}.score.tsv"

==============================================================================
singularity exec ~/isky20/02.software/sifs/plink2.sif plink2   --pfile 203357 \
--score LDpred2.score.tsv 1 2 3 header-read no-mean-imputation cols=+scoresums list-variants  \
--out 203357_LDpred2_ref
================================================================================
./prs_zscore_from_panel_af.py \
  --panel turkish_bone_panel.tsv.gz \
  --used-vars 203357_LDpred2_ref.sscore.vars \
  --sscore 203357_LDpred2_sum.sscore \
  --model LDpred2 \
  --sumcol LDpred2_SUM

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

IN="merged.harmonised.long.clean.with_id.tsv.gz"
OUTDIR="shards_100k"
STEP=100000

mkdir -p "$OUTDIR"

# 1) Add (chr, shard) key + sort so we write ONE shard at a time
TMP=$(mktemp)
zcat "$IN" \
| awk -v step=$STEP 'BEGIN{FS=OFS="\t"} NR==1{next}
  { chr=$2; pos=$3+0; shard=int((pos-1)/step)+1; print chr,shard,$0 }' \
| LC_ALL=C sort -t$'\t' -k1,1 -k2,2n -k5,5n > "$TMP"

# 2) Write shard files (gz) with header
awk -v out="$OUTDIR" -v step=$STEP 'BEGIN{
  FS=OFS="\t";
  header="varid\tchr\tpos\tref\talt\tA1\tbeta\tmodel\tchr_pos_ref_alt"
}
{
  chr=$1; shard=$2;
  pos=$5+0;                  # because original "pos" is column 5 after adding chr+shard
  start=(shard-1)*step+1; end=shard*step;

  dir=out"/chr"chr;
  if (!(dir in made)) { system("mkdir -p " dir); made[dir]=1 }

  file=sprintf("%s/chr%s_%05d_%d-%d.tsv.gz", dir, chr, shard, start, end);
  cmd="gzip -c > " file;

  if (file!=cur) {
    if (cur!="") close(curcmd);
    cur=file; curcmd=cmd;
    print header | curcmd;
  }

  # print original columns (drop the first 2 added fields)
  print $3,$4,$5,$6,$7,$8,$9,$10,$11 | curcmd;
}
END{ if (cur!="") close(curcmd) }' "$TMP"

rm -f "$TMP"

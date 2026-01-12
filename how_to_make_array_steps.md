1. **Download PGS scoring files** for the trait of interest with different Development Methods (PLR + LDpred2).

2. **Harmonise each model** to one genome build (e.g., GRCh37):

   * keep SNP-only, biallelic-only
   * enforce **ALT = effect allele (A1)**
   * flip beta sign when needed
   * output per model: `varid (chr:pos) , ref , alt , A1 , beta`

3. **Merge models (long format)**:

   * stack rows and add `model` column (PLR / LDpred2) 

4. **Create panel SNP list**:

   * union both models
   * deduplicate by `chr-pos-ref-alt` → `panel.chr-pos-ref-alt.txt`

5. **Bulk query TGD portal** with `panel.chr-pos-ref-alt.txt` using your script:

   * save AF/AC/AN (+ HOM if available)
   * keep status found / not found

6. **QC TGD output**:

   * drop not found
   * drop missing AF/AC/AN
   * drop allele mismatches (PGS vs TGD ref/alt)
   * (optional) drop strand-ambiguous A/T and C/G

7. **Final Turkish panel list**:

   * `panel.PRSxTGD.txt` = SNPs present in both PRS model(s) and TGD

8. **Prepare per-model score files** from the filtered set:

   * PLR: `varid  A1  beta`
   * LDpred2: `varid  A1  beta`

9. **Score Turkish individuals** (from Turkish VCF/PLINK dataset):

   * compute `PRS_PLR`
   * compute `PRS_LDpred2`

10. **Interpret within Turkish reference**:

* compute mean/sd in Turkish group for each model
* z-score and percentile per individual (model-specific)


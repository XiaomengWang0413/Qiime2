#!bin/bash
source activate /home/xxx/miniconda3/envs/qiime2-2023.09

#QIIME2 PR2
#database download
#https://github.com/pr2database/pr2database/releases
#Prep reference database
# First import the database
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path pr2_version_5.0.0_SSU_mothur.fasta\
  --output-path pr2.qza

# Then the taxonomy file
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path pr2_version_5.0.0_SSU_mothur.tax \
  --output-path pr2_tax.qza


# Selectqiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads  v9_extracts.qza \
  --i-reference-taxonomy pr2_tax.qza \
  --o-classifier pr2_v9_classifier.qza V4 region from the PR2 database
# Use appropriate forward and reverse primers
qiime feature-classifier extract-reads \
  --i-sequences pr2.qza \
  --p-f-primer CCCTGCCHTTTGTACACAC  \
  --p-r-primer CCTTCYGCAGGTTCACCTAC \
  --p-trunc-len 150 \
  --o-reads v9_extracts.qza

# Train the classifier
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads  v9_extracts.qza \
  --i-reference-taxonomy pr2_tax.qza \
  --o-classifier PR2-v9-classifier.qza
#full length database
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads  pr2.qza \
  --i-reference-taxonomy pr2_tax.qza \
  --o-classifier PR2-full-classifier.qza

# tip: make sure you version the databases and taxonomy files you're using. These are often updated so you want o keep them current, but also be able to match the appropriate fasta and taxonomy file.
  


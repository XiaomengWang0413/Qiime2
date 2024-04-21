#!bin/bash
#16S analysis
source activate /home/xiaomeng/miniconda3/envs/qiime2-2023.7
# 2.1 Import data
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.txt \
  --input-format PairedEndFastqManifestPhred33V2 \
  --output-path paired-end-demux.qza

# 2.2 cut primer (optional)
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences paired-end-demux.qza \
  --p-front-f GTGYCAGCMGCCGCGGTAA \
  --p-front-r CCGYCAATTYMTTTRAGTTT \
  --verbose \
  --o-trimmed-sequences demux-noprimers.qza

# 2.3 Join paired reads
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs demux-noprimers.qza \
  --o-merged-sequences demux-joined.qza

# 2.4 Quality fitering
# 2.4.1 View the quality of joined reads
qiime demux summarize \
  --i-data demux-joined.qza \
  --o-visualization demux-joined.qzv

# 2.4.2 Quality scores statistic
qiime quality-filter q-score \
  --i-demux demux-joined.qza \
  --o-filtered-sequences demux-joined-filtered.qza \
  --o-filter-stats demux-joined-filter-stats.qza
# View the result
qiime metadata tabulate \
  --m-input-file demux-joined-filter-stats.qza \
  --o-visualization demux-filter-stats.qzv

# 3. Generate big table
# 3.1 Denoise
# Here need to cite 'deblur' software
#length depend on demux-joined.qzv interactive Quality Plot >30
qiime deblur denoise-16S \
  --i-demultiplexed-seqs demux-joined-filtered.qza \
  --p-trim-length 230 \
  --p-sample-stats \
  --o-representative-sequences rep-seqs-deblur.qza \
  --o-table table-deblur.qza \
  --o-stats deblur-stats.qza

# View the result
qiime deblur visualize-stats \
  --i-deblur-stats deblur-stats.qza \
  --o-visualization deblur-stats.qzv

# 3.2 Generate feature (ASV) table
qiime feature-table summarize \
  --i-table table-deblur.qza \
  --o-visualization table-deblur.qzv \
  --m-sample-metadata-file metadata.txt

# 3.3 Generate representative sequences
qiime feature-table tabulate-seqs \
  --i-data rep-seqs-deblur.qza \
  --o-visualization rep-seqs.qzv

# 3.4 Taxonomic assignment using RDP database
qiime feature-classifier classify-sklearn \
  --i-classifier /home/xunying/db/QIIME2/silva-138-99-nb-classifier.qza \
  --i-reads rep-seqs-deblur.qza \
  --o-classification taxonomy.qza

# Remove certain taxa
qiime taxa filter-table \
  --i-table table-deblur.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude "Chloroplast" \
  --o-filtered-table feature-table-filtered.qza

  qiime taxa filter-table \
  --i-table feature-table-filtered.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude "Mitochondria"  \
  --o-filtered-table feature-table-filtered.qza

# 3.5 Combine taxonomy and feature table
qiime feature-table transpose \
  --i-table feature-table-filtered.qza \
  --o-transposed-feature-table transposed-feature-table.qza
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --m-input-file transposed-feature-table.qza \
  --o-visualization taxo-table.qzv 


# 4. Other analysis (optional)
# 4.1 Phylogenetic analysis
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs-deblur.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

# 4.2 Barplot for taxonomy
qiime taxa barplot \
  --i-table feature-table-filtered.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file metadata.txt \
  --o-visualization taxa-bar-plots.qzv


# 4.3 Diversity--抽平选序列最少的
# --p-sampling-depth NUMBER = the minimum reads number of taxo-table.qzv
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table feature-table-filtered.qza \
  --p-sampling-depth 20127 \
  --m-metadata-file metadata.txt \
  --output-dir core-metrics-results

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata.txt \
  --m-metadata-column type \
  --o-visualization core-metrics-results/unweighted-unifrac-type-significance.qzv \
  --p-pairwise


#move rarefied_table.qza from core-metrics-results

qiime taxa barplot \
  --i-table ./core-metrics-results/rarefied_table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file metadata.txt \
  --o-visualization taxa-bar-plots-even.qzv

#此步得到的ASV表格为抽平后的，用于做α多样性。
4.4 Combine taxonomy and feature table
qiime feature-table transpose \
  --i-table core-metrics-results/rarefied_table.qza \
  --o-transposed-feature-table transposed-rarefied-table.qza

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --m-input-file transposed-rarefied-table.qza \
  --o-visualization taxo-table-even.qzv 




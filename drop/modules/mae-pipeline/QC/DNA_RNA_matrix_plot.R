#'---
#' title: DNA-RNA matching matrix
#' author: vyepez
#' wb:
#'  log:
#'   - snakemake: '`sm str(tmp_dir / "MAE" / "{dataset}" / "QC_matrix_plot.Rds")`'
#'  input:
#'    - mat_qc: '`sm cfg.getProcessedResultsDir() + 
#'               "/mae/{dataset}/dna_rna_qc_matrix.Rds"`'
#'  output:
#'    - wBhtml: '`sm config["htmlOutputPath"] + "/MonoallelicExpression/QC/{dataset}.html"`'
#'  type: noindex
#'---

#+echo=F
saveRDS(snakemake, snakemake@log$snakemake)

suppressPackageStartupMessages({
  library(reshape2)
  library(data.table)
  library(ggplot2)
})


#'
#' ## Plot DNA - RNA matching matrix
qc_mat <- readRDS(snakemake@input$mat_qc)
# hist(qc_mat, xlab = '% of overlapping variants from DNA and RNA', main = '')
melt_mat <- as.data.table(reshape2::melt(qc_mat))

#' Logarithmic scale of the y axis provides a better visualization
identityCutoff <- .85

ggplot(melt_mat, aes(value)) + geom_histogram(fill = 'cadetblue4', binwidth = 0.05, center = .025) + 
  theme_bw(base_size = 14) + 
  labs(x = 'Proportion of matching DNA-RNA variants', y = 'DNA-RNA combinations') + 
  scale_y_log10() + annotation_logticks(sides = "l") + 
  expand_limits(x=c(0,1)) +
  geom_vline(xintercept=identityCutoff, linetype='dashed', color = 'firebrick')

#' ## Identify matching samples

#' Number of samples: `r nrow(qc_mat)`
#' 
#' Number of samples that match with another: `r length(qc_mat[qc_mat > identityCutoff])`
#'
#' Median of matching samples value: `r round(median(qc_mat[qc_mat > identityCutoff]), 2)`
#'
#' Median of not matching samples value: `r round(median(qc_mat[qc_mat < identityCutoff]), 2)`
#'

sa <- fread(snakemake@config$sampleAnnotation)[, .(DNA_ID, RNA_ID)]
sa[, ANNOTATED_MATCH := TRUE]
colnames(melt_mat)[1:2] <- c('DNA_ID', 'RNA_ID')

#' ### Samples that were annotated to match but do not 
false_matches <- merge(sa, melt_mat, by = c('DNA_ID', 'RNA_ID'), 
                       sort = FALSE, all.x = TRUE)
DT::datatable(false_matches[value < identityCutoff])

#' ### Samples that were not annotated to match but actually do
false_mismatches <- merge(melt_mat, sa, by = c('DNA_ID', 'RNA_ID'), 
                          sort = FALSE, all.x = TRUE)
DT::datatable(false_mismatches[is.na(ANNOTATED_MATCH) & value > identityCutoff])


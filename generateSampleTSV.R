# .libPaths(c("/extscratch/shahlab/dalai/R/x86_64-pc-linux-gnu-library-centos5/3.2", "/clusterapp/software/linux-x86_64-centos5/R-3.2.3/lib64/R/library")
library(stringr)
options(stringsAsFactors = FALSE)

args <- commandArgs(TRUE)
# args <- unlist(strsplit(c("sample_info.csv experimental_setup.csv tmp"), split = " "))

if (length(args) < 2) {
	cat("Usage: Rscript generateSampleTSV.R <sample.csv> <experiment.csv> <comma-separated-list-of-pipelines, default:museq,destruct,titan,lumpy,strelka>", sep = "\n")
	q()
}

sample <- read.csv(args[1])


experiment <- read.csv(args[2])


OUTPUT <- args[3]
if (is.na(OUTPUT)) {
	OUTPUT <- ""
}

tools <- unlist(strsplit("museq,destruct,titan,lumpy,strelka,hmmcopy", ","))

# if (length(args) == 4) {
# 	tools <- unlist(str_split(args[], ","))
# } else {
# 	tools <- unlist(strsplit("museq,destruct,titan,lumpy,strelka", ","))
# }

# single_experiment <- subset(experiment, nchar(experiment$NORMAL_ID) == 0 | nchar(experiment$TUMOUR_ID) == 0)
single_experiment <- subset(experiment, is.na(experiment$NORMAL_ID) | is.na(experiment$TUMOUR_ID))

if (nrow(single_experiment) > 0) {
	print("Making single experiment sheets")
	if ("museq" %in% tools) {
		museq <- data.frame("#sample_id" = single_experiment$EXPERIMENT_ID,
			tumour = sample$ABSOLUTE_FILE_PATH[match(single_experiment$TUMOUR_ID, sample$SAMPLE_ID)],
			normal = sample$ABSOLUTE_FILE_PATH[match(single_experiment$NORMAL_ID, sample$SAMPLE_ID)],
			manifest = "None",
			tumour_id = single_experiment$TUMOUR_ID,
			normal_id = single_experiment$NORMAL_ID,
			check.names = FALSE)
		museq$tumour_id[museq$tumour_id == ""] <- "None"
		museq$normal_id[museq$normal_id == ""] <- "None"
		cat("Writing single sample MutationSeq samples file to samples_museq.tsv", sep = "\n")
		write.table(museq, file = paste0(OUTPUT, "samples_single_museq.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}

	if ("lumpy" %in% tools) {

		lumpy <- data.frame("#sample_id" = single_experiment$EXPERIMENT_ID,
			tumour_file = sample$ABSOLUTE_FILE_PATH[match(single_experiment$TUMOUR_ID, sample$SAMPLE_ID)],
			normal_file = sample$ABSOLUTE_FILE_PATH[match(single_experiment$NORMAL_ID, sample$SAMPLE_ID)],
			check.names = FALSE)
		if (length(lumpy$normal_file[!is.na(lumpy$normal_file)]) > 0) {
			lumpy$tumour_file[is.na(lumpy$tumour_file)] <- lumpy$normal_file[!is.na(lumpy$normal_file)]
		}
		lumpy$normal_file <- NA
		cat("Writing single sample Lumpy samples file to samples_lumpy.tsv", sep = "\n")
		write.table(lumpy, file = paste0(OUTPUT, "samples_single_lumpy.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}

	if ("hmmcopy" %in% tools) {
		copy <- data.frame("#sample_id" = single_experiment$EXPERIMENT_ID,
			tumour_file = sample$ABSOLUTE_FILE_PATH[match(single_experiment$TUMOUR_ID, sample$SAMPLE_ID)],
			normal_file = sample$ABSOLUTE_FILE_PATH[match(single_experiment$NORMAL_ID, sample$SAMPLE_ID)],
			check.names = FALSE)

		if (length(copy$normal_file[!is.na(copy$normal_file)]) > 0) {
			copy$tumour_file[is.na(copy$tumour_file)] <- copy$normal_file[!is.na(copy$normal_file)]
		}		
		copy$normal_file <- NA
		copy <- copy[, c(1, 2)]
		names(copy)[2] <- "bam"
		cat("Writing single sample hmmcopy samples file to samples_lumpy.tsv", sep = "\n")
		write.table(copy, file = paste0(OUTPUT, "samples_single_hmmcopy.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}

}

paired_experiment <- subset(experiment, !(nchar(experiment$NORMAL_ID) == 0 | nchar(experiment$TUMOUR_ID) == 0))

if (nrow(paired_experiment) > 0) {
	if ("destruct" %in% tools) {
		destruct <- data.frame("#sample_id" = paired_experiment$EXPERIMENT_ID,
			bam_files = paste0("['", sample$ABSOLUTE_FILE_PATH[match(paired_experiment$TUMOUR_ID, sample$SAMPLE_ID)],"','", sample$ABSOLUTE_FILE_PATH[match(paired_experiment$NORMAL_ID, sample$SAMPLE_ID)],"']"),
			lib_ids = paste0("['", paired_experiment$TUMOUR_ID,"','", paired_experiment$NORMAL_ID,"']"),
			control_ids = paste0("['", paired_experiment$NORMAL_ID,"']"), check.names = FALSE)
		cat("Writing Destruct samples file to samples_destruct.tsv", sep = "\n")
		write.table(destruct, file = paste0(OUTPUT, "samples_paired_destruct.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}

	if ("strelka" %in% tools) {
		strelka <- data.frame("#sample_id" = paired_experiment$EXPERIMENT_ID,
			tumour = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$TUMOUR_ID, sample$SAMPLE_ID)],
			normal = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$NORMAL_ID, sample$SAMPLE_ID)],
			tumour_id = paired_experiment$TUMOUR_ID,
			normal_id = paired_experiment$NORMAL_ID,
			check.names = FALSE)
		cat("Writing Strelka samples file to samples_strelka.tsv", sep = "\n")
		write.table(strelka, file = paste0(OUTPUT, "samples_paired_strelka.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}

	if ("titan" %in% tools) {
		titan <- data.frame("#sample_id" = paired_experiment$EXPERIMENT_ID,
			tumour = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$TUMOUR_ID, sample$SAMPLE_ID)],
			normal = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$NORMAL_ID, sample$SAMPLE_ID)],
			tumour_id = paired_experiment$TUMOUR_ID,
			normal_id = paired_experiment$NORMAL_ID,
			check.names = FALSE)
		cat("Writing Titan samples file to samples_titan.tsv", sep = "\n")
		write.table(titan, file = paste0(OUTPUT, "samples_paired_titan.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}

	if ("museq" %in% tools) {
		museq <- data.frame("#sample_id" = paired_experiment$EXPERIMENT_ID,
			tumour = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$TUMOUR_ID, sample$SAMPLE_ID)],
			normal = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$NORMAL_ID, sample$SAMPLE_ID)],
			manifest = "None",
			tumour_id = paired_experiment$TUMOUR_ID,
			normal_id = paired_experiment$NORMAL_ID,
			check.names = FALSE)
		cat("Writing MutationSeq samples file to samples_museq.tsv", sep = "\n")
		write.table(museq, file = paste0(OUTPUT, "samples_paired_museq.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}

	if ("lumpy" %in% tools) {
		lumpy <- data.frame("#sample_id" = paired_experiment$EXPERIMENT_ID,
			tumour_file = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$TUMOUR_ID, sample$SAMPLE_ID)],
			normal_file = sample$ABSOLUTE_FILE_PATH[match(paired_experiment$NORMAL_ID, sample$SAMPLE_ID)],
			check.names = FALSE)
		cat("Writing Lumpy samples file to samples_lumpy.tsv", sep = "\n")
		write.table(lumpy, file = paste0(OUTPUT, "samples_paired_lumpy.tsv"), quote = FALSE, row.names = FALSE, sep = "\t", na = "None")
	}
}
options(stringsAsFactors = FALSE)

args <- commandArgs(TRUE)

input <- read.csv(args[1],comment.char = "#")
wd <- args[2]

# input <- read.csv("FBI-22/pipelines.csv")
# wd <- "/genesis/shahlab/danlai/FBI-22"

user <- "danlai"

samples <- "sample.tsv"

dir.create(wd, recursive = TRUE)

for (i in 1:nrow(input)) {
	setwd(wd)

	row <- input[i,]

	dir.create(row$DIRECTORY)
	setwd(row$DIRECTORY)

	# ssh://git@svn.bcgsc.ca:7999/pp/bwa_alignment_pipeline.git
	# git <- "https://USERNAME@svn.bcgsc.ca/bitbucket/scm/pp/PIPELINE.git"
	git <- "ssh://git@svn.bcgsc.ca:7999/pp/PIPELINE.git"
	git <- sub("USERNAME", user, git)
	git <- sub("PIPELINE", row$PIPELINE, git)

	system(paste("git clone", git))
	setwd(row$PIPELINE)
	file.copy(row$SAMPLE_FILE, samples, overwrite = TRUE)


	output <- paste0(getwd(), "/OUTPUT")
	components <- paste0(getwd(), "/components")
	queue <- ifelse(input$QUEUE[i] == "shahlab.q", "' -q shahlab.q -l h_vmem={mem},mem_free={mem},mem_token={mem} -pe ncpus {num_cpus}'", "' -q all.q -l h_vmem={mem},mem_free={mem},mem_token={mem} -pe ncpus {num_cpus}'")

	kronos <- c("kronos", "run",
		"-w", output,
		"-r", "RUN", 
		"-c", components,
		"-i", samples,
		"-s", row$SETUP_FILE,
		"-y", row$YAML_FILE,
		"-n", 10,
		"-j", 25,
		"-b", "sge",
		"-q", queue
	)

	run <- paste(kronos, collapse = " ")
	cat(run, file = "run.sh", sep = "\n")
}

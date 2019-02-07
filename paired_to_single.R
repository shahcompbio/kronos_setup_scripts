options(stringsAsFactors = FALSE)
a <- read.csv("experimental_setup_paired.csv")

b <- data.frame(EXPERIMENT_ID = a$TUMOUR_ID, TUMOUR_ID = a$TUMOUR_ID, NORMAL_ID = NA)
b2 <- data.frame(EXPERIMENT_ID = a$NORMAL_ID, TUMOUR_ID = a$NORMAL_ID, NORMAL_ID = NA)

output <- rbind(rbind(a, b), b2)
output <- output[!duplicated(output), ]

write.csv(output, file = "experimental_setup.csv", quote = FALSE, row.names = FALSE)

# load libraries with require and quietly
require("dplyr", quietly = TRUE)
require("tidyr", quietly = TRUE)

# Get master directory from arguments
args <- commandArgs(trailingOnly=TRUE)
if (length(args) < 4) {
  stop("Usage: Rscript plot-pca.R <fail_txt> <input> <hapmap> <output_pdf>")
}
# Set variables to arguments
fail <- args[1]
input <- args[2]
hapmap <- args[3]
output <- args[4]
# Read in the data
data <- read.table(input,h=F,skip=1)

data <- data[c(1,2,3)]

# Rename the columns
colnames(data) <- c("ID" ,"PC1", "PC2")
# Seperate the ID into two columns
data <- data %>% separate(ID, into = c("FID", "IID"), sep = "_")

# Read in the population data
pop <- read.table(hapmap,h=F)
# If column 2 of pop matches column 1 of data, then add column 4 of pop to data
data$pop <- pop[match(data$IID, pop[,2]),4]

# Match the population names to the colors
data$pop <- data$pop %>% replace(is.na(.), 0) %>% as.numeric
CEU <- which(data$pop==3)
CHB <- which(data$pop==4)
JPT <- which(data$pop==5)
YRI <- which(data$pop==6)
test <- which(data$pop==0)

# Plot the data
pdf(output)
plot(0,0,pch="",xlim=c(-0.1,0.05),ylim=c(-0.1,0.1),xlab="principal component 1", ylab="principal component 2")
points(data$PC1[JPT],data$PC2[JPT],pch=20,col="PURPLE")
points(data$PC1[CHB],data$PC2[CHB],pch=20,col="PURPLE")
points(data$PC1[YRI],data$PC2[YRI],pch=20,col="GREEN")
points(data$PC1[CEU],data$PC2[CEU],pch=20,col="RED")
par(cex=0.5)
points(data$PC1[test],data$PC2[test],pch="+",col="BLACK")

# Plot the CEU box for outliers
# Outliers are defined as outside of 1 standard deviation from the mean
abline(h=mean(data$PC2[CEU])+3*sd(data$PC2[CEU]),col="gray32",lty=2)
abline(h=mean(data$PC2[CEU])-3*sd(data$PC2[CEU]),col="gray32",lty=2)
abline(v=mean(data$PC1[CEU])+3*sd(data$PC1[CEU]),col="gray32",lty=2)
abline(v=mean(data$PC1[CEU])-3*sd(data$PC1[CEU]),col="gray32",lty=2)

# Check which are outside the CEU box
pc1 <- between(data$PC1[test], mean(data$PC1[CEU])-sd(data$PC1), mean(data$PC1[CEU])+sd(data$PC1))
pc2 <- between(data$PC2[test], mean(data$PC2[CEU])-sd(data$PC2), mean(data$PC2[CEU])+sd(data$PC2))
data$FID <- as.numeric(data$FID)
data$IID <- as.numeric(data$IID)

# Write out the samples that are outside the CEU box
write.table(data[which(!(pc1 & pc2)),c(1,2)], fail, row.names = F, col.names = F, sep = '\t')
dev.off()
q()

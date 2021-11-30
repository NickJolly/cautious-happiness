install.packages('mlbench')
library(mlbench)
data(BreastCancer)
str(BreastCancer)
?BreastCancer

library(ggplot2)
library(ggfortify)

bc <- BreastCancer[complete.cases(BreastCancer),]

str(bc)

bc$Cl.thickness <- as.numeric(levels(bc$Cl.thickness)[bc$Cl.thickness])
bc$Cell.size <- as.numeric(levels(bc$Cell.size))[bc$Cell.size]
bc$Cell.shape <- as.numeric(levels(bc$Cell.shape))[bc$Cell.shape]
bc$Marg.adhesion <- as.numeric(levels(bc$Marg.adhesion))[bc$Marg.adhesion]
bc$Epith.c.size <- as.numeric(levels(bc$Epith.c.size))[bc$Epith.c.size]
bc$Bare.nuclei <- as.numeric(levels(bc$Bare.nuclei))[bc$Bare.nuclei]
bc$Bl.cromatin <- as.numeric(levels(bc$Bl.cromatin))[bc$Bl.cromatin]
bc$Normal.nucleoli <- as.numeric(levels(bc$Normal.nucleoli))[bc$Normal.nucleoli]
bc$Mitoses <- as.numeric(levels(bc$Mitoses))[bc$Mitoses]

bc_pca <- prcomp(bc[2:10], scale=T)
autoplot(bc_pca, colour='Class', data=bc, size=0.5) +
  scale_colour_manual(name='Class', values=c('dodgerblue2','magenta3')) +
  ggtitle('Breast Cancer: Class') +
  theme(plot.title=element_text(face='bold', hjust=0.5))


library(factoextra)
fviz_eig(bc_pca)
fviz_pca_var(bc_pca, col.var = 'Contribution', 
             gradient.cols = c('#009509', '#DFAB12', '#E05032'), repel = TRUE) 

par(bg='white')

fviz_pca_var(bc_pca, col.var = 'contrib', 
             repel = TRUE, xlab='PC1', ylab='PC2',
             legend.title = 'Contribution') +
  scale_colour_gradientn(colors=c(low='purple3', high='red3'),
                         breaks=c(9,13.5),labels=c('Less','More')) +
  theme(plot.title=element_text(face='bold', hjust=0.5))
plot(bc, pch='.')
        
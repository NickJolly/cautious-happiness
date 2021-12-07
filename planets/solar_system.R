setwd('/Users/nickjolly/Documents/cautious-happiness/planets')
planets <- read.csv('planets.csv', row.names=1)

planets$Ring.System. <- factor(planets$Ring.System.)
planets$Global.Magnetic.Field. <- factor(planets$Global.Magnetic.Field.)
moon <- planets[4,]
planets <- planets[-4,]
sun <- 1.3927

library(ggplot2)

planets$Distance.from.Sun..106.km. <- as.numeric(planets$Distance.from.Sun..106.km.)

ggplot(planets, aes(Distance.from.Sun..106.km., 0)) +
  geom_point(size=planets$Diameter..km./(10^6)) +
  geom_point(aes(0,0), size=sun) +
  xlim(-7000, 7000)


planets
planets[-4,]

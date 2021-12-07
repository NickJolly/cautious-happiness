library(faraway)
data(troutegg)
# str(troutegg)

# We would like to model period as a numerical predictor, not a factor
troutegg$period <- as.integer(as.vector(troutegg$period))



# Plot survival rate against period of submersion for each location
troutegg_1234 <- troutegg[troutegg$location != 5, ]
troutegg_5 <- troutegg[troutegg$location == 5, ]

with(troutegg_1234, plot(period, survive/total,
                   main='Observations of Trout Eggs',
                    xlab='Period (weeks)', ylab='Survival Rate',
                    xlim=c(0,13), ylim=c(0,1)))
with(troutegg_5, points(period, survive/total, col='red'))
legend('bottomleft', legend=c('Locations 1 to 4', 'Location 5'), 
       col = c('black', 'red'), pch=c(1,1),
       box.lty=0, inset=0.01)



# Check for interaction
with(troutegg, interaction.plot(period, location, survive/total))


# Model with and without interaction
model_add <- glm(cbind(survive, total-survive) ~ location + period, 
              family=binomial, data=troutegg)
summary(model_add)

model_int <- glm(cbind(survive, total-survive) ~ location * period, 
              family=binomial, data=troutegg)
summary(model_int)

# Check which model is preferred
anova(model_add, model_int, test='Chisq')
# We reject the hypothesis that the additive model is correct

# Test for model relevance
anova(glm(cbind(survive, total-survive) ~ 1, 
          family=binomial, data=troutegg), 
      model_int, 
      test='Chisq')

# Test for relevance of period in presence of location
anova(glm(cbind(survive, total-survive) ~ location, 
                family=binomial, data=troutegg), 
      model_int, 
      test='Chisq')

# Test for relevance of location in presence of period
anova(glm(cbind(survive, total-survive) ~ period, 
          family=binomial, data=troutegg), 
      model_int, 
      test='Chisq')


# Plotting the fit: Model without interaction
b1 <- model_add$coefficients

# Plot points from all 5 locations
with(troutegg_1234, plot(period, survive/total, 
                         main = 'Chance of Survival vs. Period',
                         xlab='Period (weeks)', ylab='Survival Rate',
                         xlim=c(2,13), ylim=c(0,1)))
with(troutegg_5, points(period, survive/total, col='red'))

# Add lines from each of the locations
curve(ilogit(b1[1] + b1[6]*x), add=T, col='forestgreen', lty=1)
curve(ilogit(b1[1] + +b1[2] + b1[6]*x), add=T, col='darkgreen', lty=2)
curve(ilogit(b1[1] + +b1[3] + b1[6]*x), add=T, col='darkolivegreen4', lty=3)
curve(ilogit(b1[1] + +b1[4] + b1[6]*x), add=T, col='chartreuse4', lty=4)
curve(ilogit(b1[1] + b1[5] + b1[6]*x), add=T, col='firebrick')

legend('bottomleft', legend=c('Loc 1', 'Loc 2', 'Loc 3', 'Loc 4', 'Loc 5'), 
       col = c('forestgreen','darkgreen','darkolivegreen4',
               'chartreuse4','firebrick'),
       lty=c(1,2,3,4,1), box.lty=0, inset=0.01, cex=0.8)




# Plotting the fit: Model with interaction
b2 <- model_int$coefficients

# Plot points from all 5 locations
with(troutegg_1234, plot(period, survive/total, 
                         main = 'Chance of Survival vs. Period (with interaction)',
                         xlab='Period (weeks)', ylab='Survival Rate',
                         xlim=c(2,13), ylim=c(0,1)))
with(troutegg_5, points(period, survive/total, col='red'))

# Add lines from each of the locations
curve(ilogit(b2[1] + b2[6]*x), add=T, col='forestgreen', lty=1)
curve(ilogit(b2[1] + +b2[2] + (b2[7]+b2[6])*x), add=T, col='darkgreen', lty=2)
curve(ilogit(b2[1] + +b2[3] + (b2[8]+b2[6])*x), add=T, col='darkolivegreen4', lty=3)
curve(ilogit(b2[1] + +b2[4] + (b2[9]+b2[6])*x), add=T, col='chartreuse4', lty=4)
curve(ilogit(b2[1] + b2[5] + (b2[10]+b2[6])*x), add=T, col='firebrick')

legend('bottomleft', legend=c('Loc 1', 'Loc 2', 'Loc 3', 'Loc 4', 'Loc 5'), 
       col = c('forestgreen','darkgreen','darkolivegreen4',
               'chartreuse4','firebrick'),
       lty=c(1,2,3,4,1), box.lty=0, inset=0.01, cex=0.8)


# Check which model is preferred
anova(model_add, model_int, test='Chisq')
# Reject the null hypothesis that the smaller (additive) model is correct

# We can use the model to predict the chance of survival. For instance:
newval <- data.frame(location=factor(5), period=6)

pr <- predict(model_int, newval, type='link', se.fit=T)
n <- length(troutegg$survive); p <- length(model_int$coefficients)
half_width <- qt(.975, n-p) * pr$se.fit

point_est <- ilogit(pr$fit)
lower <- ilogit(point_est - half_width)
upper <- ilogit(point_est + half_width)
point_est
c(lower, upper)
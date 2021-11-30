library(faraway)
data(ozone)
#str(ozone)
#?ozone

ozone <- ozone[1:9]

plot(ozone, pch='.')

model1 <- lm(O3 ~ . ,data=ozone)
summary(model1)
model2 <- step(model1, scope=~.)
summary(model2)

par(mfrow=c(2,2))
plot(model2)

# Take the log of the response variable
plot(ozone, pch='.')
ozone$O3 <- log(ozone$O3)
names(ozone)[1] <- 'logO3'
plot(ozone, pch='.')

model3 <- lm(logO3 ~ ., data=ozone)
summary(model3)
model4 <- step(model3, trace=F)
summary(model4)

par(mfrow=c(2,2), bg='white')
plot(model4)

anova(model4)


ozone_adjusted <- ozone[-c(327,330,286), ]
model5 <- lm(logO3 ~ ., data=ozone_adjusted)
model6 <- step(model5, trace=F)
summary(model6)
plot(model6)

anova(model6)
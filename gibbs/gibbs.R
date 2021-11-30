install.packages('invgamma')
install.packages('faraway')
library(invgamma)
library(faraway)
data(airpass)


# Define function to run Gibbs Sampler
gibbs_sample <- function (x, y, shape, rate, beta_var, J, m) {
  # Iterates m times and discards the first J
  
  # Find various sample means
  x_bar <- mean(x)
  y_bar <- mean(y)
  x2_bar <- mean(x^2)
  y2_bar <- mean(y^2)
  xy_bar <- mean(x*y)
  n <- length(y)
  
  # Initialise vectors to record each iteration, starting with priors
  beta0_seq <- rep(NA, m+J+1)
  beta1_seq <- rep(NA, m+J+1)
  sigma2_seq <- rep(NA, m+J+1)
  
  beta0_seq[1] <- rnorm(1, mean=0, sd=sqrt(beta_var))
  beta1_seq[1] <- rnorm(1, mean=0, sd=sqrt(beta_var))
  sigma2_seq[1] <- rinvgamma(1, shape=shape, rate=rate)
  
  # Iterate and update parameters
  for (j in 2:(m+J+1)) {
    n_b <- sigma2_seq[j-1]/beta_var
    
    # Beta_0 - posterior
    beta0_mean <- n*(y_bar - beta1_seq[j-1]*x_bar)/(n + n_b)
    beta0_sd <- sqrt(sigma2_seq[j-1] / (n + n_b))
    beta0 <- rnorm(1, mean=beta0_mean, sd=beta0_sd)
    beta0_seq[j] <- beta0
    
    # Beta_1 - posterior
    beta1_mean <- n*(xy_bar - beta0*x_bar)/(n_b + n*x2_bar)
    beta1_sd <- sqrt(sigma2_seq[j-1]/(n_b + n*x2_bar))
    beta1 <- rnorm(1, mean=beta1_mean, sd=beta1_sd)
    beta1_seq[j] <- beta1
    
    # Sigma squared - posterior
    a_prime <- n/2 + a
    b_prime <- b + (n/2)*(y2_bar - 2* beta0*y_bar - 2*beta1*xy_bar 
                          +beta0^2 + 2*beta0*beta1*x_bar + beta1^2*x2_bar)
    sigma2_seq[j] <- rinvgamma(1, shape=a_prime, rate=b_prime)
  }
  
  result <- list(beta0_seq[(J+2):(m+J+1)],
                 beta1_seq[(J+2):(m+J+1)],
                 sigma2_seq[(J+2):(m+J+1)])
  return(result)
}


# Data and initial values
x <- airpass$year
y <- log(airpass$pass)
a <- 2
b <- 1
sigma2_b <- 10


# Set seed and generate sample
set.seed(1990)
sample <- gibbs_sample(x, y, shape=a, rate=b, beta_var=sigma2_b, 
                       m=200000, J=50000)

# Report results
alpha <- unlist(sample[1])
beta <- unlist(sample[2])
sigma2 <- unlist(sample[3])

(alpha_hat <- median(alpha))
(beta_hat <- median(beta))
(sigma2_hat <- median(sigma2))



# Figure 1
par(mfrow=c(1,1), cex=1)
plot(x, exp(y), xlab='Years', ylab='Passengers', cex=0.5, 
     main='Passengers over Time')

# Figure 2
par(mfrow=c(1,3))
hist(alpha, freq=F, col='azure1')
lines(density(alpha), col='red')

hist(beta, freq=F, col='azure1')
lines(density(beta), col='red')

hist(sigma2, freq=F, col='azure1')
lines(density(sigma2), col='red')

# Figure 3
par(mfrow=c(1,1), cex=1)
half.width = qnorm(0.95)*sqrt(sigma2_hat)
plot(x, y, xlab='Years', ylab='log(Passengers)', cex=0.5, 
     main='log(Passengers) over Time: Simple Regression')
curve(alpha_hat + beta_hat*x, add=T, col='red')
curve(alpha_hat + beta_hat*x + half.width, add=T, col='blue', lty='dashed')
curve(alpha_hat + beta_hat*x - half.width, add=T, col='blue', lty='dashed')
legend('bottomright', legend=c('Posterior Median', '95% Probability Interval'),
       col=c('red', 'blue'), lty=c('solid', 'dashed'), box.lty=0, inset=0.01)

# Figure 4
plot(x, exp(y), xlab='Years', ylab='Passengers', cex=0.5,
     main='Passengers over Time: Simple Regression')
curve(exp(alpha_hat + beta_hat*x), add=T, col='red')
curve(exp(alpha_hat + beta_hat*x + half.width), add=T, col='blue', lty='dashed')
curve(exp(alpha_hat + beta_hat*x - half.width), add=T, col='blue', lty='dashed')
legend('bottomright', legend=c('Posterior Median', '95% Probability Interval'),
       col=c('red', 'blue'), lty=c('solid', 'dashed'), box.lty=0, inset=0.01)

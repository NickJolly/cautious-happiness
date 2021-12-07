# Readme

## Simple Regression with Bayesian Estimation

See this work presented at www.njds.com.au/linear <br />

The simple regression model is <br />
<i>y = alpha + beta * x + epsilon</i> <br />
where each epsilon is assumed to be normal with mean zero, and variance sigma squared. 

### Prior distributions:
Alpha and Beta: Normal with mean 0, variance 10. <br />
Sigma squared: Inverse Gamma with shape parameter 2, rate parameter 1. 

### Posterior distributions:
Estimated with a Gibbs sampler, sample size 200,000 after burning in for 50,000 iterations. <br />

### Requires R packages:
invgamma <br />
faraway

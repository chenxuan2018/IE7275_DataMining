# Problem 5.1

# a.
# Here we use the Naive Rule.
# estimated profit = (estimated profit/sale) * (total sale)
#                  = $2128 * 1000
#                  = 2128000

# b.
# One decile.

# c.
# Six deciles.

# d.
# The goal of this case is to find the top spenders, but not to predict the exact number for how much each customer will spend. So lift and decile charts are good enough to reach our purpose, and it's also easy to apply and more efficient.



# Problem 5.2
library(caret)
library(e1071)
propensity <- c(0.03, 0.52, 0.38, 0.82, 0.33, 0.42, 0.55, 0.59, 0.09, 0.21,
                0.43, 0.04, 0.08, 0.13, 0.01, 0.79, 0.42, 0.29, 0.08, 0.02)
actual <- c(0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0)
df <- data.frame(propensity, actual)

# a.
# cutoff = 0.25
confusionMatrix(ifelse(df$propensity > 0.25, 1, 0), df$actual)
# error rates = 40%, sensitivity = 0.5294, specificity = 1.

# cutoff = 0.5
confusionMatrix(ifelse(df$propensity > 0.5, 1, 0), df$actual)
# error rates = 10%, sensitivity = 0.8824, specificity = 1.

# cutoff = 0.75
confusionMatrix(ifelse(df$propensity > 0.75, 1, 0), df$actual)
# error rates = 5%, sensitivity = 1, specificity = 0.6667.

# b.
library(gains)
gain <- gains(df$actual, df$propensity)
barplot(gain$mean.resp / mean(df$actual), names.arg = gain$depth, xlab = "Percentile",
        ylab = "Mean Response", main = "Decile-wise lift chart")



# Problem 7.1
bank.df <- read.csv("UniversalBank.csv")
# Pre-process the data
# Use model.matrix() to create dummy variables for Education.
bank.df$Education <- as.factor(bank.df$Education)
bank.df[,c("Education_1", "Education_2", "Education_3")] <- model.matrix( ~ Education - 1, data = bank.df)
# Select useful variables for future prediction.
bank.df <- bank.df[, c(2,3,4,6,7,15,16,17,9,11,12,13,14,10)]
bank.df[, 14] <- as.factor(bank.df[, 14])
# Partition the data into training and validation sets.
set.seed(101)
train.index <- sample(row.names(bank.df), 0.6*dim(bank.df)[1])
valid.index <- setdiff(row.names(bank.df), train.index)
train.df <- bank.df[train.index, ]
valid.df <- bank.df[valid.index, ]

# a.
# initialize normalized training, validation data, complete data frames to originals
train.norm.df <- train.df
valid.norm.df <- valid.df
bank.norm.df <- bank.df
new.df <- data.frame(Age = 40, Experience = 10, Income = 84, Family = 2, CCAvg = 2, Education_1 = 0, Education_2 = 1, Education_3 = 0, Mortgage = 0, Securities.Account = 0, CD.Account = 0, Online = 1, CreditCard = 1)
new.norm.df <- new.df
# use preProcess() from the caret package to normalize predictors.
norm.values <- preProcess(train.df[, -14], method=c("center", "scale"))
train.norm.df[, -14] <- predict(norm.values, train.df[, -14])
valid.norm.df[, -14] <- predict(norm.values, valid.df[, -14])
bank.norm.df[, -14] <- predict(norm.values, bank.df[, -14])
new.norm.df <- predict(norm.values, new.df)
# use knn() to compute knn.
library(FNN)
nn <- knn(train = train.norm.df[, -14], test = new.norm.df, cl = train.norm.df[, 14], k = 1)
as.data.frame(nn)
row.names(train.df)[attr(nn, "nn.index")]
# So, this customer would be classified as 0, which means not accepting the personal loan offer.

# b.
library(caret)
# initialize a data frame with two columns: k, and accuracy.
accuracy.df <- data.frame(k = seq(1, 20, 1), accuracy = rep(0, 20))
# compute knn for different k on validation.
for(i in 1:20) {
  knn.pred <- knn(train.norm.df[, -14], valid.norm.df[, -14],
                  cl = train.norm.df[, 14], k = i)
  accuracy.df[i, 2] <- confusionMatrix(knn.pred, valid.norm.df[, 14])$overall[1]
}
accuracy.df
plot(accuracy.df, type = "b")
# We want to consider odd numbers for k to avoid ties. A choice of k that balances between overfitting and ignoring the predictor would be k = 5. The value is chosen because it gives the highest accuracy after k = 3 (k = 3 might be overfitting).

# c.
knn5 <- knn(train.norm.df[, -14], valid.norm.df[, -14], cl = train.norm.df[, 14], k = 5)
table(valid.norm.df[,14], knn5)

# d.
nn5 <- knn(train.norm.df[, -14], new.norm.df, cl = train.norm.df[, 14], k = 5)
as.data.frame(nn5)
# The result remains the same as it was in question a. The customer would not accept the personal loan offer.

# e.
# Partition the data into training, validation and test sets.
set.seed(110)
train.index <- sample(row.names(bank.df), 0.5*dim(bank.df)[1])
valid.index <- sample(setdiff(row.names(bank.df), train.index), 0.3*dim(bank.df)[1])
test.index <- setdiff(row.names(bank.df), union(train.index, valid.index))
train.df <- bank.df[train.index, ]
valid.df <- bank.df[valid.index, ]
test.df <- bank.df[test.index, ]
# initialize normalized training, validation data, complete data frames to originals
train.norm.df <- train.df
valid.norm.df <- valid.df
test.norm.df <- test.df
bank.norm.df <- bank.df
# use preProcess() from the caret package to normalize Age, Experience, Income, and Mortgage.
norm.values <- preProcess(train.df[, -14], method=c("center", "scale"))
train.norm.df[, -14] <- predict(norm.values, train.df[, -14])
valid.norm.df[, -14] <- predict(norm.values, valid.df[, -14])
test.norm.df[, -14] <- predict(norm.values, test.df[, -14])
bank.norm.df[, -14] <- predict(norm.values, bank.df[, -14])
# compute knn
knntrain <- knn(train.norm.df[, -14], train.norm.df[, -14], cl = train.norm.df[, 14], k = 5)
table(train.norm.df[,14], knntrain)
# error rate for training set is 3.16%.
knnvalid <- knn(train.norm.df[, -14], valid.norm.df[, -14], cl = train.norm.df[, 14], k = 5)
table(valid.norm.df[,14], knnvalid)
# error rate for validation set is 4.4%.
knntest <- knn(train.norm.df[, -14], test.norm.df[, -14], cl = train.norm.df[, 14], k = 5)
table(test.norm.df[,14], knntest)
# error rate for test set is 4.8%.
# Error rates for validation and test sets are higher than that for training set. And there isn't big difference between validation and test's error rates, which means the model does not overfit or ignore predictors.
# It is normal that the error rate for training set is lower because we used training set itself as new data set's neighbors. As for the small difference between validation and test's error rates, it's becuase we chose the value of k based on the validation error rate, we expect to get a higher error rate on test data, but it remains similar, which means our model is good.



# Problem 7.2
housing.df <- read.csv("BostonHousing.csv")
# Partition the data into training and validation sets.
set.seed(201)
train.index <- sample(row.names(housing.df), 0.6*dim(housing.df)[1])
valid.index <- setdiff(row.names(housing.df), train.index)
train.df <- housing.df[train.index, ]
valid.df <- housing.df[valid.index, ]

# a.
library(FNN)
# initialize normalized training, validation data, complete data frames to originals
train.norm.df <- train.df
valid.norm.df <- valid.df
housing.norm.df <- housing.df
# use preProcess() from the caret package to normalize predictors.
norm.values <- preProcess(train.df[, c(-13,-14)], method=c("center", "scale"))
train.norm.df[, c(-13,-14)] <- predict(norm.values, train.df[, c(-13,-14)])
valid.norm.df[, c(-13,-14)] <- predict(norm.values, valid.df[, c(-13,-14)])
housing.norm.df[, c(-13,-14)] <- predict(norm.values, housing.df[, c(-13,-14)])
RMSE.df <- data.frame(k = seq(1, 20, 1), RMSE = rep(0, 20))
# compute knn for different k on validation.
# Since our response MEDV is numerical but not categorical, we want to use knn.reg() to do the prediction.
for(i in 1:20) {
  knn.pred <- knn.reg(train.norm.df[, c(-13,-14)], valid.norm.df[, c(-13,-14)],
                  y = train.norm.df[, 13], k = i)
  RMSE.df[i, 2] <- sqrt(sum((valid.norm.df[, 13] - as.array(knn.pred$pred))^2)/nrow(as.array(knn.pred$pred)))
}
RMSE.df
plot(RMSE.df, type = "b")
# From the plot, we can see RMSE drops after k = 1, and rises up after k = 3, which means the model might be overfitting at the beginning, and start to ignore predictors after k = 4. So k = 4 would be the best k.

# If we treat the response as categorical variable, we could use class:knn to do the classification.
for(i in 1:20) {
  knn.pred <- class::knn(train.norm.df[, c(-13,-14)], valid.norm.df[, c(-13,-14)],
                         cl = train.norm.df[, 13], k = i)
  RMSE.df[i, 2] <- sqrt(sum((valid.norm.df[, 13] - as.numeric(levels(knn.pred))[knn.pred])^2)/nrow(valid.norm.df))
}
RMSE.df
plot(RMSE.df, type = "b")
# This plot also shows k = 4 would be the best k.

# b.
new.df <- data.frame(CRIM = 0.2, ZN = 0, INDUS = 7, CHAS = 0, NOX = 0.538, RM = 6, AGE = 62, DIS = 4.7, RAD = 4, TAX = 307, PTRATIO = 21, LSTAT = 10)
new.norm.df <- new.df
# use preProcess() from the caret package to normalize predictors.
new.norm.df <- predict(norm.values, new.df)
knnnew <- knn.reg(train = train.norm.df[, c(-13,-14)], test = new.norm.df, y = train.norm.df[, 13], k = 3)
knnnew
# The predicted MEDV is 18.5667.

# c.
knntrain1 <- knn.reg(train.norm.df[, c(-13,-14)], train.norm.df[, c(-13,-14)], y = train.norm.df[, 13], k = 1)
knntrain1 <- as.array(knntrain1$pred)
RMSE <- sqrt(sum((train.norm.df[, 13] - knntrain1)^2)/nrow(knntrain1))
RMSE
# The error of the training set would be zero at k = 1.
knntrain3 <- knn.reg(train.norm.df[, c(-13,-14)], train.norm.df[, c(-13,-14)], y = train.norm.df[, 13], k = 3)
knntrain3 <- as.array(knntrain3$pred)
RMSE <- sqrt(sum((train.norm.df[, 13] - knntrain3)^2)/nrow(knntrain3))
RMSE
# The error of the training set would be 3.1469 at k = 3.

# d.
# The model was chosen which performs best on the validation set. So the validation data error is overly optimistic compared to new data error rate.

# e.
# The disadvantage is that the process of prediction would be time-consuming. Because for each record to be predicted, we need to compute its distances from the entire training set.
# KNN operations for each prediction: compute the distances of the new record from each record in the entire training set, find k numbers of nearest neighbors(smallest distances), take the weighted average response value of all the neighbors as the prediction value.



# Problem 8.1
bank.df <- read.csv("UniversalBank.csv")
# Select useful variables for future prediction.
bank.df <- bank.df[, c(13,14,10)]
bank.df[, 1] <- as.factor(bank.df[, 1])
bank.df[, 2] <- as.factor(bank.df[, 2])
bank.df[, 3] <- as.factor(bank.df[, 3])
# Partition the data into training and validation sets.
set.seed(301)
train.index <- sample(row.names(bank.df), 0.6*dim(bank.df)[1])
valid.index <- setdiff(row.names(bank.df), train.index)
train.df <- bank.df[train.index, ]
valid.df <- bank.df[valid.index, ]

# a.
table(train.df$CreditCard, train.df$Online, train.df$Personal.Loan, dnn = c("CreditCard", "Online", "Personal.Loan"))

# b.
# probability = 52 / (471 + 52) = 0.099

# c.
table(train.df$Personal.Loan, train.df$Online, dnn = c("Personal.Loan", "Online"))
table(train.df$Personal.Loan, train.df$CreditCard, dnn = c("Personal.Loan", "CreditCard"))

# d.

# i.
p1 = 89 / (203 + 89)
p1
# P(CC = 1 ∣ Loan = 1) = 89 / (203 + 89) = 0.305

# ii.
p2 = 177 / (115 + 177)
p2
# P(Online = 1 ∣ Loan = 1) = 177 / (115 + 177) = 0.606

# iii.
p3 = (115 + 177) / 3000
p3
# P(Loan = 1) = (115 + 177) / 3000 = 0.097

# iv.
p4 = 789 / (1919 + 789)
p4
# P(CC = 1 ∣ Loan = 0) = 789 / (1919 + 789) = 0.291

# v.
p5 = 1614 / (1094 + 1614)
p5
# P(Online = 1 ∣ Loan = 0) = 1614 / (1094 + 1614) = 0.596

# vi.
p6 = (1094 + 1614) / 3000
p6
# P(Loan = 0) = (1094 + 1614) / 3000 = 0.903

# e.
p1*p2*p3 / (p1*p2*p3 + p4*p5*p6)
# P(Loan = 1 ∣ CC = 1, Online = 1) = P(Loan = 1)[P(CC = 1 | Loan = 1)P(Online = 1 | Loan = 1)] / {P(Loan = 1)[P(CC = 1 | Loan = 1)P(Online = 1 | Loan = 1)] + P(Loan = 0)[P(CC = 1 | Loan = 0)P(Online = 1 | Loan = 0)]}
#                                  = 0.097[(0.305)(0.606)] / {0.097[(0.305)(0.606)] + 0.903[(0.291)(0.596)]}
#                                  = 0.01792851 / (0.01792851 + 0.156612708)
#                                  = 0.103

# f.
# The value obtained from (b) (pivot table) is a more accurate estimate, because we don't need to make independent assumption. The probability values obtained from naive bayes is not on the same scale as the exact values that we expect, but just a reasonable accurate rank ordering of propensities.

# g.
# Only two entries are needed for complete Bayes computation: P(CC = 1, Online = 1 | Loan = 0), P(CC = 1, Online = 1 | Loan = 1).
library(e1071)
# run naive bayes
bank.nb <- naiveBayes(Personal.Loan ~ ., data = train.df)
bank.nb
## predict probabilities
pred.prob <- predict(bank.nb, newdata = train.df, type = "raw")
## predict class membership
pred.class <- predict(bank.nb, newdata = train.df)
df <- data.frame(actual = train.df$Personal.Loan, predicted = pred.class, pred.prob)
df[train.df$CreditCard == 1 & train.df$Online == 1,]
# The entry that corresponds to P(Loan = 1 ∣ CC = 1, Online = 1) is 0.1029157, which is the same as what we got from (e).



# Problem 8.2
library(readxl)
Accidents <- read_excel("Accidents.xlsx", sheet = "Data", col_names = TRUE)
Accidents$INJURY <- ifelse(Accidents$MAX_SEV_IR == 0, 0, 1)
Accidents$INJURY <- factor(Accidents$INJURY, levels = c(0, 1), labels = c("No", "Yes"))

# a.
table(Accidents$INJURY)
# INJURY = Yes. According to the table, we should predict Yes based on naive rule, because probability of Yes is higher.

# b.
subset <- Accidents[1:12, c(16,19,25)]
subset$TRAF_CON_R <- factor(subset$TRAF_CON_R)
subset$WEATHER_R <- factor(subset$WEATHER_R)
subset$INJURY <- factor(subset$INJURY)

# i.
table(subset$WEATHER_R, subset$TRAF_CON_R, subset$INJURY, dnn = c("WEATHER_R","TRAF_CON_R", "INJURY"))

# ii.
# P(INJURY = Yes | WEATHER_R = 1, TRAF_CON_R = 0) = 2 / (1 + 2) = 0.667
# P(INJURY = Yes | WEATHER_R = 1, TRAF_CON_R = 1) = 0 / (1 + 0) = 0
# P(INJURY = Yes | WEATHER_R = 1, TRAF_CON_R = 2) = 0 / (1 + 0) = 0
# P(INJURY = Yes | WEATHER_R = 2, TRAF_CON_R = 0) = 1 / (5 + 1) = 0.167
# P(INJURY = Yes | WEATHER_R = 2, TRAF_CON_R = 1) = 0 / (1 + 0) = 0
# P(INJURY = Yes | WEATHER_R = 2, TRAF_CON_R = 2) = 0 / (0 + 0) = 0

# iii.
# Because cutoff is 0.5, only given WEATHER_R = 1 and TRAF_CON_R = 0, INJURY would be Yes.
subset$predicted <- ifelse(subset$TRAF_CON_R == 0 & subset$WEATHER_R == 1, "Yes", "No")
subset

# iv.
# P(INJURY = Yes | WEATHER_R = 1, TRAF_CON_R = 1) = (3/12)[(2/3)(0/3)] / {(3/12)[(2/3)(0/3)] + {(9/12)[(3/9)(2/9)]}}
#                                                 = 0

# v.
subset.nb <- naiveBayes(INJURY ~ TRAF_CON_R + WEATHER_R, subset)
subset.nb
## predict probabilities
pred.prob <- predict(subset.nb, newdata = subset, type = "raw")
pred.prob
## predict class membership, cutoff = 0.5
pred.class <- c("Yes", "No", "No", "No", "Yes", "No", "No", "Yes", "No", "No", "No", "No")
df <- data.frame(actual = subset$INJURY, predicted = pred.class, pred.prob)
df
# The resulting classifications are equivalent. The ranking (= ordering) of observations are also equivalent.

# c.
set.seed(401)
train.index <- sample(nrow(Accidents), 0.6*nrow(Accidents))
train.df <- Accidents[train.index, ]
valid.df <- Accidents[-train.index, ]

# i.
# We can include all 23 predictors in the analysis.
# Delete redundant response variable, convert all predictors into categorical variables.
data.df <- Accidents[, -24]
data.df$HOUR_I_R <- factor(data.df$HOUR_I_R)
data.df$ALCHL_I <- factor(data.df$ALCHL_I)
data.df$ALIGN_I <- factor(data.df$ALIGN_I)
data.df$STRATUM_R <- factor(data.df$STRATUM_R)
data.df$WRK_ZONE <- factor(data.df$WRK_ZONE)
data.df$WKDY_I_R <- factor(data.df$WKDY_I_R)
data.df$INT_HWY <- factor(data.df$INT_HWY)
data.df$LGTCON_I_R <- factor(data.df$LGTCON_I_R)
data.df$MANCOL_I_R <- factor(data.df$MANCOL_I_R)
data.df$PED_ACC_R <- factor(data.df$PED_ACC_R)
data.df$RELJCT_I_R <- factor(data.df$RELJCT_I_R)
data.df$REL_RWY_R <- factor(data.df$REL_RWY_R)
data.df$PROFIL_I_R <- factor(data.df$PROFIL_I_R)
data.df$SPD_LIM <- factor(data.df$SPD_LIM)
data.df$SUR_COND <- factor(data.df$SUR_COND)
data.df$TRAF_CON_R <- factor(data.df$TRAF_CON_R)
data.df$TRAF_WAY <- factor(data.df$TRAF_WAY)
data.df$VEH_INVL <- factor(data.df$VEH_INVL)
data.df$WEATHER_R <- factor(data.df$WEATHER_R)
data.df$INJURY_CRASH <- factor(data.df$INJURY_CRASH)
data.df$NO_INJ_I <- factor(data.df$NO_INJ_I)
data.df$PRPTYDMG_CRASH <- factor(data.df$PRPTYDMG_CRASH)
data.df$FATALITIES <- factor(data.df$FATALITIES)
data.df$INJURY <- factor(data.df$INJURY)
train.df <- data.df[train.index, ]
valid.df <- data.df[-train.index, ]

# ii.
train.nb <- naiveBayes(INJURY ~ ., train.df)
train.nb
# A-priori probabilities:
#   Y
# No       Yes 
# 0.4911296 0.5088704

# training
pred.prob <- predict(train.nb, newdata = train.df, type = "raw")
pred.class <- predict(train.nb, newdata = train.df)
confusionMatrix(pred.class, train.df$INJURY)

# iii.
# validation
pred.prob <- predict(train.nb, newdata = valid.df, type = "raw")
pred.class <- predict(train.nb, newdata = valid.df)
confusionMatrix(pred.class, valid.df$INJURY)
# Error rate is zero.

# iv.
# Both training set and validation set got error rate of zero.

# v.
table(valid.df$INJURY, valid.df$SPD_LIM, dnn = c("INJURY", "SPD_LIM"))
# Among all 25309 cases, we only have one case with INJURY = No and SPD_LIM = 5, so the probability is nearly zero.



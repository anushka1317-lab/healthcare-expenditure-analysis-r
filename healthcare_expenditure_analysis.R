## 1. PACKAGES
library(readxl)
library(tidyverse)
library(car)
library(lmtest)
library(sandwich)
library(stargazer)

## 2. IMPORT DATA
insurance <- read_excel("insurance.xlsx")

# Initial inspection
head(insurance)
str(insurance) 
dim(insurance)   
names(insurance)  
sapply(insurance, class)

## 3. DATA CLEANING

# Check missing values
colSums(is.na(insurance))
# Check duplicate observations
sum(duplicated(insurance))  
# Remove duplicate observations
insurance[duplicated(insurance), ]
insurance <- distinct(insurance)
# Confirm final sample
dim(insurance)

## 4. VARIABLE PREPARATION

# Categorical variables
insurance$sex <- factor(insurance$sex)
insurance$smoker <- factor(insurance$smoker)
insurance$region <- factor(insurance$region)
str(insurance)
colSums(is.na(insurance))

# Log transformation of healthcare expenditure
insurance$log_charges <- log(insurance$charges)
summary(insurance$log_charges)

## Mean-centering for interaction terms (age & BMI)

insurance$age_c <- insurance$age - mean(insurance$age)
insurance$bmi_c <- insurance$bmi - mean(insurance$bmi)

mean(insurance$age_c)
mean(insurance$bmi_c)

## 5. EXPLORATORY DATA ANALYSIS

# 5.1 Distribution of healthcare expenditure
p1 <- ggplot(
  insurance,
  aes(x = charges)
) +
  geom_histogram(
    bins = 30,
    fill = "skyblue",
    color = "white"
  ) +
  labs(
    title = "Distribution of Healthcare Expenditure",
    x = "Healthcare Expenditure (USD)",
    y = "Frequency"
  ) +
  theme_minimal()

print(p1)


# 5.2 Distribution of log healthcare expenditure

p2 <- ggplot(
  insurance,
  aes(x = log_charges)
) +
  geom_histogram(
    bins = 30,
    fill = "mediumseagreen",
    color = "white"
  ) +
  labs(
    title = "Distribution of Log Healthcare Expenditure",
    x = "Log Healthcare Expenditure",
    y = "Frequency"
  ) +
  theme_minimal()

print(p2)

# 5.3 Healthcare expenditure by smoking status

p3 <- ggplot(
  insurance,
  aes(
    x = smoker,
    y = charges,
  fill = smoker)
) +
  geom_boxplot() +
  labs(
    title = "Healthcare Expenditure by Smoking Status",
    x = "Smoking Status",
    y = "Healthcare Expenditure (USD)"
  ) +
  theme_minimal()

print(p3)

# 5.4 Age and healthcare expenditure

p4 <- ggplot(
  insurance,
  aes(
    x = age,
    y = charges,
    color = smoker
  )
) +
  geom_point(alpha = 0.6) +
  geom_smooth(
    method = "lm",
    se = FALSE
  ) +
  labs(
    title = "Healthcare Expenditure by Age and Smoking Status",
    x = "Age (years)",
    y = "Healthcare Expenditure (USD)",
    color = "Smoking Status"
  ) +
  theme_minimal()

print(p4)

## 6. OLS REGRESSION MODELS

# Model 1: Smoking
model1 <- lm(log_charges ~ smoker,
             data = insurance)

summary(model1)

# Model 2: Smoking + Age
model2 <- lm(log_charges ~ smoker + age_c,
             data = insurance)

summary(model2)

# Model 3: Smoking + Age + BMI
model3 <- lm(log_charges ~ smoker + age_c + bmi_c,
             data = insurance)

summary(model3)

# Model 4: Add control variables
model4 <- lm(log_charges ~ age_c + bmi_c +
               smoker +
               sex +
               children +
               region,
             data = insurance)

summary(model4)

# Model 5: Smoking × BMI
model5 <- lm(log_charges ~ age_c +
               bmi_c +
               smoker +
               sex +
               children +
               region +
               smoker:bmi_c,
             data = insurance)

summary(model5)

# Model 6: Smoking × Age
model6 <- lm(log_charges ~ age_c +
               bmi_c +
               smoker +
               sex +
               children +
               region +
               smoker:age_c,
             data = insurance)

summary(model6)

# Model 7: Final model with both interactions
model7 <- lm(log_charges ~ age_c +
               bmi_c +
               smoker +
               sex +
               children +
               region +
               smoker:bmi_c +
               smoker:age_c,
             data = insurance)

summary(model7)

## 7. MODEL COMPARISON

stargazer(
  model1,
  model2,
  model3,
  model4,
  model5,
  model6,
  model7,
  type = "text",
  title = "Healthcare Expenditure Regression Models",
  dep.var.labels = "Log Healthcare Expenditure",
  column.labels = paste0("Model ", 1:7),
  digits = 3
)

## 8. INTERACTION EFFECTS

# Smoking × BMI interaction
coef(model7)["smokeryes:bmi_c"]

# Smoking × Age interaction
coef(model7)["smokeryes:age_c"]

## 9. MULTICOLLINEARITY

vif(model7)

## 10. HETEROSKEDASTICITY

bptest(model7)

## 11. HC1 ROBUST STANDARD ERRORS

coeftest(model7,
         vcov = vcovHC(model7,   type = "HC1"
         )
)

# 12. GAMMA GLM ROBUSTNESS CHECK

# Gamma GLM with a log link is used as a robustness check
# because healthcare expenditure is positive and right-skewed.

glm_gamma <- glm(
  charges ~
    age_c +
    bmi_c +
    smoker +
    sex +
    children +
    region +
    smoker:bmi_c +
    smoker:age_c,
  family = Gamma(link = "log"),
  data = insurance
)

# View Gamma GLM results
summary(glm_gamma)

# 12.1 Compare OLS and Gamma GLM

ols_results <- tidy(model7)

gamma_results <- tidy(glm_gamma)

print(ols_results)
print(gamma_results)

## 13. RAMSEY RESET TEST

# Tests for possible functional-form misspecification.
# A significant result suggests that the current
# functional form may not fully capture the relationship.

resettest(
  model7,
  power = 2:3,
  type = "fitted"
)

## 14. RESIDUAL DIAGNOSTICS
# Residuals vs fitted values
plot(
  model7,
  which = 1,
  main = "Residuals vs Fitted"
)

# Normal Q-Q plot
plot(
  model7,
  which = 2,
  main = "Normal Q-Q Plot"
)
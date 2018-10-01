# ----------------------------
# author: Joël Meili
# meilijoe@students.zhaw.ch
# ----------------------------

# --------------------------------------------------------
# IMPORTANT NOTES:
# ----------------
# - should we use log-returns instead? --> Assumption now
# is that returns follow a gaussian distribution
# KS-test(Kolmogorov-Smirnov test), Null hypothesis is defined as sample is drawn from said distribution --> for distribution testing
# Anderson-Darling-Test statistic test that tests for normality 
# -- The Anderson-Darling test is the recommended EDF test by Stephens (1986).--
# -- Compared to the Cramer-von Mises test (as second choice) it gives more weight to the tails of the distribution. --
# 
# --------------------------------------------------------

# - load packages
library(readxl)
library(tibble)
library(purrr)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(ggthemes)
library(gridExtra)
library(car)
library(nortest)
library(rmutil) # contains levy dist.

# - read data
X35years <- read_excel("C:/Users/joelm/PA18_ZHAW/35years.xlsx")
data <- as.tibble(X35years)
colnames(data) <- c("Date", "SP500", "DAX30", "USTreas", "UKGilt", "EUR", "JPY", "Gold", "Oil")

# - create dataframes for daily, weekly, monthly and yearly aggregation of returns
data.long <- std.daily <- data.daily <- data %>% gather(Asset, Value, 2:ncol(data))
data.weekly <- std.weekly <- data.long %>% group_by(Year=year(Date), Week=week(Date), Asset) %>% summarise(Value=sum(Value))
data.monthly <- std.monthly <- data.long %>% group_by(Year=year(Date), Month=month(Date), Asset) %>% summarise(Value=sum(Value))
data.yearly <- std.yearly <- data.long %>% group_by(Year=year(Date), Asset) %>% summarise(Value=sum(Value))

# - calculating value-at-risk for three different quantiles for each category e.g. daily data
conf.level <- list(0.84, 0.975, 0.999)

daily.var <- lapply(conf.level, FUN=function(x){
  temp <- data.daily %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=(1-x)))
  colnames(temp)[2] <- paste("VaR @", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))
daily.var$Horizon <- "Daily"
weekly.var <- lapply(conf.level, FUN=function(x){
  temp <- data.weekly %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=(1-x)))
  colnames(temp)[2] <- paste("VaR @", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))
weekly.var$Horizon <- "Weekly"
monthly.var <- lapply(conf.level, FUN=function(x){
  temp <- data.monthly %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=(1-x)))
  colnames(temp)[2] <- paste("VaR @", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))
monthly.var$Horizon <- "Monthly"
yearly.var <- lapply(conf.level, FUN=function(x){
  temp <- data.yearly %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=(1-x)))
  colnames(temp)[2] <- paste("VaR @", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))
yearly.var$Horizon <- "Yearly"
data.var <- rbind(daily.var, weekly.var, monthly.var, yearly.var)

norm.daily <- data.daily %>% group_by(Asset) %>% summarise(mu=mean(Value), sd=sd(Value))
norm.weekly <- data.weekly %>% group_by(Asset) %>% summarise(mu=mean(Value), sd=sd(Value))
norm.monthly <- data.monthly %>% group_by(Asset) %>% summarise(mu=mean(Value), sd=sd(Value))
norm.yearly <- data.yearly %>% group_by(Asset) %>% summarise(mu=mean(Value), sd=sd(Value))

std.daily <- std.daily %>% group_by(Asset) %>% mutate(Value=scale(Value))
std.daily$Freq <- "daily"
std.weekly <- std.weekly %>% group_by(Asset) %>% mutate(Value=scale(Value))
std.weekly$Freq <- "weekly"
std.monthly <- std.monthly %>% group_by(Asset) %>% mutate(Value=scale(Value))
std.monthly$Freq <- "monthly"
std.yearly <- std.yearly %>% group_by(Asset) %>% mutate(Value=scale(Value))
std.yearly$Freq <- "yearly"

# - standardized distribution plots
h.daily <- ggplot(std.daily, aes(x=Value))+
  geom_density()+
  stat_function(fun=dnorm, colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of standardized daily returns")+
  ggsave("figures/return_distribution_daily.png")

h.weekly <- ggplot(std.weekly, aes(x=Value))+
  geom_density()+
  stat_function(fun=dnorm, colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of standardized weekly returns")+
  ggsave("figures/return_distribution_weekly.png")

h.monthly <- ggplot(std.monthly, aes(x=Value))+
  geom_density()+
  stat_function(fun=dnorm, colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of standardized monthly returns")+
  ggsave("figures/return_distribution_monthly.png")

h.yearly <- ggplot(std.yearly, aes(x=Value))+
  geom_density()+
  stat_function(fun=dnorm, colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of standardized yearly returns")+
  ggsave("figures/return_distribution_yearly.png")

# - standardized qq-plots
qq.daily <- ggplot(std.daily, aes(sample=Value))+
  stat_qq(geom="line")+
  stat_qq_line(colour='red')+
  facet_wrap(~Asset)+
  xlab("Theoretical Quantiles")+
  ylab("Sample Quantiles")+
  ggtitle("QQ-Plot of daily returns")+
  ggsave("figures/return_qq_daily.png")

qq.weekly <- ggplot(std.weekly, aes(sample=Value))+
  stat_qq(geom="line")+
  stat_qq_line(colour='red')+
  facet_wrap(~Asset)+
  xlab("Theoretical Quantiles")+
  ylab("Sample Quantiles")+
  ggtitle("QQ-Plot of weekly returns")+
  ggsave("figures/return_qq_weekly.png")

qq.monthly <- ggplot(std.monthly, aes(sample=Value))+
  stat_qq(geom="line")+
  stat_qq(geom="line")+
  stat_qq_line(colour='red')+
  facet_wrap(~Asset)+
  xlab("Theoretical Quantiles")+
  ylab("Sample Quantiles")+
  ggtitle("QQ-Plot of monthly returns")+
  ggsave("figures/return_qq_monthly.png")

qq.yearly <- ggplot(std.yearly, aes(sample=Value))+
  stat_qq(geom="line")+
  stat_qq_line(colour='red')+
  facet_wrap(~Asset)+
  xlab("Theoretical Quantiles")+
  ylab("Sample Quantiles")+
  ggtitle("QQ-Plot of yearly returns")+
  ggsave("figures/return_qq_yearly.png")

# - standardized normal distribution and qq-plots with package car and base
lst <- list(std.daily, std.weekly, std.monthly, std.yearly)
lapply(lst, FUN=function(x){
  assets <- unique(x$Asset)
  sapply(assets, FUN=function(y){
    string <- unique(x$Freq)
    png(paste0(paste0("figures/return_distribution_", paste0(paste0(string, "_"), y)), ".png"))
    dens <- density(x$Value[which(x$Asset==y)])
    plot(dens$x, dens$y, type='l', xlab="Value", ylab="Density")
    lines(seq(-20, 20, length.out=1e4), dnorm(seq(-20, 20, length.out=1e4)), col='red')
    title(paste(paste("Distribution of standardized", paste(string, "returns -")), y))
    dev.off()
    
    png(paste0(paste0("figures/return_qq_", paste0(paste0(string, "_"), y)), ".png"))
    qqPlot(x$Value[which(x$Asset==y)], xlab="Theoretical Quantiles", ylab="Sample Quantiles")
    title(paste(paste("QQ-Plot of standardized", paste(string, "returns -")), y)) 
    dev.off()
  })
})

# - disribution testing
p.val.daily <- std.daily %>% group_by(Asset) %>% summarise(p.value=ad.test(Value)$p.value)
colnames(p.val.daily)[2] <- "Daily"
p.val.weekly <- std.weekly %>% group_by(Asset) %>% summarise(p.value=ad.test(Value)$p.value)
colnames(p.val.weekly)[2] <- "Weekly"
p.val.monthly <- std.monthly %>% group_by(Asset) %>% summarise(p.value=ad.test(Value)$p.value)
colnames(p.val.monthly)[2] <- "Monthly"
p.val.yearly <- std.yearly %>% group_by(Asset) %>% summarise(p.value=ad.test(Value)$p.value)
colnames(p.val.yearly)[2] <- "Yearly"
p.values <- list(p.val.daily, p.val.weekly, p.val.monthly, p.val.yearly) %>% reduce(inner_join, by="Asset")





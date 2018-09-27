# ----------------------------
# author: Joël Meili
# meilijoe@students.zhaw.ch
# ----------------------------

# - load packages
library(readxl)
library(tibble)
library(purrr)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(ggthemes)

# - read data
X35years <- read_excel("C:/Users/joelm/PA18_ZHAW/35years.xlsx")
data <- as.tibble(X35years)
colnames(data) <- c("Date", "SP500", "DAX30", "USTreas", "UKGilt", "EUR", "JPY", "Gold", "Oil")

# - create dataframes for daily, weekly, monthly and yearly aggregation of returns
data.long <- data.daily <- data %>% gather(Asset, Value, 2:ncol(data))
data.weekly <- data.long %>% group_by(Year=year(Date), Week=week(Date), Asset) %>% summarise(Value=sum(Value))
data.monthly <- data.long %>% group_by(Year=year(Date), Month=month(Date), Asset) %>% summarise(Value=sum(Value))
data.yearly <- data.long %>% group_by(Year=year(Date), Asset) %>% summarise(Value=sum(Value))

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

n.sample = 1e4

rnorm.daily <- do.call("rbind", lapply(as.list(norm.daily$Asset), FUN=function(x){
  tibble("Asset"=x, "Value"=rnorm(n.sample, mean=as.numeric(norm.daily[which(norm.daily$Asset==x), "mu"]), sd=as.numeric(norm.daily[which(norm.daily$Asset==x), "sd"])))
}))
rnorm.weekly <- do.call("rbind", lapply(as.list(norm.weekly$Asset), FUN=function(x){
  tibble("Asset"=x, "Value"=rnorm(n.sample, mean=as.numeric(norm.weekly[which(norm.weekly$Asset==x), "mu"]), sd=as.numeric(norm.weekly[which(norm.weekly$Asset==x), "sd"])))
}))
rnorm.monthly <- do.call("rbind", lapply(as.list(norm.monthly$Asset), FUN=function(x){
  tibble("Asset"=x, "Value"=rnorm(n.sample, mean=as.numeric(norm.monthly[which(norm.monthly$Asset==x), "mu"]), sd=as.numeric(norm.monthly[which(norm.monthly$Asset==x), "sd"])))
}))
rnorm.yearly <- do.call("rbind", lapply(as.list(norm.yearly$Asset), FUN=function(x){
  tibble("Asset"=x, "Value"=rnorm(n.sample, mean=as.numeric(norm.yearly[which(norm.yearly$Asset==x), "mu"]), sd=as.numeric(norm.yearly[which(norm.yearly$Asset==x), "sd"])))
}))

# - plot distribution of returns for each category e.g. daily data
g.daily <- ggplot(data=data.daily, aes(x=Value))+
  geom_density()+
  geom_density(data=rnorm.daily, aes(x=Value), colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of daily returns")+
  ggsave('return_distribution_daily.png')

g.weekly <- ggplot(data.weekly, aes(x=Value))+
  geom_density()+
  geom_density(data=rnorm.weekly, aes(x=Value), colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of weekly returns")+
  ggsave('return_distribution_weekly.png')

g.monthly <- ggplot(data.monthly, aes(x=Value))+
  geom_density()+
  geom_density(data=rnorm.monthly, aes(x=Value), colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of monthly returns")+
  ggsave('return_distribution_monthly.png')

g.yearly <- ggplot(data.yearly, aes(x=Value))+
  geom_density()+
  geom_density(data=rnorm.yearly, aes(x=Value), colour='red')+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggtitle("Distribution of yearly return")+
  ggsave('return_distribution_yearly.png')
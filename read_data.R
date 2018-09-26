# ----------------------------
# author: Joël Meili
# meilijoe@students.zhaw.ch
# ----------------------------

# - load packages
library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)
library(ggthemes)

# - read data
X35years <- read_excel("C:/Users/joelm/PA18_ZHAW/35years.xlsx")
data <- as.data.frame(X35years)
colnames(data) <- c("Date", "SP500", "DAX30", "USTreas", "UKGilt", "EUR", "JPY", "Gold", "Oil")

# - create dataframes for daily, weekly, monthly and yearly aggregation of returns
data.long <- data.daily <- data %>% gather(Asset, Value, 2:ncol(data))
data.weekly <- data.long %>% group_by(Year=year(Date), Week=week(Date), Asset) %>% summarise(Value=sum(Value))
data.monthly <- data.long %>% group_by(Year=year(Date), Month=month(Date), Asset) %>% summarise(Value=sum(Value))
data.yearly <- data.long %>% group_by(Year=year(Date), Asset) %>% summarise(Value=sum(Value))

# - calculating value-at-risk for three different quantiles for each category e.g. daily data
conf.level <- list(0.84, 0.975, 0.999)

daily.var <- lapply(conf.level, FUN=function(x){
  temp <- data.daily %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=x))
  colnames(temp)[2] <- paste("VaR", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))
weekly.var <- lapply(conf.level, FUN=function(x){
  temp <- data.weekly %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=x))
  colnames(temp)[2] <- paste("VaR", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))
monthly.var <- lapply(conf.level, FUN=function(x){
  temp <- data.monthly %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=x))
  colnames(temp)[2] <- paste("VaR", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))
yearly.var <- lapply(conf.level, FUN=function(x){
  temp <- data.yearly %>% group_by(Asset) %>% summarise(VaR=quantile(Value, p=x))
  colnames(temp)[2] <- paste("VaR", paste0(x*100, "%"))
  temp
}) %>% reduce(inner_join, by="Asset") %>% gather(VaR, Value, 2:(length(conf.level)+1))

# - plot distribution of returns for each category e.g. daily data
g.daily <- ggplot(data.daily, aes(x=Value))+
  geom_density()+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggsave('return_distribution_daily.png')

g.weekly <- ggplot(data.weekly, aes(x=Value))+
  geom_density()+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggsave('return_distribution_weekly.png')

g.monthly <- ggplot(data.monthly, aes(x=Value))+
  geom_density()+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggsave('return_distribution_monthly.png')

g.yearly <- ggplot(data.yearly, aes(x=Value))+
  geom_density()+
  facet_wrap(~Asset)+
  xlab(NULL)+
  ylab(NULL)+
  ggsave('return_distribution_yearly.png')
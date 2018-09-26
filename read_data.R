library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)
library(ggthemes)

X35years <- read_excel("C:/Users/joelm/PA18_ZHAW/35years.xlsx")
data <- as.data.frame(X35years)
colnames(data) <- c("Date", "SP500", "DAX30", "USTreas", "UKGilt", "EUR", "JPY", "Gold", "Oil")
data.long <- data.daily <- data %>% gather(Asset, Value, 2:ncol(data))
data.weekly <- data.long %>% group_by(Year=year(Date), Week=week(Date), Asset) %>% summarise(Value=sum(Value))
data.monthly <- data.long %>% group_by(Year=year(Date), Month=month(Date), Asset) %>% summarise(Value=sum(Value))
data.yearly <- data.long %>% group_by(Year=year(Date), Asset) %>% summarise(Value=sum(Value))

conf.level <- c(0.84, 0.975, 0.999)

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

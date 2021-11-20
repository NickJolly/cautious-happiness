
library(stringr)
library(ggplot2)
library(ggfortify)

# Dataset published by the City of Melbourne
# https://data.melbourne.vic.gov.au/Environment/Microclimate-Sensor-Readings/u4vh-84j8?src=featured_banner

sensors <- read.csv('Microclimate_Sensor_Readings.csv')

# Just look at 2021 data
sensors$Year <- as.integer(str_sub(sensors$local_time, start=1, end=4))
sensors21 <- sensors[str_sub(sensors$local_time, start=1, end=4) == '2021', ]

# Code each row by Month/Day/Hour
sensors21$Month <- as.integer(str_sub(sensors21$local_time, start=6, end=7))
sensors21$Day <- as.integer(str_sub(sensors21$local_time, start=9, end=10))

q <- str_sub(sensors21$local_time, start=21, end=22)
sensors21$Hour <- as.integer(str_sub(sensors21$local_time, start=12, end=13))
sensors21$Hour[q=='PM'] <- sensors21$Hour[q=='PM'] + 12
sensors21$Hour[sensors21$Hour==12] <- 0

sensors21$TimeCode <- paste(sensors21$Month, sensors21$Day, sensors21$Hour)

# Create a new dataset with each row uniquely identified by date, time, location
# Each row contains temperature, barometric, wind, and particle readings
new_data <- data.frame()

sites <- unique(sensors$site_id)
for (s in sites) {
  site_data <- sensors21[sensors21$site_id == s, ]
  codes <- unique(site_data$TimeCode)
  for (c in codes) {
    time_data <- site_data[site_data$TimeCode == c, ]
    
    temp <- mean(time_data[time_data$type=='TPH.TEMP',]$value)
    barom <- mean(time_data[time_data$type=='TPH.PRESSURE',]$value)
    wind <- mean(time_data[time_data$type=='WS',]$value)
    particle10 <- mean(time_data[time_data$type=='PM10-EPA-1h-NOPK',]$value)
    particle2.5 <- mean(time_data[time_data$type=='PM2.5-EPA-1h-NOPK',]$value)
    date <- time_data[]
    
    row <- data.frame('site'=s, 'hour'=time_data[1,]$Hour, 
                      'day'=time_data[1,]$Day, 'month'=time_data[1,]$Month,
                      'temp'=temp, 'pressure'=barom, 'wind'=wind,
                      'particle10'=particle10, 'particle2.5'=particle2.5)
    
    new_data <- rbind(new_data, row)
  }
}


# Discard rows with missing values
df <- new_data[complete.cases(new_data),]
df <- df[df$wind!=0,]

# Create PCA plots for daytime and nighttime readings, coloured by season
df$season <- NA
df[df$month== 12 | df$month==1 | df$month==2, ]$season <- 'Summer'
df[df$month== 3 | df$month==4 | df$month==5, ]$season <- 'Autumn'
df[df$month== 6 | df$month==7 | df$month==8, ]$season <- 'Winter'
df[df$month== 9 | df$month==10 | df$month==11, ]$season <- 'Spring'


df_days <- df[df$hour > 8, ]
df_days <- df_days[df_days$hour < 21, ]
df_nights <- rbind(df[df$hour < 9, ], df[df$hour > 20, ])

melb_pca_days <- prcomp(df_days[4:6], scale=T)
melb_pca_days
summary(melb_pca_days)
melb_pca_nights <- prcomp(df_nights[4:6], scale=T)

autoplot(melb_pca_days, colour='season', data=df_days, size=0.4) + 
  scale_colour_manual(name='Season',
    values=c('lightgoldenrod3','palegreen3','sienna3','steelblue3')) +
  ggtitle('City of Melbourne: Days') +
  theme(plot.title=element_text(face='bold', hjust=0.5))

autoplot(melb_pca_nights, colour='season', data=df_nights, size=0.4) + 
  scale_colour_manual(name='Season',
    values=c('lightgoldenrod3','palegreen3','sienna3','steelblue3')) +
  ggtitle('City of Melbourne: Nights') +
  theme(plot.title=element_text(face='bold', hjust=0.5))

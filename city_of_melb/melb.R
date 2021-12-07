# Dataset available at:
# https://data.melbourne.vic.gov.au/Environment/Microclimate-Sensor-Readings/u4vh-84j8

library(stringr)
library(chron)
library(ggplot2)
library(ggfortify)
library(gganimate)
library(gifski)

sensors <- read.csv('Microclimate_Sensor_Readings.csv')
sensors$local_time <- strptime(sensors$local_time, 
                                format='%Y/%m/%d %I:%M:%S %p')
sensors$local_time <- round(sensors$local_time, 'hour')

# Select sub-set of data: 11th Nov to 18th Nov 2021
sensors <- sensors[sensors$local_time >'2021/11/11',]
sensors <- sensors[sensors$local_time < '2021/11/18',]
sensors$day <- unclass(sensors$local_time)$mday
sensors$hour <- unclass(sensors$local_time)$hour

# Transform data
days <- sort(unique(sensors$day))
sites <- sort(unique(sensors$site_id))

df <- data.frame()
for (i in days) {
  daily <- sensors[sensors$day==i,]
  for (j in 1:23) {
    hourly <- daily[daily$hour==j,]
    time <- data.frame('time'=hourly[1,]$local_time)
    for (k in sites) {
      site_data <- hourly[hourly$site_id==k,]
      temps <- site_data[site_data$type=='TPH.TEMP',]$value
      winds <- site_data[site_data$type=='WS',]$value
      rel_humid <- site_data[site_data$type=='TPH.RH',]$value
      row <- data.frame('time'=time, 'site'=k, 
                        'temp'=mean(temps), 'wind'=mean(winds),
                        'rh'=mean(rel_humid))
      df <- rbind(df, row)
    }
  }
}

df <- df[complete.cases(df),]
df$site <- factor(df$site)




# write.csv(df, 'readings.csv')
# df <- read.csv('readings.csv')

# Figure 1
plot(df[df$site==1007,]$time,df[df$site==1007,]$temp, type='l',
     ylim=c(7,20), xlab= 'Date', ylab='Temperature (degrees C)',
     main='Temperature Readings in Melbourne')
for (i in sites[2:10]) {
  lines(df[df$site==i,]$time,df[df$site==i,]$temp, type='l', col=i)
}

# Figure 2
df_1013 <- df[df$site==1013,]
ggplot(df_1013, aes(time, temp, size=wind, col=rh)) +
  geom_point(alpha=0.7) +
  scale_size(name='Wind Speed (km/h)') +
  scale_colour_gradientn(colours=c('peru','darkorchid1','deepskyblue2'),
                         values=c(0,0.5,1), 
                         name='Rel. Humidity (%)') +
  theme(plot.background=element_rect(fill='white'),
        panel.background=element_rect(fill='#f2f2f2'),
        plot.title=element_text(face='bold', hjust=0.5)) +
  labs(x='Date', y='Temperature (degrees C)', title='Site 1013')
  
# Figure 3
p <- ggplot(df, aes(site, temp, size=wind, col=rh)) + 
  geom_point(alpha=0.8) +
  scale_size(name='Wind Speed (km/h)') +
  scale_colour_gradientn(colours=c('peru','darkorchid1','deepskyblue2'),
                         values=c(0,0.5,1),
                         name='Rel. Humidity (%)') +
  theme(plot.background=element_rect(fill='white'),
        panel.background=element_rect(fill='#f2f2f2'),
        panel.grid.major.x=element_blank(),
        plot.title=element_text(size=16, face='bold', hjust=0.5),
        plot.subtitle=element_text(hjust=0.5),
        axis.text=element_text(size=12),
        axis.title=element_text(size=11,face='bold'))+
  transition_time(time) +
  labs(title='Temperatures in Melbourne',subtitle='Time code: {frame_time}', 
       x='Site ID', y='Temperature (degrees C)') +
  shadow_mark(alpha = 0.3, size = 1)

animate(p, duration = 60, fps = 20, width = 750, height = 600, 
        renderer = gifski_renderer())

anim_save('anim1.gif')

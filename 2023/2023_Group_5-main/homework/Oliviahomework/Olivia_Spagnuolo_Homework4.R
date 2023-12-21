#Install packages and load libraries:

install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)

# gbifopts: run occ_options('gbif') in console to see possibilities()
occ_options('gbif')

#Query for the tortoise
tortoisequery<-occ(query = 'Gopherus morafkai', from = 'gbif', limit=4000)
tortoisequery

#Drill down data
tortoise<-tortoisequery$gbif$data$Gopherus_morafkai

#Plot data
wrld<-ggplot2::map_data("world")
ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long,y=lat,group=group), fill="grey75", colour="grey60")+
  geom_point(data=tortoise,mapping=aes(x=longitude,y=latitude), show.legend = FALSE)+
  labs(title="Species occurences of G. morafkai", x="longitude", y="latitude")

#Clean data - NA values and duplicates. And occurrence status present. There weren't any outliers. 
clean.tortoise<-tortoise%>%filter(latitude!="NA", longitude!="NA")%>% mutate(location=paste(latitude, longitude, dateIdentified, sep="/"))%>%
  distinct(location, .keep_all=TRUE)%>%filter(occurrenceStatus=="PRESENT")
clean.tortoise

#Create min and max values for the map
xmax <- max(clean.tortoise$longitude)
xmin <- min(clean.tortoise$longitude)
ymax<- max(clean.tortoise$latitude)
ymin<- min(clean.tortoise$latitude)

#make the map! 
wrld<-ggplot2::map_data("world")
ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long,y=lat,group=group), fill="grey75", colour="grey60")+
  geom_point(data=tortoise,mapping=aes(x=longitude,y=latitude), show.legend = FALSE)+
  labs(title="Species occurences of G. morafkai 1986-2022", x="longitude", y="latitude")+
  coord_fixed(xlim=c(xmin,xmax),ylim=c(ymin,ymax))+
  scale_size_area()+
  borders("state")

#Occurrence points are data that shows there was a species located there or evidence of a species. 



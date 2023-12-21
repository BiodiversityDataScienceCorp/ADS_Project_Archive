
install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)

occ_options('gbif')

Tortoise <- occ(query='Gopherus morafkai', from=c('gbif'), limit=4000)
Tortoise

Gopherus <- Tortoise$gbif$data$Gopherus_morafkai
Gopherus

ggplot()+
  geom_point(data=Gopherus, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences", x="longitude", y="latitude")

wrld <- ggplot2::map_data("world")

ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey75", color = "grey60")+
  geom_point(data=Gopherus, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences", x="longitude", y="latitude")


cleanTortoise <- Gopherus %>% 
  filter(longitude <= 0) %>% 
  filter(latitude != "NA", longitude != "NA") %>% 
  filter(occurrenceStatus == "PRESENT") %>%
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/"))%>%
  distinct(location, .keep_all=TRUE)
#only filtered NAs and duplicates because map didn't show any extreme outliers, 
#all occurrences were located in southern US and Mexico.  

xmax <- max(cleanTortoise$longitude)
xmin <- min(cleanTortoise$longitude)
ymax <- max(cleanTortoise$latitude)
ymin <- min(cleanTortoise$latitude)

ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="burlywood1", color = "grey9")+
  geom_point(data=cleanTortoise, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences of Gopherus morafkai 1968-2022", x="longitude", y="latitude") +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin,ymax))+
  scale_size_area()+
  borders("state")

range(as.Date(na.omit(cleanTortoise$dateIdentified)))

#The occurrence points are where the species was noted as existing,
#meaning there was evidence that the species was located in that specific area. 

#attempting to add state names 


ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="burlywood1", color = "grey9")+
  geom_point(data=cleanTortoise, mapping=aes(x=longitude, y=latitude), show.legend=FALSE) +
  labs(title = "species occurences of Gopherus morafkai 1968-2022", x="longitude", y="latitude") +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin,ymax))+
  scale_size_area()+
  borders("state")

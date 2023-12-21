#Install packages and load libraries:

install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)

snailquery <- occ(query= "Ashmunella levettei", from = "gbif", limit= 4000)


# Drill down to get the data using "$", and show from Env window
snail <- snailquery$gbif$data$Ashmunella_levettei

### Let's initially plot the data on a map.
snail <-  snailquery$gbif$data$Ashmunella_levettei


#deal with NA values
noNAPoints <- snail %>%
  filter(latitude!="NA", longitude !="NA")


#remove duplicates
noDupsn <-  noNAPoints %>% mutate (location= paste (latitude, longitude, dateIdentified,  sep = "/")) %>%
  distinct(location, .keep_all = TRUE)



cleansnail <- snail%>%
  filter(latitude != "NA", longitude != "NA") %>%
  mutate(location = paste (latitude, longitude, f=dateIdentified, sep = "/"))%>%
  distinct(location, .keep_all = TRUE)



xmax <- max(cleansnail$longitude)
xmin <- min(cleansnail$longitude)
ymax <- max(cleansnail$latitude)
ymin <- min(cleansnail$latitude)


wrld <- ggplot2::map_data("world")
ggplot()+
  geom_polygon(data= wrld, mapping=aes(x=long, y=lat, group=group),fill="grey75",colour="grey60")+
  geom_point(data=cleansnail, mapping=aes(x=longitude, y=latitude), show.legend=FALSE)+
  labs(title="species occurences of A. levettei, x=longitude, y=latitude")+ 
  coord_fixed(xlim=c(xmin,xmax), ylim=c(ymin, ymax))+
  borders("state")




##Occurence points show up when there is the A. Levettei speicies located in the specific latitude and longitude. 

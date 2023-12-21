#Install packages and load libraries:

install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)

snailquery <- occ(query = "Ashmunella levettei", from = "gbif", limit = 4000)

# Drill down to get the data using "$", and show from Env window
snail <- snailquery$gbif$data$Ashmunella_levettei

#deal w/ NAs
noNA <- snail %>% filter(latitude != "NA", longitude != "NA")

#remove duplicates
noDupSn <- noNA %>% mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>%
  distinct(location, .keep_all = TRUE)

cleanSnail <- snail %>% 
  filter(latitude != "NA", longitude != "NA") %>%
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>%
  distinct(location, .keep_all = TRUE)

xmax <- max(cleanSnail$longitude)
xmin <- min(cleanSnail$longitude)
ymax <- max(cleanSnail$latitude)
ymin <- min(cleanSnail$latitude)
wrld <- ggplot2::map_data("world")

ggplot()+
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey75", colour="grey60")+
  geom_point(data=cleanSnail, mapping=aes(x=longitude, y=latitude), show.legend = FALSE)+
  labs(title="Species occurences of A. levettei", x="longitude", y="latitude")+
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax))+
  scale_size_area()+
  borders("state")

#occurrence points are geographical observations noted within GBIF
##seen in southern Arizona mostly, but a few points noted in other parts of Arizona and New Mexico
#but very few, so not sure if accurate or not
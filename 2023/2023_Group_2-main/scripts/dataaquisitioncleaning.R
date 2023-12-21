install.packages("spocc")
install.packages("tidyverse") #includes ggplot
library(spocc)
library(tidyverse)

#get occurrence data from gbif
myQuery<-occ(query="Martes caurina", from="gbif", limit=4000)
myQuery

marten<-myQuery$gbif$data$Martes_caurina

wrld<-ggplot2::map_data("world")


cleanMarten <- marten %>% 
  filter(latitude != "NA", longitude != "NA", occurrenceStatus=="PRESENT") %>% #remove NA values and when occurrence status is not present
  mutate(location = paste(latitude, longitude, dateIdentified, sep="/")) %>%
  distinct(location, .keep_all = TRUE) #remove duplicate



write_csv(cleanMarten, file="data/marten.csv")
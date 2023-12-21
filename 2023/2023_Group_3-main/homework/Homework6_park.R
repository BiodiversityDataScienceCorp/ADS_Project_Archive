#homework6 
#Hailey Park

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

##save data
write.csv(cleanSnail, "data\\snail_data.csv")


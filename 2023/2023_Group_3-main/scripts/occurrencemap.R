#Occurrence Map
#03/18/2023
#Synthesized from team member's individual scripts
#Bailie Wynbelt, Hailey Park, Zoe Evans, Josie Graydon

### SECTION 1: Install needed packages and query snail data from GBIF ###

install.packages("spocc")
install.packages("tidyverse") 
library(spocc)
library(tidyverse)

snailquery <- occ(query = "Ashmunella levettei", from = "gbif", limit = 4000)

# Drill down to get the data using "$", and show from Env window
snail <- snailquery$gbif$data$Ashmunella_levettei

# Remove NA's in the latitude and longitude columns using the filter() function
noNA <- snail %>% 
  filter(latitude != "NA", longitude != "NA")

#Remove duplicates
#using the mutate() function, create a new column called location with longitude/latitude/dateIdentified that is seprated by /
#keep only distinct locations with the distinct() function
noDupSn <- noNA %>% 
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>%
  distinct(location, .keep_all = TRUE)

# All required data cleaning in one chunk of code
#remove NA's in latitude and longitude with filter() function
#remove any outliers in the latitude and longitude columns with the filter() function.
#using the mutate() function, create a new column called location with longitude/latitude/dateIdentified that is seprated by /
#keep only distinct locations with the distinct() function
cleanSnail <- snail %>% 
  filter(latitude != "NA", longitude != "NA") %>%
  filter(latitude <= 33, longitude <= -109) %>%
  mutate(location = paste(latitude, longitude, dateIdentified, sep = "/")) %>%
  distinct(location, .keep_all = TRUE)

### SECTION 2: Plot occurrences with ggplot ###

# Set longitude and latitude boundaries for the occurrence map
xmax <- max(cleanSnail$longitude) + 1
xmin <- min(cleanSnail$longitude) - 1
ymax <- max(cleanSnail$latitude) + 1
ymin <- min(cleanSnail$latitude) - 1

# load in the world data for the map
wrld <- ggplot2::map_data("world")
# Adding state variable from map_data to add state labels to SDM
states <- ggplot2::map_data("state")

# clean up labels so state names are spelled out and in title case
state_label <- states %>%
  group_by(region) %>%
  summarize(mean_long = mean(range(long)),
            mean_lat = mean(range(lat)))

state_label$region <- str_to_title(state_label$region)

# Plot occurrence data using ggplot
ggplot() +
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat, group=group), fill="grey75", colour="grey60")+
  geom_point(data=cleanSnail, mapping=aes(x=longitude, y=latitude), show.legend = FALSE) +
  labs(title="Species Occurrences of A. levettei", x="longitude", y="latitude") +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax)) +
  scale_size_area() +
  borders("state") +
  geom_text(data=state_label, aes(x=mean_long, y=mean_lat, label=region))

#save the image
ggsave(file="occurrencemap.jpg",
       plot=last_plot(), 
       path = "output", 
       width=1600, 
       height=1000, 
       units="px")
# Occurrence points are geographical observations noted within GBIF
# Spotted in southern Arizona mostly, but a few points noted in other parts of Arizona and New Mexico
# but very few, so not sure if accurate or not
#Data Acqisition Cleaning 
#Zoe 03/07/23
#first draft of this file
# based on - https://docs.google.com/document/d/10ppTiiD_ogwr3o3ZQcsQ0EsqCYjJIGI_DxV5NYqupwk/edit
# Bailie Wynbelt, Hailey Park, Zoe Evans, Josie Graydon

### SECTION 1: Install required packages and loading library ###

install.packages("spocc")
install.packages("tidyverse") 
library(spocc)
library(tidyverse)

### SECTION 2: Query the snail data from GBIF ###

# Getting snail data from GBIF
snailquery<-occ(query = "Ashmunella levettei", from = "gbif", limit = 4000)
snailquery

# Creating a data frame from snailquery
snail<-snailquery$gbif$data$Ashmunella_levettei


### SECTION 3: Clean the snail data and export to csv ###

# Clean the snail data - 
#remove NA's in latitude and longitude with filter() function
#remove any outliers in the latitude and longitude columns with the filter() function.
#using the mutate() function, create a new column called location with longitude/latitude/dateIdentified that is seprated by /
#keep only distinct locations with the distinct() function.
cleanSnail <- snail%>% 
  filter(latitude !="NA", longitude !="NA") %>% 
  filter(latitude <= 33, longitude <= -109) %>%
  mutate(location = paste(latitude, longitude,dateIdentified, sep = "/" ))%>% 
  distinct(location, .keep_all = TRUE)

# Export to csv file in the data folder
write_csv(cleanSnail, file="data/snaildata.csv")


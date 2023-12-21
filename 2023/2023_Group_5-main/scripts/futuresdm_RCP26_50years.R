
# get climate data
currentEnv <- clim # renaming from the last sdm because "clim" isn't very specific

# to set our specific future data...
# Can adjust the year by changing the "year" value, depending on how many years in the future you want to look. 
# The options are 50 or 70.
# Ours is year = 50, for 50 years into the future
# RCP: In this SDM, we use rcp 26 for a less extreme climate scenario.
# Make query for the future data and make it a raster
futureEnv <- raster::getData(name = 'CMIP5', var = 'bio', res = 2.5,
                             rcp = 26, model = 'IP', year = 50, path="data") 
# make future data columnn names same as current ones
names(futureEnv) = names(currentEnv)

# crop clim to the extent of the map you want
geographicAreaFutureC5 <- crop(futureEnv, predictExtent)


# predict  model onto future climate
tortoisePredictPlotFutureC5 <- raster::predict(tortoiseSDM, geographicAreaFutureC5)  

# for ggplot, we need the prediction to be a data frame 
#convert output of the tortoisePredictPlot to a data frame
raster.spdfFutureC5 <- as(tortoisePredictPlotFutureC5, "SpatialPixelsDataFrame")
tortoisePredictDfFutureC5 <- as.data.frame(raster.spdfFutureC5)

#PLOT IT!!!
wrld <- ggplot2::map_data("world")

# get our lat/long boundaries
xmax <- max(tortoisePredictDfFutureC5$x)
xmin <- min(tortoisePredictDfFutureC5$x)
ymax <- max(tortoisePredictDfFutureC5$y)
ymin <- min(tortoisePredictDfFutureC5$y)

# make the final future SDM in ggplot:
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = tortoisePredictDfFutureC5, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T), limits = c(0,1)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("world") +
  borders("state") +
  labs(title = "SDM of G. Morafkai\nUnder RCP 2.6\nClimate Conditions \n 50 years",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 


# Save the final plot using ggsave
ggsave(filename="futureSDM_RCP26_50years.jpg", plot=last_plot(),path="output", width=1600, height=800, units="px")



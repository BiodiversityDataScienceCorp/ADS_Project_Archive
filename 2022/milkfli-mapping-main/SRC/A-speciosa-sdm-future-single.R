# Script to run forecast species distribution model for a single species
# Jeff Oliver
# jcoliver@email.arizona.edu
# 2017-09-07

rm(list = ls())

################################################################################
# SETUP
# Gather path information
# Load dependancies

# Things to set:
infile <- "Data/A_speciosa.csv"
outprefix <- "A_speciosa"
outpath <- "Outputs/"

# Make sure the input file exists
if (!file.exists(infile)) {
  stop(paste0("Cannot find ", infile, ", file does not exist.\n"))
}

# Make sure the input file is readable
if (file.access(names = infile, mode = 4) != 0) {
  stop(paste0("You do not have sufficient access to read ", infile, "\n"))
}

# Make sure the output path ends with "/" (and append one if it doesn't)
if (substring(text = outpath, first = nchar(outpath), last = nchar(outpath)) != "/") {
  outpath <- paste0(outpath, "/")
}

# Make sure directories are writable
required.writables <- c("data", outpath)
write.access <- file.access(names = required.writables)
if (any(write.access != 0)) {
  stop(paste0("You do not have sufficient write access to one or more directories. ",
              "The following directories do not appear writable: \n",
              paste(required.writables[write.access != 0], collapse = "\n")))
}

# Load dependancies, keeping track of any that fail
required.packages <- c("raster", "sp", "dismo", "maptools")
missing.packages <- character(0)
for (one.package in required.packages) {
  if (!suppressMessages(require(package = one.package, character.only = TRUE))) {
    missing.packages <- cbind(missing.packages, one.package)
  }
}

if (length(missing.packages) > 0) {
  stop(paste0("Missing one or more required packages. The following packages are required for run-sdm: ", paste(missing.packages, sep = "", collapse = ", ")), ".\n")
}


source(file = "SRC/sdm-functions.R")

################################################################################
# ANALYSES
# Prepare data
# Run species distribution modeling
# Combine results from butterflies and plants

# Prepare data
prepared.data <- PrepareData(file = infile)

# Run species distribution modeling
sdm.raster <- SDMForecast(data = prepared.data)

################################################################################
# PLOT
# Determine size of plot
# Plot to pdf file

# Add small value to all raster pixels so plot is colored correctly
sdm.raster <- sdm.raster + 0.00001

# Determine the geographic extent of our plot
xmin <- extent(sdm.raster)[1]
xmax <- extent(sdm.raster)[2]
ymin <- extent(sdm.raster)[3]
ymax <- extent(sdm.raster)[4]

# Plot the model; save to pdf
plot.file <- paste0(outpath, outprefix, "_single_future_prediction.pdf")
#pdf(file = plot.file, useDingbats = FALSE)

# Load in data for map borders
#data(wrld_simpl)

# Draw the base map
#plot(wrld_simpl, xlim = c(xmin, xmax), ylim = c(ymin, ymax), axes = TRUE, col = "gray95", 
#main = paste0(gsub(pattern = "_", replacement = " ", x = outprefix), " - future"))

# Add the model rasters
#plot(sdm.raster, legend = FALSE, add = TRUE)

# Redraw the borders of the base map
#plot(wrld_simpl, xlim = c(xmin, xmax), ylim = c(ymin, ymax), add = TRUE, border = "gray10", col = NA)

# Add bounding box around map
#box()

# Stop re-direction to PDF graphics device
#dev.off()

plot.file.sdm <- paste0(outpath, outprefix, "_single_future_sdm.jpg")

#Convert sdm.raster to a data frame
# First, to a SpatialPointsDataFrame
sdf <- rasterToPoints(sdm.raster, spatial = TRUE)
# Then to a 'conventional' dataframe
rasterDF  <- data.frame(sdf)

# removes absence data
sdmRasterDF<-rasterDF %>% subset(layer>1)


wrld<-ggplot2::map_data("world", c("mexico", "canada"))

states<-ggplot(prepared.data) +
  geom_tile(data = sdmRasterDF , aes(x = x, y = y), show.legend=FALSE) +  
  geom_point(aes(x=lon, y=lat, color='red'), show.legend=FALSE) +
  borders("state", xlim = c(xmin, xmax), ylim = c(ymin, ymax)) +
  geom_polygon(data=wrld, mapping=aes(x=long, y=lat,group = group), fill = NA, colour = "grey60") +
  scale_size_area() +
  coord_quickmap() +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax))+
  labs(title="Current Species Occurrences with Future Climate SDM Projections", x="Longitude", y="Latitude")

ggsave(plot.file.sdm, states)

# Let user know analysis is done.
message(paste0("\nAnalysis complete. Map image written to ", plot.file, "."))

rm(list = ls())
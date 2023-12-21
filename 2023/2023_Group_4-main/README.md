# Rhyacotriton cascadae Species Distribution Model

[![DOI](https://zenodo.org/badge/595765803.svg)](https://zenodo.org/badge/latestdoi/595765803)

Sydney C, Aubrey W, Finn W, Olivia V

![image](https://user-images.githubusercontent.com/122934743/231263920-2b519bf9-daa4-4c7c-810b-18198fc6d7a3.png)

# Rhyacotriton cascadae

  Rhyacotriton cascadae are small salamanders with a stocky body, a broad head, and large protruding eyes. They also vary highly in color that ranges from brown to olive to tan. Their bellies are usually yellow with black and white dots, and spotted sides. Adult Cascade Torrent salamanders are about two inches long, with sexual dimorphism present with smaller males.  Their larvae have small heads and eyes close to their snout, and look similar to the adults. Cascade torrent salamanders have a lifespan of about 10 years.

  Cascade torrent salamanders have a riparian habitat, and are found in or around permanent streams with fast-flowing, cold water, and steep banks. Rhyacotriton are more likely to be found in mature coniferous forests than younger forest stands and are intolerant to warm weather. Most commonly they are found in headwaters and waterfalls, and the banks of large streams. Usually they stay within a few yards of their home creek or river. The adults occasionally venture into the woods around a creek to feed, but must return to the water to survive. The eggs and larva require the running water to survive and so the range of the salamander is inherently limited to areas where the flow rate is acceptable. They also require loose rocks on the bottom of the creek, not silt bottomed bodies of water.

  The distribution and range of the salamander remains confined to the west coast of the US, remaining in areas around Portland up into the southern half of Washington. No long-term population data exists for the cascade torrent salamander, though it is likely that population has been decreasing. About 51% of the range of these salamanders is located on state and federally owned lands. The main reason for population decreasing is increased air and water temperatures, and changes to the watershed like decreased precipitation and earlier snowmelt. Currently they are under consideration for endangered status.

# Overview

-   Creating Species Occurence Maps and Species Distribution Models for Species Status Assessment of Rhyacotriton cascadae
-   Sydney C, Aubrey W, Finn W, Olivia V GH repo for ADS 2023
-   Completed April, 2023 

# Dependencies The following R packages are required (these will be installed in each file where necessary):
-   raster
-   dismo
-   spocc
-   rJava
-   tidyverse
-   maps
-   maptools 
-  5GB minumum of RAM


# Structure/Data
-   wc2-5: climate data at 2.5 minute resolution from WorldClim (note: this folder is not under version control, but will be created by running the setup script (scr/setup.R))
-   cmip5: forcast climate data at 2.5 minute resolution from WorldClim. The data are for the year 2070, based on the IPSL-CM5A-LR model with an RCP of 4.5 CO2. For an examination of different forecast models, see McSweeney et al. 2015. To choose a different one, see the documentation on WorldClim(note: this folder is not under version control, but will be created by running the currentsdm script (scripts/futuresdm.R))
-   [salamanderData]( from GBIF and iNaturalist for Rhyacotriton cascadae This dataset is not under version control, but will be harvested by running scripts/dataaquisitioncleaning.R.

# Output 

(contents are not under version control)
- [occurancemap.jpeg](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/output/salamanderOccurrence.jpg)
- [currentsdm.jpeg](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/output/salamanderSDMCurrent.jpg)
- [futuresdm.jpeg](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/output/salamanderSDMFuture.jpg)
- [maxent_outputs](output)

# Scripts

Scripts (directory containing R scripts for gathering occurrence data, running forecast models, and creating map outputs)

\* [DataCollection.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/src/DataCollection.R) for obtaining the GBIF data\
\* [SpeciesOccurenceMap.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/output/salamanderOccurrence.jpg) create the occurrence map of the GBIF data\
\* [SDMSalamander.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/src/SDMSalamander.R) to run a maxent model and generate a current sdm\
\* [futureSDM.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/src/futureSDM.R) to generate a future SDM, in 70 years under IP model

# Running the code

Run the scripts in the following order

1\. [DataCollection.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/src/DataCollection.R)

2\. [SpeciesDistributionMap.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/src/SpeciesDistributionMap.R)

3\. [SDMSalamander.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/src/SDMSalamander.R)

4\. [futureSDM.R](https://github.com/BiodiversityDataScienceCorp/2023_Group_4/blob/main/src/futureSDM.R)

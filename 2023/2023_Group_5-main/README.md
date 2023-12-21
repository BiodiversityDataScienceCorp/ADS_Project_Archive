# *Gopherus morafkai* Species Status Assessment

![Photo of Sonoran Desert Tortoise ](https://www.arizonahighways.com/sites/default/files/2022-06/0722_Nature_tortoise.jpg) 

## Overview

-   Lily McMullen
-   Nick Oliver
-   Olivia Spagnuolo
-   Whitney Maxfield

Creating Species Occurrence Maps and Species Distribution Models for Species Status Assessment of *Gopherus morafkai*

*Data accessed 4/11/2023*

## Data 

- wc2-5: Climate data from [WorldClim](https://www.worldclim.org/).
- cmip5: Forecast climate data from [WorldClim](https://www.worldclim.org/).The data are for varying years in the future. Data is based on the  [IPSL-CM5A-LR](https://cmc.ipsl.fr/international-projects/cmip5/) model with an RCP of 4.5 CO2. 
- GBIF: Biodiversity data 


## Dependencies

The following R packages are required: 
- dismo 
- tidyverse 
- rJava 
- maps 
- spocc

## Structure

**How to put our code into your R studio:**

You can either use an R desktop program in which case we recommend you download our project. 
Or, if you are using the online platform posit.cloud, you can follow these steps: 
1. Go to our main GitHub page https://github.com/BiodiversityDataScienceCorp/2023_Group_5
2. Click the green code button 
3. Copy the URL under HTTPS
4. In your posit.cloud workspace, click "New Project", which will bring you to a drop down menu 
5. Click "New project from Git Repository"
6. Paste the link you copied and click "Ok" 
7. You will now have our project in your R workspace and can edit it freely 


*note* increase Ram within R to at least 5 before running

**Within scripts:** 

1. run script titled "dataaquisitioncleaning.R" 
2. run script titled "occurrencemap.R" 
3. run script titled "currentsdm.R" 
4. run script titled "futuresdm.R"

All packages needed are loaded first in "dataaquisitioncleaning.R" meaning there is no need to re-run all packages within each script.

**Moving script from github to R**

Forking Process: <https://docs.github.com/en/get-started/quickstart/fork-a-repo>

**Limitations to our modeling**

We would like to note that this project is constrained by maxent's modeling capabilities as well as the climate data we used which was primarily based on temperature and precipitation.
Since our tortoise requires a very specific habitat, it is hard to know exactly where it will be able to live based only on the climate features we have modeled. 
There are two likely reasons for these constraints: overfitting and temporal issues. 

We may have overfitting, or auto-correlation issues due to spatial sampling and the importance/weight of our covariants. 
Overfitting may come from the way our creatures are observed in space (i.e. the same creature observed twice). To fix this we could try buffering or blocking. 

Additionally, we may temporal issues. That is, we have a large shift when we change from current to future climate, so we may need to weigh the covariants (temperature and precipitation) differently than the current equal weighting. 

We would recommend using cross-validation to help fix environmental covariant issues and determining the weight of the variables. 

[![DOI](https://zenodo.org/badge/595765967.svg)](https://zenodo.org/badge/latestdoi/595765967)


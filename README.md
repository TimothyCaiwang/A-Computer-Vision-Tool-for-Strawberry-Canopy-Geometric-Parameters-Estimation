# A-Computer-Vision-Tool-for-Strawberry-Canopy-Geometric-Parameters-Estimation
**R scripts for strawberry canopy delineation and Python scripts for canopy size metrics calculations.**

Individual strawberry plant detection is a critical step in the calculation of canopy structural parameters. An image processing workflow was established to perform canopy delineation from the UAV multispectral imagery. The input dataset for this workflow consists of four datasets: 
1) Orthomosaic image and DSM generated from raw UAV images using the SfM algorithm;  
2) A shp layer containing a single point that is approximately located at the center of each plant, which can be generated using the UAV images in the early stage.

![image](https://github.com/TimothyCaiwang/A-Computer-Vision-Tool-for-Strawberry-Canopy-Geometric-Parameters-Estimation/assets/41359035/b68135a9-9871-4415-abd6-e1e503b006ff)
Figure 1. Automatic canopy boundary delineation workflow




**Python scripts for strawberry size metrics extraction.**

As proposed in many previous UAS-based studies, the canopy height model (CSM) model can be obtained by subtracting the Digital Terrain Model (DTM) from the DSM, which was calculated as:
CSM = DSM - DTM
 
Combined with the strawberry canopy boundary file, structural parameters (area, volume, mean height, and standard deviation of canopy height) were calculated for each plant from the CSM model. The plant height was extracted as the difference between the 95th and 5th percentiles of CHM elevation values within the canopy boundary.

![image](https://github.com/TimothyCaiwang/A-Computer-Vision-Tool-for-Strawberry-Canopy-Geometric-Parameters-Estimation/assets/41359035/942373d5-afea-4d35-8258-334931e5442b)

Figure 2. Canopy structural parameter estimation workflow

# A-Computer-Vision-Tool-for-Strawberry-Canopy-Geometric-Parameters-Estimation
R scripts for strawberry canopy delineation and Python scripts for canopy size metrics calculations

Individual strawberry plant detection is a critical step in the calculation of canopy structural parameters. An image processing workflow was established to perform canopy delineation from the UAV multispectral imagery. The input dataset for this workflow consists of four datasets: 
1) Orthomosaic image and DSM generated from raw UAV images using the SfM algorithm; 
2) An optional shp layer “Top Bed Boundary” outlining the boundary of strawberry breeding beds.  
3) A shp layer containing a single point that is approximately located at the center of each plant.

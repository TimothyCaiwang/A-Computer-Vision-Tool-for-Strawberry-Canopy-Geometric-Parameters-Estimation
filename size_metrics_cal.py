# -*- coding: utf-8 -*-
"""
Created on Wed Mar 29 22:53:53 2023

@author: caiwangzheng
"""


import csv
import os
import gdal
os.environ['PROJ_LIB'] = r'C:\Users\caiwangzheng\Anaconda3\envs\deep_regression_keras\Lib\site-packages\pyproj'
from rasterstats import zonal_stats

CHM_DIR = '/chm/'
SHP_DIR = '/shp/'
SizeMetrics_DIR = '/size_metrics/'


file_names = os.listdir(CHM_DIR)


for fi in file_names:
    if(fi.endswith('.tif')):
        fi_path = CHM_DIR + fi
        # CHM = gdal.Open(fi_path)
        # CHMi = CHM.GetRasterBand(1).ReadAsArray()
        
        SHPi = SHP_DIR+fi[0:8]+'_ortho_clip_UTM_join.shp'
        size_metrics = zonal_stats(SHPi, fi_path, stats = ['min', 'mean','percentile_1', 'percentile_95', 'max', 'count', 'sum', 'std', ], geojson_out=True)
        csvFile = open(SizeMetrics_DIR+fi[0:8]+'_size_mertics.csv', 'wt')
        chtLength = len(size_metrics)
        
        try:
            writer = csv.writer(csvFile, delimiter=',', lineterminator='\n')
            writer.writerow(('Can_ID','Height_min','Height_max','Height_mean','Area','Volume','Heigh_Std','Height_PC1','Height_PC95'))
            for i in range(0,chtLength):
                writer.writerow((size_metrics[i]['properties'].get('Can_ID'),
                                 size_metrics[i]['properties'].get('min'),
                                 size_metrics[i]['properties'].get('max'),
                                 size_metrics[i]['properties'].get('mean'),
                                 size_metrics[i]['properties'].get('count'),
                                 size_metrics[i]['properties'].get('sum'),
                                 size_metrics[i]['properties'].get('std'),
                                 size_metrics[i]['properties'].get('percentile_1'),
                                 size_metrics[i]['properties'].get('percentile_95'),))
        finally:
            csvFile.close()

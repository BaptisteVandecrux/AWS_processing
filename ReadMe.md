# Weather station processing toolchain

Baptiste Vandecrux
bav@geus.dk

## Reference

These scripts contain the processing steps used for the preparation of the data for the followng studies:

Vandecrux B, Fausto RS, Langen PL, Van As D, MacFerrin M, Colgan WT, Ingeman-Nielsen T, Steffen K, Jensen NS, Møller MT and Box JE (2018) Drivers of Firn Density on the Greenland Ice Sheet Revealed by Weather Station Observations and Modeling. J. Geophys. Res. Earth Surf. 123(10), 2563–2576 (doi:10.1029/2017JF004597)

Vandecrux, B., Fausto, R. S., Box, J.E., van As, D., Colgan, W., Langen, P. L., Haubner, K., Ingeman-Nielsen, T., Heilig,, A., Stevens, C. Max, MacFerrin, M., Niwano, M., Steffen, K.: Firn cold content evolution at nine sites on the Greenland ice sheet since 1998, submitted to Journal of Glaciology


## Description of the scripts
The scripts do:
- Automated filetring of suspicious data
- Manual removal of suspicious data according to the information listed in Input\ErrorData_AllStations.xlsx
- Gap filling of the station data based on secondary datasets, RCM or other AWS, located in Input\Secondary data
- Gap filling the upward shortwave radiation based on remotely sensed albedo grids located in Input\Albedo
- Update and gapfill the instrument height
- Converting observed snow height into continuous surface height time series accounting for the maintenance of the sonic sounders positions listed in the Input\maintenance.xlsx file
- Calculate the thermistor depth based on the measured surface height and on the maintenance reported in Input\maintenance file.
- Convert the surface height increase into snow accumulation at the surface using a list of snow-pit-observed snow water equivalent.
- Output the whole dataset in csv file

=====================================

## Getting the scripts running

1. Download the all scripts from GitHub
2. Download a weather data file from PROMICE and place it in \Input\PROMICE. For exemple: https://promice.org/PromiceDataPortal/api/download/f24019f7-d586-4465-8181-d4965421e6eb/v03/hourly/csv/KAN_M_hour_v03.txt or more generally from https://www.promice.org/PromiceDataPortal/
3. Get the secondary weather data and place it in \Input\Secondary data
4. Get the MODIS albedo grids from https://doi.org/10.22008/promice/data/modis_greenland_albedo and place them in \Input\Albedo. 
5. Get the snow-pit-derived SWE file "Greenland_snow_pit_SWE.xlsx" from bav@geus.dk and place it in the Input folder
6. (optional) for the stations of interest, get a sublimation estimate from a Surface Energy Balance Model and place it in the Input\Sublimation estimates folder. File should be named "<station_name>_sublimation.txt". A SEB model is available at https://github.com/BaptisteVandecrux/SEB_Firn_model

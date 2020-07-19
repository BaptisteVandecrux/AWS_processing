# Weather station processing toolchain

Baptiste Vandecrux
bav@geus.dk

## Reference

These scripts contain the processing steps used for the preparation of the data for the followng studies:

Vandecrux B, Fausto RS, Langen PL, Van As D, MacFerrin M, Colgan WT, Ingeman-Nielsen T, Steffen K, Jensen NS, Møller MT and Box JE (2018) Drivers of Firn Density on the Greenland Ice Sheet Revealed by Weather Station Observations and Modeling. J. Geophys. Res. Earth Surf. 123(10), 2563–2576 (doi:10.1029/2017JF004597)
Useful information about the gap-filling in the Supplementary Material:
https://agupubs.onlinelibrary.wiley.com/action/downloadSupplement?doi=10.1029%2F2017JF004597&file=jgrf20920-sup-0001-2017JF004597-SI.pdf

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


## Getting started
* Download the GitHub repository to your computer
* Download an AWS data file from (PROMICE web site)[https://promice.org/] for example [KAN_M](https://promice.org/PromiceDataPortal/api/download/f24019f7-d586-4465-8181-d4965421e6eb/v03/hourly/csv/KAN_M_hour_v03.txt)
* Place the RCM gap-filling file RACMO_3h_AWS_sites.nc (get from bav@geus.dk) in the Input/Secondary data
* Place the snow pit data file (Greenland_snow_pit_SWE.xlsx, get from bav@geus.dk) in the Input folder
* Place the MODIS albedo file (ALL_YEARS_MOD10A1_C6_500m_d_nn_at_PROMICE_daily_columns_cumulated.txt, get from bav@geus.dk) in the Input/Albedo folder
* (optional) for the stations of interest, get a sublimation estimate from a Surface Energy Balance Model and place it in the Input\Sublimation estimates folder. File should be named "<station_name>_sublimation.txt". A SEB model is available at https://github.com/BaptisteVandecrux/SEB_Firn_model
* Open AWS_DataTreatment.m in Matlab
Change the station code name to process if needed:
```
% select station here
station_list = {'KAN_M'}; 
```
* Run the AWS_DataTreatment.m scripts

## Defining erroneous periods

## Adding maintenance information

## Working on a different time period


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
After running the main script, an overview of the data is saved as "WeatherData_2.pdf". From that plot, the data can be inspected and period of instrument malfunction can be spotted. If we say that we find, for the example, the air pressure suspicious during 2011, we have the possibility to remove it.

For this, open Input/ErrorData_AllStations.xlsx, create a sheet named "KAN_M" and add a line with
AirPressurehPa | 01-01-2011 00:00:00	| 31-12-2011 00:00:00

Save and close. Rerun the AWS_DataTreatment script. The data has now been removed and replaced by RCM data.

The variable names that should be used are:
```
AirPressurehPa	AirPressurehPa_Origin	AirTemperature1C	
AirTemperature1C_Origin	AirTemperature2C	AirTemperature2C_Origin	RelativeHumidity1	
RelativeHumidity1_Origin	RelativeHumidity2	RelativeHumidity2_Origin	WindSpeed1ms	
WindSpeed1ms_Origin	WindSpeed2ms	WindSpeed2ms_Origin	WindDirection1d	WindDirection2d	
ShortwaveRadiationDownWm2	ShortwaveRadiationDownWm2_Origin	ShortwaveRadiationUpWm2	
ShortwaveRadiationUpWm2_Origin	Albedo	LongwaveRadiationDownWm2	
LongwaveRadiationDownWm2_Origin	LongwaveRadiationUpWm2	LongwaveRadiationUpWm2_Origin	
HeightSensorBoomm	HeightStakesm	IceTemperature1C	IceTemperature2C	IceTemperature3C	
IceTemperature4C	IceTemperature5C	IceTemperature6C	IceTemperature7C	
IceTemperature8C	time	HeightWindSpeed1m	HeightWindSpeed2m	HeightTemperature1m	
HeightTemperature2m	HeightHumidity1m	HeightHumidity2m	SurfaceHeightm	Snowfallmweq	
Rainfallmweq	DepthThermistor1m	DepthThermistor2m	DepthThermistor3m	DepthThermistor4m	
DepthThermistor5m	DepthThermistor6m	DepthThermistor7m	DepthThermistor8m
```

## Adding maintenance information
Maintenance information can be used to check that the instrument heights in the data files agree with the manual measurements done manually during maintenance visits.
They also inform the script of the initial depth of ice temperature sensor.
Finally, since the sureface height is calculated from the instrument height, which some times can be moved up or down during maintenance, the maintenance file allows to correct those shifts to reconstruct a continuous surface height.

To enter this information open Input/maintenance.xlsx and create a sheet for "KAN_M".
Copy the header from another sheet and paste it in the current sheet.
The first maintenance is the installation of the station. For KAN_M we can use the first valid day in the data file: 02-09-2008  00:00:00. We can then fill up the next columns with information from maintenance reports or knowledge inferred from other observation. For a start we can give the default values to the ice temperature sensors (NewDepth1..10): from 0.1 to 9.1 with 1 m spacing. The other cells can be left empty.


## Working on a different time period
If the project is focusing on a specific time period, or if you need to restrict the data file to the period when the RCM is available, the processing period can be changed:
In the AWS_DataTreatment script, section "Cropping at defined periods"
Add after "switch station" the following case:
```
        case 'KAN_M'
	    time_start = datenum('02-Sept-2011 00:00:00');
	    time_end = datenum('31-Dec-2017 00:00:00');
```		
Save and re-run, only this period will be processed.

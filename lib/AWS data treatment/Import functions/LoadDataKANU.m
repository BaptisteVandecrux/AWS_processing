function data_KANU = LoadDataKANU(vis,OutputFolder)

filename = 'KAN_U_hour_bapt.txt';
delimiter = '\t';
startRow = 2;

formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
data_KANU = table(dataArray{1:end-1}, 'VariableNames', {'Year','MonthOfYear','DayOfMonth','HourOfDayUTC','DayOfYear','DayOfCentury','AirPressurehPa','AirTemperatureC','AirTemperatureHygroClipC','RelativeHumidity_wrtWater','RelativeHumidity','WindSpeedms','WindDirectiond','ShortwaveRadiationDownWm2','ShortwaveRadiationDown_CorWm2','ShortwaveRadiationUpWm2','ShortwaveRadiationUp_CorWm2','Albedo_theta70d','LongwaveRadiationDownWm2','LongwaveRadiationUpWm2','CloudCover','SurfaceTemperatureC','HeightSensorBoomm','HeightStakesm','DepthPressureTransducerm','DepthPressureTransducer_Corm','IceTemperature1C','IceTemperature2C','IceTemperature3C','IceTemperature4C','IceTemperature5C','IceTemperature6C','IceTemperature7C','IceTemperature8C','TiltToEastd','TiltToNorthd','TimeGPShhmmssUTC','LatitudeGPSddmm','LongitudeGPSddmm','ElevationGPSm','HorDilOfPrecGPS','LoggerTemperatureC','FanCurrentmA','BatteryVoltageV','time','HeightSensorBoomm_raw','SurfaceHeightm','DepthThermistor1m','DepthThermistor2m','DepthThermistor3m','DepthThermistor4m','DepthThermistor5m','DepthThermistor6m','DepthThermistor7m','DepthThermistor8m'});
clearvars filename delimiter startRow formatSpec fileID dataArray ans;
 
    data_KANU.time = datenum(data_KANU.Year,data_KANU.MonthOfYear,data_KANU.DayOfMonth,data_KANU.HourOfDayUTC,0,0);  
    data_KANU.NetRadiationWm2 = data_KANU.ShortwaveRadiationDownWm2...
        - data_KANU.ShortwaveRadiationUpWm2 ...
        + data_KANU.LongwaveRadiationDownWm2 ...
        - data_KANU.LongwaveRadiationUpWm2;

    
    data_KANU.AirTemperature2C = data_KANU.AirTemperatureC;
    data_KANU.AirTemperature1C = NaN *data_KANU.AirTemperature2C;
    data_KANU.AirTemperature3C = NaN *data_KANU.AirTemperature1C;
    data_KANU.AirTemperature4C = NaN *data_KANU.AirTemperature1C;
    data_KANU.RelativeHumidity2Perc = data_KANU.RelativeHumidity;
    data_KANU.RelativeHumidity1Perc = NaN *data_KANU.RelativeHumidity2Perc;
    data_KANU.WindSpeed2ms = data_KANU.WindSpeedms;
    data_KANU.WindSpeed1ms = NaN *data_KANU.WindSpeed2ms;
    data_KANU.WindSensorHeight2m = data_KANU.HeightSensorBoomm_raw + 0.4;
    data_KANU.WindSensorHeight1m = NaN *data_KANU.WindSensorHeight2m;
    data_KANU.TemperatureSensorHeight2m = data_KANU.HeightSensorBoomm_raw - 0.2;
    data_KANU.TemperatureSensorHeight1m = NaN * data_KANU.TemperatureSensorHeight2m;
    data_KANU.HumiditySensorHeight2m = data_KANU.TemperatureSensorHeight2m;
    data_KANU.HumiditySensorHeight1m = NaN *data_KANU.TemperatureSensorHeight2m;
    data_KANU.WindDirection1deg = NaN *data_KANU.WindDirectiond;
    data_KANU.WindDirection2deg = data_KANU.WindDirectiond;
    
    data_KANU.AirPressurehPa(1:end-24) = data_KANU.AirPressurehPa(25:end);
    data_KANU.WindSpeed2ms(1:end-25) = data_KANU.WindSpeed2ms(26:end);
    data_KANU.WindSpeed2ms(end-25:end) = NaN;
    data_KANU.AirTemperature2C(1:end-24) = data_KANU.AirTemperature2C(25:end);
    data_KANU.NetRadiationWm2(1:end-19) = data_KANU.NetRadiationWm2(20:end);
    data_KANU.ShortwaveRadiationDownWm2(1:end-23) = data_KANU.ShortwaveRadiationDownWm2(24:end);
    data_KANU.ShortwaveRadiationDownWm2(end-23:end) = NaN;
    ind_nan = and(data_KANU.time<datenum('31-dec-2012'),data_KANU.time>datenum('01-jan-2012'));
    data_KANU.ShortwaveRadiationDownWm2(ind_nan) = NaN;
    ind_nan = and(data_KANU.time>datenum('30-Dec-2011 07:00:00'),...
        data_KANU.time<datenum('24-Jul-2012 08:00:00'));
    data_KANU.WindSpeed2ms(ind_nan) = NaN;

    data_KANU = TreatAndFilterData(data_KANU,'','KAN_U',OutputFolder,vis);
end
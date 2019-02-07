
function data_KANUbabis = LoadDataKANUbabis()
        filename = 'KAN_U_babis.csv';
        delimiter = ';';
        startRow = 2;
        formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
        fclose(fileID);
        data_KANUbabis = table(dataArray{1:end-1}, 'VariableNames', ...
            {'Year','MonthOfYear','DayOfMonth','HourOfDayUTC','DayOfYear',...
            'DayOfCentury','AirPressurehPa','AirTemperature1C',...
            'RelativeHumidity1Perc','WindSpeed1ms','WindDirectiond',...
            'ShortwaveRadiationDownWm2','ShortwaveRadiationUpWm2',...
            'LongwaveRadiationDownWm2','LongwaveRadiationUpWm2',...
            'WindSensorHeight1m','StakeHeight2m','ValidationHeightm',...
            'TiceInterp1mdepthC','TiceInterp2mdepthC','TiceInterp3mdepthC',...
            'TiceInterp4mdepthC','TiceInterp5mdepthC','TiceInterp6mdepthC',...
            'TiceInterp7mdepthC','TiceInterp8mdepthC'});
        clearvars filename delimiter startRow formatSpec fileID dataArray ans;

        data_KANUbabis.time = datenum(data_KANUbabis.Year,data_KANUbabis.MonthOfYear,...
            data_KANUbabis.DayOfMonth,data_KANUbabis.HourOfDayUTC,0,0);

data_KANUbabis.RelativeHumidity1Perc = RHwater2ice(data_KANUbabis.RelativeHumidity1Perc,...
    data_KANUbabis.AirTemperature1C+273.15, data_KANUbabis.AirPressurehPa);

    data_KANUbabis.NetRadiationWm2 = data_KANUbabis.ShortwaveRadiationDownWm2...
        - data_KANUbabis.ShortwaveRadiationUpWm2 ...
        + data_KANUbabis.LongwaveRadiationDownWm2 ...
        - data_KANUbabis.LongwaveRadiationUpWm2;   
       
    data_KANUbabis.AirTemperature2C = data_KANUbabis.AirTemperature1C;
    data_KANUbabis.AirTemperature3C = data_KANUbabis.AirTemperature1C;
    data_KANUbabis.AirTemperature4C = data_KANUbabis.AirTemperature1C;
    
    data_KANUbabis.RelativeHumidity2Perc = data_KANUbabis.RelativeHumidity1Perc;
    data_KANUbabis.WindSpeed2ms = data_KANUbabis.WindSpeed1ms;
    data_KANUbabis.WindDirection1deg = data_KANUbabis.WindDirectiond;
    data_KANUbabis.WindDirection2deg = data_KANUbabis.WindDirectiond;
    
    data_KANUbabis.TemperatureSensorHeight1m = data_KANUbabis.WindSensorHeight1m-0.1;
    data_KANUbabis.TemperatureSensorHeight2m = data_KANUbabis.WindSensorHeight1m-0.1;
    data_KANUbabis.HumiditySensorHeight1m = data_KANUbabis.WindSensorHeight1m-0.1;
    data_KANUbabis.HumiditySensorHeight2m = data_KANUbabis.WindSensorHeight1m-0.1;
    data_KANUbabis.WindSensorHeight1m =data_KANUbabis.WindSensorHeight1m+0.4;
    data_KANUbabis.WindSensorHeight2m = data_KANUbabis.WindSensorHeight1m;

        data_KANUbabis.SnowHeight1m = data_KANUbabis.ValidationHeightm;
    data_KANUbabis.SnowHeight2m = data_KANUbabis.ValidationHeightm;


end
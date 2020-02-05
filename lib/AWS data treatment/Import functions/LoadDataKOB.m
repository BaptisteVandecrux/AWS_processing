function [data_KOB] = LoadDataKOB(OutputFolder,vis)
    filename = '.\Input\Secondary data\KOB_station.txt';
    delimiter = '\t';
    startRow = 2;

    formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(fileID);
    data_KOB = table(dataArray{1:end-1}, 'VariableNames', ...
        {'Year','MonthOfYear','DayOfMonth','HourOfDayUTC','DayOfYear',...
        'DayOfCentury','AirPressurehPa','AirTemperature1C',...
        'RelativeHumidity1Perc','WindSpeed1ms','WindDirectiond',...
        'ShortwaveRadiationDownWm2','ShortwaveRadiationUpWm2',...
        'LongwaveRadiationDownWm2','LongwaveRadiationUpWm2'});
    clearvars filename delimiter startRow formatSpec fileID dataArray ans;
    
     data_KOB.time = datenum(data_KOB.Year,data_KOB.MonthOfYear,...
                        data_KOB.DayOfMonth,data_KOB.HourOfDayUTC,0,0);
        data_KOB = standardizeMissing(data_KOB,-999);
%     data_KOB.RelativeHumidity1Perc = RHwater2ice(data_KOB.RelativeHumidity1Perc,...
%                 data_KOB.AirTemperature1C+273.15, data_KOB.AirPressurehPa);
       
    data_KOB.AirTemperature2C = data_KOB.AirTemperature1C;
    data_KOB.AirTemperature3C = data_KOB.AirTemperature1C;
    data_KOB.AirTemperature4C = data_KOB.AirTemperature1C;

    data_KOB.RelativeHumidity2Perc = data_KOB.RelativeHumidity1Perc;
    data_KOB.WindSpeed2ms = data_KOB.WindSpeed1ms;
    data_KOB.WindDirection1deg = data_KOB.WindDirectiond;
    data_KOB.WindDirection2deg = data_KOB.WindDirectiond;
    data_KOB.WindSensorHeight1m = 2*ones(size(data_KOB.RelativeHumidity1Perc));
    data_KOB.TemperatureSensorHeight1m = data_KOB.WindSensorHeight1m;
    data_KOB.TemperatureSensorHeight2m = data_KOB.WindSensorHeight1m;
    data_KOB.HumiditySensorHeight1m = data_KOB.WindSensorHeight1m;
    data_KOB.HumiditySensorHeight2m = data_KOB.WindSensorHeight1m;
    data_KOB.WindSensorHeight2m = data_KOB.WindSensorHeight1m;  
    ind = data_KOB.time<= datenum('31-Dec-2015 24:00:00');

        data_KOB.WindSpeed1ms(ind) = NaN;
    data_KOB.WindSpeed2ms(ind) = NaN;
    data_KOB.RelativeHumidity1Perc(ind) = NaN;
    data_KOB.RelativeHumidity2Perc(ind) = NaN;
    
    data_KOB = TreatAndFilterData(data_KOB,'','KOB',OutputFolder,vis);

end

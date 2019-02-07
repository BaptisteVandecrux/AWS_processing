function data = ImportIMAUfile()

list_dir = dir('./IMAU_raw/txt');
file_list = {list_dir.name};
file_list(1:2) = [];
data = table;
for i=1:length(file_list)
    filename= strcat('./IMAU_raw/txt/',file_list{i});
    
    delimiter = '\t';
    startRow = 5;
    endRow = inf;

    formatSpec = '%f%q%q%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%q%f%f%f%f%f%f%f%f%f%f%f%f%f%q%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
    for block=2:length(startRow)
        frewind(fileID);
        dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
        for col=1:length(dataArray)
            dataArray{col} = [dataArray{col};dataArrayBlock{col}];
        end
    end
    fclose(fileID);

    data = [data;...
        table(dataArray{1:end-1}, 'VariableNames', ...
        {'ID','DATE','TIME','AirTemperature3C','TC1std','AirTemperature1C','TC2std','CJavg',...
        'IceTemperature1C','IceTemperature2C','IceTemperature3C',...
        'IceTemperature4C','IceTemperature5C','IceTemperature6C',...
        'IceTemperature7C','IceTemperature8C',...
        'THUTavg','RelativeHumidity1Perc','RHTavg','WindSpeed1ms','HWSstd','HWSmax','WindDirection1deg',...
        'VWSavg','VWSstd','ShortwaveRadiationDownWm2','NRUstd','ShortwaveRadiationUpWm2','LongwaveRadiationDownWm2','LongwaveRadiationUpWm2',...
        'NRTavg','NRUcal','NRLcal','NRIUcal','NRILcal','NRID','AirPressurehPa','HeightSensorBoomm',...
        'ADW','TBRG','MCH','TiltToEastd','TiltToNorthd','LongitudeGPSdegW','LatitudeGPSdegN','ElevationGPSm','PACC',...
        'SATS','SPARE1','SPARE2','VBBatteryVoltageVAT','LBUT','STATUS','xID','xTC1avg',...
        'xTC2avg','xCJavg','xTHUTavg','xRHWavg','xRHTavg','xHWSavg',...
        'xHWDavg','xVWSavg','xSSH','xSPARE1','xVBAT','xSTATUS'})];
end

ind_remove = [1 5 7 8 17 19 21 22 24 25 27 31:36 39  40 41 47:50 52:67];
data(:,ind_remove) = [];
time= datetime(2000,2,NaN(size(data,1),1));
% data.DATE(1:end-1) = data.DATE(2:end);
time = datetime([char(data.DATE),repmat(' ',size(data.DATE)),char(data.TIME)],...
    'Format','yyyy-MM-dd hh:mm');
time(find(time(2:end) - time(1:end-1)==duration(-24,30,0))+1) = ...
    time(find(time(2:end) - time(1:end-1)==duration(-24,30,0)))+duration(0,30,0);
data.Year = time.Year;
data.MonthOfYear = time.Month;
data.DayOfMonth = time.Day;
data.RelativeHumidity2Perc = data.RelativeHumidity1Perc;
data.AirTemperature2C = data.AirTemperature1C;
data.AirTemperature4C = data.AirTemperature3C;
data.WindSpeed2ms = data.WindSpeed1ms;
data.WindSensorHeight1m = data.HeightSensorBoomm;
data.WindSensorHeight2m = data.HeightSensorBoomm;
data.TemperatureSensorHeight1m = data.HeightSensorBoomm;
data.TemperatureSensorHeight2m = data.HeightSensorBoomm;
data.HumiditySensorHeight1m = data.HeightSensorBoomm;
data.HumiditySensorHeight2m = data.HeightSensorBoomm;
data.WindDirection2deg = data.WindDirection1deg;
data.SnowHeight1m = data.HeightSensorBoomm(1) - data.HeightSensorBoomm;
data.SnowHeight2m = data.HeightSensorBoomm(1) - data.HeightSensorBoomm;
data.HourOfDayUTC = time.Hour+time.Minute/60;
data.DayOfCentury = nan(size(time));
data.HeightStakesm = nan(size(time));
data.time = datenum(time);
data(:,1:2) = [];
data([11461 14873],:)=[];
% data = data(1728:14425,:);
data.HeightSensorBoomm = data.HeightSensorBoomm*10;
end


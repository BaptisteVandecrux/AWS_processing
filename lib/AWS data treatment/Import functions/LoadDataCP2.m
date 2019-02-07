function data_CP2 = LoadDataCP2(vis,OutputFolder)
    %Loading variable list
    filename = 'Input/GCnet/CP2.txt';
    startRow = 2;
    endRow = 35;
    formatSpec = '%2f%48s%[^\n\r]';
    fileID = fopen(filename,'r');

    textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);
    dataArray{2} = strtrim(dataArray{2});
    fclose(fileID);
    FieldNumber = dataArray{:, 1};
    FieldNames = dataArray{:, 2};
    clearvars startRow endRow formatSpec fileID dataArray ans;

    for i = 1:length(FieldNames)
        FieldNames{i} = strrep(FieldNames{i},' ','_');
    end

    delimiter = ' ';
    startRow = 36;
    formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
    fileID = fopen(filename,'r');

    textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN,'ReturnOnError', false);
    fclose(fileID);

    data_CP2 = table(dataArray{1:end-1}, 'VariableNames', ...
    {'StationName', 'Year', 'JulianTime', 'ShortwaveRadiationDownWm2',...
        'ShortwaveRadiationUpWm2','NetRadiationWm2', 'AirTemperature1C',...
        'AirTemperature2C', 'AirTemperature3C', 'AirTemperature4C',...
        'RelativeHumidity1Perc','RelativeHumidity2Perc',...
        'WindSpeed1ms','WindSpeed2ms','WindDirection1deg','WindDirection2deg',...
        'AirPressurehPa','SnowHeight1m','SnowHeight2m','IceTemperature1C',...
        'IceTemperature2C','IceTemperature3C','IceTemperature4C','IceTemperature5C',...
        'IceTemperature6C','IceTemperature7C','IceTemperature8C','IceTemperature9C',...
        'IceTemperature10C', 'WindSpeed2mms', 'WindSpeed10mms','WindSensorHeight1m',...
        'WindSensorHeight2m', 'ZenithAngledeg'});
    clearvars  delimiter startRow formatSpec fileID dataArray ans;

    data_CP2.time = datenum(data_CP2.Year,0,data_CP2.JulianTime);
    time_2 = datevec(data_CP2.time);
    data_CP2.MonthOfTheYear = time_2(:,2);
    data_CP2.DayOfTheMonth = time_2(:,3);
    data_CP2.HourOfTheDay = time_2(:,4);
    data_CP2.DayOfTheYear = data_CP2.JulianTime;
    clearvars time_2
    % removing erroneous data
    data_CP2.RelativeHumidity2Perc(15748:15774)=NaN;
    
    % Creating other heights
    data_CP2.TemperatureSensorHeight1m = data_CP2.WindSensorHeight1m;
    data_CP2.TemperatureSensorHeight2m = data_CP2.WindSensorHeight2m;
    data_CP2.HumiditySensorHeight1m = data_CP2.WindSensorHeight1m;
    data_CP2.HumiditySensorHeight2m = data_CP2.WindSensorHeight2m;
    
    % Dealing with the missing instrument heights
    % sometimes snow height is available and not sensor height
    % for those period we recalculate sensor height based on a guess of the
    % initial height and on the variation in snow height. We also assume that
    % the tower is raised every documented visit

    maintenance = ImportMaintenanceFile('CP2');

    h1 = 3 - data_CP2. SnowHeight1m;
    h2 = 4.2 - data_CP2. SnowHeight1m;

    for i=1:size(maintenance,1)
        [~,ind] = min(abs(data_CP2.time-datenum(maintenance.date(i))));
        if ~strcmp(maintenance.reported(i),'y')
            continue
        end

        h1(ind:end) = 4 - data_CP2. SnowHeight1m(ind:end)+data_CP2. SnowHeight1m(ind);
        h2(ind:end) = 5.2 - data_CP2. SnowHeight1m(ind:end)+data_CP2. SnowHeight1m(ind);
    end
    % figure
    % hold on 
    % plot(h1)
    % plot(h2)

    ind1 = and( isnan(data_CP2.WindSensorHeight1m), ~isnan(data_CP2.SnowHeight1m));
    data_CP2.WindSensorHeight1m(ind1) = h1(ind1);
    ind2 = and( isnan(data_CP2.WindSensorHeight2m), ~isnan(data_CP2.SnowHeight2m));
    data_CP2.WindSensorHeight1m(ind2) = h1(ind2);

%     figure
% subplot(2,1,1)
% plot(data.time,h1)
% plot(data.time,data.WindSensorHeight1m)
% subplot(2,1,2)
% plot(data.time,h1)
% plot(data.time,data.WindSensorHeight1m)
% legend('reconstructed','available')

% Creating other heights
data_CP2.TemperatureSensorHeight1m = data_CP2.WindSensorHeight1m;
data_CP2.TemperatureSensorHeight2m = data_CP2.WindSensorHeight2m;
data_CP2.HumiditySensorHeight1m = data_CP2.WindSensorHeight1m;
data_CP2.HumiditySensorHeight2m = data_CP2.WindSensorHeight2m;

    data_CP2 = TreatAndFilterData(data_CP2,'','CP2',OutputFolder,vis);
end
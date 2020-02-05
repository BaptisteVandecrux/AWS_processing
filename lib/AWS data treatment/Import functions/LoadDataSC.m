function data_SC = LoadDataSC(vis,OutputFolder)
 %Loading variable list
    filename = './Input/GCnet/Additional files/SwissCamp2.txt';
    startRow = 2;
    endRow = 35;
    formatSpec = '%2f%48s%[^\n\r]';
    fileID = fopen(filename,'r');

    textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);
    dataArray{2} = strtrim(dataArray{2});
    fclose(fileID);
    FieldNames = dataArray{:, 2};
    clearvars startRow endRow formatSpec fileID dataArray ans;

    for i = 1:length(FieldNames)
        FieldNames{i} = strrep(FieldNames{i},' ','_');
    end

    delimiter = '\t';
    startRow = 36;
    formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
    fileID = fopen(filename,'r');

    textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN,'ReturnOnError', false);
    fclose(fileID);

    data_SC = table(dataArray{1:end-1}, 'VariableNames', ...
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

    data_SC.time = datenum(data_SC.Year,0,data_SC.JulianTime);
    time_2 = datevec(data_SC.time);
    data_SC.MonthOfTheYear = time_2(:,2);
    data_SC.DayOfTheMonth = time_2(:,3);
    data_SC.HourOfTheDay = time_2(:,4);
    data_SC.DayOfTheYear = floor(data_SC.JulianTime)+1;
    clearvars time_2
    % Removing erroneous data
    ind = and(data_SC.time>datenum('11-Jul-2010 17:00:00'),...
    data_SC.time<datenum('18-May-2011 15:00:00'));
    data_SC.ShortwaveRadiationUpWm2(ind) = NaN;
    
    ind = and(data_SC.time>datenum('26-Jul-2011 17:00:00'),...
    data_SC.time<datenum('09-May-2012 16:00:00'));
    data_SC.ShortwaveRadiationUpWm2(ind) = NaN;
    
    ind = and(data_SC.time>datenum('05-Jun-1999 12:00:00'),...
    data_SC.time<datenum('07-Jun-1999 09:00:00'));
    data_SC.AirPressurehPa(ind) = NaN;

    data_SC.AirPressurehPa(30090:30110)=NaN;
    data_SC.ShortwaveRadiationUpWm2(126795:136585)=NaN;
    data_SC.ShortwaveRadiationDownWm2(131665:143137)=NaN;
    data_SC.ShortwaveRadiationDownWm2(76201:81865)=NaN;
    data_SC.ShortwaveRadiationUpWm2(76201:81865)=NaN;
    data_SC.WindSpeed2mms(132494:134778)=NaN;
        
    % Dealing with the missing instrument heights
    % sometimes snow height is available and not sensor height
    % for those period we recalculate sensor height based on a guess of the
    % initial height and on the variation in snow height. We also assume that
    % the tower is raised every documented visit

%     maintenance = ImportMaintenanceFile('SwissCamp');
% 
%     h1 = 3 - data_SC. SnowHeight1m;
%     h2 = 4.2 - data_SC. SnowHeight1m;
% 
%     for i=1:size(maintenance,1)
%         [~,ind] = min(abs(data_SC.time-datenum(maintenance.date(i))));
%         if ~strcmp(maintenance.reported(i),'y')
%             continue
%         end
% 
%         h1(ind:end) = 4 - data_SC. SnowHeight1m(ind:end)+data_SC. SnowHeight1m(ind);
%         h2(ind:end) = 5.2 - data_SC. SnowHeight1m(ind:end)+data_SC. SnowHeight1m(ind);
%     end
    % figure
    % hold on 
    % plot(h1)
    % plot(h2)

%     ind1 = and( isnan(data_SC.WindSensorHeight1m), ~isnan(data_SC.SnowHeight1m));
%     data_SC.WindSensorHeight1m(ind1) = h1(ind1);
%     ind2 = and( isnan(data_SC.WindSensorHeight2m), ~isnan(data_SC.SnowHeight2m));
%     data_SC.WindSensorHeight2m(ind2) = h1(ind2);
% figure
% subplot(2,1,1)
% plot(data.time,h1)
% plot(data.time,data.WindSensorHeight1m)
% subplot(2,1,2)
% plot(data.time,h1)
% plot(data.time,data.WindSensorHeight1m)
% legend('reconstructed','available')

% Creating other heights
data_SC.TemperatureSensorHeight1m = data_SC.WindSensorHeight1m;
data_SC.TemperatureSensorHeight2m = data_SC.WindSensorHeight2m;
data_SC.HumiditySensorHeight1m = data_SC.WindSensorHeight1m;
data_SC.HumiditySensorHeight2m = data_SC.WindSensorHeight2m;

    ind = and(data_SC.time>datenum('30-Apr-2012 02:00:00'),...
        data_SC.time<datenum('14-May-2012 03:00:00'));
    data_SC.ShortwaveRadiationDownWm2(ind) = NaN;  

    ind = and(data_SC.time>datenum('01-Jun-2004 02:00:00'),...
        data_SC.time<datenum('01-Dec-2004 03:00:00'));
    data_SC.ShortwaveRadiationDownWm2(ind) = NaN;  
maintenance = ImportMaintenanceFile('SwissCamp');

    % filtering and processing   
    data_SC = TreatAndFilterData(data_SC,'','SwissCamp',OutputFolder,vis);
end

function [data] = ImportGCnetData(station)

%% Loading GCnet metadata

filename = '.\Input\GCnet\Gc-net_documentation_Nov_10_2000.csv';
delimiter = ';';
startRow = 2;
formatSpec = '%s%s%s%s%s%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);

raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,3,4,5]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\.]*)+[\,]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\.]*)*[\,]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers=='.');
                thousandsRegExp = '^\d+?(\.\d{3})*\,{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, '.', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = strrep(numbers, '.', '');
                numbers = strrep(numbers, ',', '.');
                numbers = textscan(numbers, '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

rawNumericColumns = raw(:, [1,3,4,5]);
rawCellColumns = raw(:, 2);

R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

overview = table;
overview.ID = cell2mat(rawNumericColumns(:, 1));
overview.StationName = rawCellColumns(:, 1);
overview.Northing = cell2mat(rawNumericColumns(:, 2));
overview.Easting = cell2mat(rawNumericColumns(:, 3));
overview.Elevation = cell2mat(rawNumericColumns(:, 4));

clearvars delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;

%% finding station ID
switch station
    case 'CP1'
        station_num = find(strcmp('Crawford Pt.',overview.StationName));
    case 'SouthDome'    
        station_num = find(strcmp('South Dome',overview.StationName));
    case 'NEEM'    
        station_num = 23;
    otherwise
        station_num = find(strcmp(station,overview.StationName));
end

filename = dir(sprintf('./Input/GCnet/20190501/%02i*',station_num));
% filename = sprintf('./Input/GCnet/10102018/%s.txt',station);
if size(filename,1) == 0
    error('No data file found.')
elseif size(filename,1) >1
    error('Several data files found.')
end
filename =filename.name;

%% detecting length of header
% tic
formatSpec = '%s%[^\n\r]';
fileID = fopen(filename,'r');
    temp = 0;

for Row = 1:60
    dataArray = textscan(fileID, formatSpec, 1, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);
    test = dataArray{1, 1}{1};

    if ~ismember(test(1), '0123456789')
        continue
    else
%             disp(test)

        if str2num(strtrim(test(1:2))) == temp +1
            temp = temp+1;
            continue
        else
%             disp(temp)
            break
        end
    end
end
fclose(fileID);
clearvars endRow formatSpec fileID dataArray ans;
endRow_header = temp +1;
num_var  = temp;
% toc
%%
startRow = 1;

formatSpec = '%s%[^\n\r]';
fileID = fopen(filename,'r');
textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow_header-startRow+1, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);
dataArray{2} = strtrim(dataArray{2});
fclose(fileID);
FieldNumber = dataArray{:, 1};
FieldNames = dataArray{:, 2};
clearvars startRow formatSpec fileID dataArray ans;

for i = 1:length(FieldNames)
    FieldNames{i} = strrep(FieldNames{i},' ','_');
end

% now extracting the data
delimiter = ' ';
startRow = endRow_header+1;
formatSpec = strcat(repmat('%f',1,endRow_header-1), '%[^\n\r]');
fileID = fopen(filename,'r');

textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN,'ReturnOnError', false);
fclose(fileID);

switch num_var
    case 35
    list_var = {'StationName', 'Year', 'JulianTime', 'ShortwaveRadiationDownWm2',...
    'ShortwaveRadiationUpWm2','NetRadiationWm2', 'AirTemperature1C',...
    'AirTemperature2C', 'AirTemperature3C', 'AirTemperature4C',...
    'RelativeHumidity1Perc','RelativeHumidity2Perc',...
    'WindSpeed1ms','WindSpeed2ms','WindDirection1deg','WindDirection2deg',...
    'AirPressurehPa','SnowHeight1m','SnowHeight2m','IceTemperature1C',...
    'IceTemperature2C','IceTemperature3C','IceTemperature4C','IceTemperature5C',...
    'IceTemperature6C','IceTemperature7C','IceTemperature8C','IceTemperature9C',...
    'IceTemperature10C', 'WindSpeed2mms', 'WindSpeed10mms','WindSensorHeight1m',...
    'WindSensorHeight2m', 'ZenithAngledeg'};
    case 51
    list_var = {'StationName', 'Year', 'JulianTime', 'ShortwaveRadiationDownWm2',...
    'ShortwaveRadiationUpWm2','NetRadiationWm2', 'AirTemperature1C',...
    'AirTemperature2C', 'AirTemperature3C', 'AirTemperature4C',...
    'RelativeHumidity1Perc','RelativeHumidity2Perc',...
    'WindSpeed1ms','WindSpeed2ms','WindDirection1deg','WindDirection2deg',...
    'AirPressurehPa','SnowHeight1m','SnowHeight2m','IceTemperature1C',...
    'IceTemperature2C','IceTemperature3C','IceTemperature4C','IceTemperature5C',...
    'IceTemperature6C','IceTemperature7C','IceTemperature8C','IceTemperature9C',...
    'IceTemperature10C','BatteryVoltageV','aux1Wm2','aux2Wm2','NetRadMaxWm',...
    'MaxAirTemperture1degC','MaxAirTemperture2degC','MinAirTemperture1degC',...
    'MinAirTemperture2degC', 'MaxWindspeed1ms', 'MaxWindspeed2ms', ...
    'StdDevWindspeed1ms', 'StdDevWindspeed2ms', 'RefTemperaturedegC',...
    'Windspeed2mms', 'Windspeed10mms', 'WindSensorHeight1m', ...
    'WindSensorHeight2m', 'Albedo', 'ZenithAngledeg', 'QCl01_08',...
    'QCl09_16', 'QCl25_27'};
    case 52
    list_var = {'StationName', 'Year', 'JulianTime', 'ShortwaveRadiationDownWm2',...
    'ShortwaveRadiationUpWm2','NetRadiationWm2', 'AirTemperature1C',...
    'AirTemperature2C', 'AirTemperature3C', 'AirTemperature4C',...
    'RelativeHumidity1Perc','RelativeHumidity2Perc',...
    'WindSpeed1ms','WindSpeed2ms','WindDirection1deg','WindDirection2deg',...
    'AirPressurehPa','SnowHeight1m','SnowHeight2m','IceTemperature1C',...
    'IceTemperature2C','IceTemperature3C','IceTemperature4C','IceTemperature5C',...
    'IceTemperature6C','IceTemperature7C','IceTemperature8C','IceTemperature9C',...
    'IceTemperature10C','BatteryVoltageV','aux1Wm2','aux2Wm2','NetRadMaxWm',...
    'MaxAirTemperture1degC','MaxAirTemperture2degC','MinAirTemperture1degC',...
    'MinAirTemperture2degC', 'MaxWindspeed1ms', 'MaxWindspeed2ms', ...
    'StdDevWindspeed1ms', 'StdDevWindspeed2ms', 'RefTemperaturedegC',...
    'Windspeed2mms', 'Windspeed10mms', 'WindSensorHeight1m', ...
    'WindSensorHeight2m', 'Albedo', 'ZenithAngledeg', 'QCl01_08',...
    'QCl09_16', 'QCl17_24', 'QCl25_27'};
    otherwise
        error('Wrong variable list for %s.',station)
end

% renaming the fields according to the PROMICE standards
data = table(dataArray{1:end-1}, 'VariableNames', list_var);

clearvars  delimiter startRow formatSpec fileID dataArray ans;
data = standardizeMissing(data,999);
data(165000:end,:) = [];
data.time = datenum(data.Year,0,data.JulianTime+1);

ind_remove = find(data.time(2:end)-data.time(1:end-1)<=0);
% disp('Duplicate timesteps:')
% disp(ind_remove)
data(ind_remove,:)=[];

   

% calculating some extra fields
time_2 = datevec(data.time);
data.MonthOfTheYear = time_2(:,2);
data.DayOfTheMonth = time_2(:,3);
data.HourOfTheDay = time_2(:,4);
data.DayOfTheYear = floor(data.JulianTime+1);
data.JulianTime = floor(data.JulianTime)+ data.HourOfTheDay/24;
clearvars time_2


%% Extra files from CP1
    if strcmp(station,'CP1')
    
        % Loading first annexe data file
        % The data file that was released by K. Steffen did not contain part of
        % the data. The missing period was communicated later in an 'annex'
        % file. Here we upload it and merge it with the main dataset for CP1.
        data_2 = LoadExtraFileCP1();
        data_new = table;
        data_new.time = unique(union(data.time,data_2.time));
        clearvars ind_neg ind_pos ind_error time_diff temp ind_ok ind_uni
        %     f = figure('Visible',vis);
        %     ha = tight_subplot(6,1,0.01, [.07 .03], 0.05);
        %     count = 1;
            for i = 1:size(data,2)
        %         if ismember(i,5:35) &&  sum(strcmp((data.Properties.VariableNames{i}),data_2.Properties.VariableNames))>0
        %             if count <= 6
        %                 axes(ha(count))
        %             else
        %                 datetick('x','yyyy','keeplimits','keepticks')
        %                 legend('additional data','shifted in time','old data')
        %     %             print(f,sprintf('fig_1_%i',i),'-dpdf')
        %                 f = figure;
        %                 ha = tight_subplot(6,1,0.01, [.07 .03], 0.05);
        %                 count = 1;
        %                 axes(ha(count))
        %             end
        % 
        %             hold on
        %             scatter(data_2.time,data_2.(data.Properties.VariableNames{i}))
        %             plot(data.time,data.(data.Properties.VariableNames{i}))
        %             axis tight
        %             set(gca,'XMinorTick','on')
        %             if count == 6
        %                 set(gca,'XTickLabel',[])
        %             end
        %             if count/2 ==floor(count/2)
        %                 set(gca,'YAxisLocation','right')
        %             end
        %             ylabel(data.Properties.VariableNames{i})
        %             set_monthly_tick(time_2);
        %             xlim([data_2.time(1) data_2.time(end)])
        %             count = count +1;
        %         end
                if and(~strcmp('time',data.Properties.VariableNames{i}),...
                        isempty(strfind(data.Properties.VariableNames{i},'Origin')))
                    ind_1 = ismember(data_new.time, data.time);
                    data_new.(data.Properties.VariableNames{i}) = NaN(size(data_new.time));
                    data_new.(data.Properties.VariableNames{i})(ind_1) = data.(data.Properties.VariableNames{i});
                    if sum(strcmp((data.Properties.VariableNames{i}),data_2.Properties.VariableNames))>0
                        ind_2 = ismember(data_new.time, data_2.time);
                        data_new.(data.Properties.VariableNames{i})(ind_2) = data_2.(data.Properties.VariableNames{i});
                    end
                end
            end

        %     datetick('x','yyyy','keeplimits','keepticks')
        %     legend('additional data','old data')
        %     print(f,sprintf('fig_1_%i',i),'-dpdf')

        data = data_new;
        clearvars data_2 data_new ind_1 ind_2 time_2
    end
    
%% Dealing with the missing instrument heights
% sometimes snow height is available and not sensor height
% for those period we recalculate sensor height based on a guess of the
% initial height and on the variation in snow height. We also assume that
% the tower is raised every documented visit


% h1 = 3 - data. SnowHeight1m;
% h2 = 4.2 - data. SnowHeight2m;
% 
% for i=1:size(maintenance,1)
%     [~,ind] = min(abs(data.time-datenum(maintenance.date(i))));
%     if ~strcmp(maintenance.reported(i),'y')
%         continue
%     end
% 
%     h1(ind:end) = 4 - data. SnowHeight1m(ind:end)+data. SnowHeight1m(ind);
%     h2(ind:end) = 5.2 - data. SnowHeight2m(ind:end)+data. SnowHeight2m(ind);
% end
% % figure
% % hold on 
% % plot(h1)
% % plot(h2)
% 
% ind1 = and( isnan(data.WindSensorHeight1m), ~isnan(data.SnowHeight1m));
% data.WindSensorHeight1m(ind1) = h1(ind1);
% ind2 = and( isnan(data.WindSensorHeight2m), ~isnan(data.SnowHeight2m));
% data.WindSensorHeight1m(ind2) = h1(ind2);

% figure
% subplot(2,1,1)
% plot(data.time,h1)
% plot(data.time,data.WindSensorHeight1m)
% subplot(2,1,2)
% plot(data.time,h1)
% plot(data.time,data.WindSensorHeight1m)
% legend('reconstructed','available')

% Creating other heights
data.TemperatureSensorHeight1m = data.WindSensorHeight1m;
data.TemperatureSensorHeight2m = data.WindSensorHeight2m;
data.HumiditySensorHeight1m = data.WindSensorHeight1m;
data.HumiditySensorHeight2m = data.WindSensorHeight2m;

% figure
% plot(data.WindSpeed1ms)
% hold on
% plot(data.WindSpeed2ms)
% plot((data.WindSpeed1ms>data.WindSpeed2ms)*10)
% figure
% scatter(data.WindSpeed1ms,data.WindSpeed2ms)
% ylimit=get(gca,'Ylim');
% hold on 
% Plotlm(data.WindSpeed1ms,data.WindSpeed2ms)
% plot(ylimit,ylimit,'--k')
% 
% legend('1','2')

end
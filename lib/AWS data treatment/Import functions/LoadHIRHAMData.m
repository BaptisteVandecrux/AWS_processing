function [data_HIRHAM] = LoadHIRHAMData(station)
if strcmp(station,'IMAU')
    station = 'TAS_A';
end
    filename = sprintf('./Input/HIRHAM/HIRHAM_GL2_%s_1981_2014.txt',station);
    delimiter = ',';
    formatSpec = '%f%f%f%f%f%f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fileID);
    data_HIRHAM_old = table(dataArray{1:end-1}, 'VariableNames', ...
        {'tas', 'ps', 'relhum', 'dswrad', 'dlwrad', 'wind10','time'});
    clearvars filename delimiter formatSpec fileID dataArray ans;
    data_HIRHAM_old = standardizeMissing(data_HIRHAM_old,-999);

    data_HIRHAM_old.Snowfallmweq = ...
        max(0, (max(data_HIRHAM_old.dlwrad)/5 - data_HIRHAM_old.dlwrad)/1000);
    
    % here the HIRHAM datais interpolated to hourly time steps
    data_HIRHAM = ResampleTable(data_HIRHAM_old);

    %% Load Extra HIRHAM files
    var_list = {'dlwrad','dswrad','tas','wind10','ps','relhum'};
    
    station_name = station;
    if strcmp(station,'CP1')
        station_name = 'CrawfordPt.';
    end
    
    for year = 2015:2016
        for i_var = 1:length(var_list)
            varname = var_list{i_var};
            filename = sprintf('./Input/HIRHAM/%s_%i_%s.txt',station_name,year,varname);
            if and(exist(filename,'file')==0,i_var == 4)
                filename = sprintf('./Input/HIRHAM/%s_%i_sfcWind.txt',station_name,year);
            end
            if exist(filename,'file')==2
            delimiter = '';
            formatSpec = '%f%[^\n\r]';
            fileID = fopen(filename,'r');
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
            fclose(fileID);
            variable = dataArray{:, 1};
            clearvars filename delimiter formatSpec fileID dataArray ans;

            if length(variable) < 3000
                time_var = datenum(year,1,1,0:3:length(variable)*3-1,0,0);
            else
                time_var = datenum(year,1,1,0:1:length(variable)-1,0,0);
            end
            data_temp = table(time_var',variable);
            data_temp.Properties.VariableNames = {'time',varname};

            data_temp = ResampleTable(data_temp);
            if i_var == 1
            data_HIRHAM(end:end+size(data_temp,1)-1,:) = ...
                array2table(NaN(size(data_temp,1),size(data_HIRHAM,2)));
            end
            data_HIRHAM.(varname)(end-size(data_temp,1)+1:end) = data_temp.(varname);
            if i_var == 1
                data_HIRHAM.time(end-size(data_temp,1)+1:end) = ...
                    data_temp.time;
            end
            end
        end
    end

    % Correcting the bias in downward LW radiation
    % as observed at PROMICE stations
    data_HIRHAM.dlwrad = data_HIRHAM.dlwrad + 14;
    data_HIRHAM = ResampleTable(data_HIRHAM);

    % converting HIRHAM data back to standard units
    data_HIRHAM.tas=data_HIRHAM.tas-273.15;
    data_HIRHAM.ps=data_HIRHAM.ps/100;
    data_HIRHAM.relhum=data_HIRHAM.relhum*100;
%     if strcmp(opt,'ConvertHumidity')
        RH_wrt_wtr = data_HIRHAM.relhum;
        T = data_HIRHAM.tas + 273.15;
        pres = data_HIRHAM.ps*100;
        data_HIRHAM.relhum = RHwater2ice(RH_wrt_wtr,T,pres);
% end
    ind = data_HIRHAM.time<datenum(2014,12,31,20,0,0);
    data_HIRHAM.wind10(ind)=data_HIRHAM.wind10(ind)*3*3600;
    ind2= and(~ind,data_HIRHAM.wind10==0);
    ind3 = ~ind2;
    data_HIRHAM.wind10(find(ind2)) = interp1(find(ind3), data_HIRHAM.wind10(find(ind3)),find(ind2));

    IndexC = strfind(data_HIRHAM.Properties.VariableNames, 'tas');
    ind_var = find(not(cellfun('isempty', IndexC)));
    data_HIRHAM.Properties.VariableNames{ind_var} = 'AirTemperature2C';
    data_HIRHAM.AirTemperature1C = data_HIRHAM.AirTemperature2C;
       
    IndexC = strfind(data_HIRHAM.Properties.VariableNames, 'dswrad');
    ind_var = find(not(cellfun('isempty', IndexC)));
    data_HIRHAM.Properties.VariableNames{ind_var} = 'ShortwaveRadiationDownWm2';

    IndexC = strfind(data_HIRHAM.Properties.VariableNames, 'ps');
    ind_var = find(not(cellfun('isempty', IndexC)));
    data_HIRHAM.Properties.VariableNames{ind_var} = 'AirPressurehPa';

    IndexC = strfind(data_HIRHAM.Properties.VariableNames, 'relhum');
    ind_var = find(not(cellfun('isempty', IndexC)));
    data_HIRHAM.Properties.VariableNames{ind_var} = 'RelativeHumidity2Perc';
    data_HIRHAM.RelativeHumidity1Perc = data_HIRHAM.RelativeHumidity2Perc;

    IndexC = strfind(data_HIRHAM.Properties.VariableNames, 'wind10');
    ind_var = find(not(cellfun('isempty', IndexC)));
    data_HIRHAM.Properties.VariableNames{ind_var} = 'WindSpeed2ms';
    data_HIRHAM.WindSpeed1ms = data_HIRHAM.WindSpeed2ms;
    
    IndexC = strfind(data_HIRHAM.Properties.VariableNames, 'dlwrad');
    ind_var = find(not(cellfun('isempty', IndexC)));
    data_HIRHAM.Properties.VariableNames{ind_var} = 'LongwaveRadiationDownWm2';
    
    % assigning heights
    data_HIRHAM.WindSensorHeight1m = 10 * ones(size(data_HIRHAM,1),1);
    data_HIRHAM.WindSensorHeight2m = 10 * ones(size(data_HIRHAM,1),1);
    data_HIRHAM.TemperatureSensorHeight1m = 2 * ones(size(data_HIRHAM,1),1);
    data_HIRHAM.TemperatureSensorHeight2m  = 2 * ones(size(data_HIRHAM,1),1);
    data_HIRHAM.HumiditySensorHeight1m = 2 * ones(size(data_HIRHAM,1),1);
    data_HIRHAM.HumiditySensorHeight2m = 2 * ones(size(data_HIRHAM,1),1);
    
    %% Loading precipitation
    if strcmp(station,'CP1')
        filename = './Input/HIRHAM/pr/HIRHAM_GL2_CrawfordPt._1990_2014_pr.txt';
    else
        filename = sprintf('./Input/HIRHAM/pr/HIRHAM_GL2_%s_1990_2014_pr.txt',station);
    end
    delimiter = ',';
formatSpec = '%f%f%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
precip = table(dataArray{1:end-1}, 'VariableNames', {'pr','time'});
clearvars filename delimiter formatSpec fileID dataArray ans;
% unit kg m-2 day-1


% figure
% hold on
%  time_step = unique(precip.time(2:end) - precip.time(1:end-1));
%     if length(time_step) >1
%         error('uneven time step')
%     end
% plot(precip.time(1:50)+ time_step/2,precip.pr(1:50),'o')
% stairs(precip.time(1:50),precip.pr(1:50))

data_precip = ResampleTable(precip);

data_HIRHAM.Snowfallmweq = NaN(size(data_HIRHAM,1),1);
[~, ind_1]= min(abs(data_precip.time(1)-data_HIRHAM.time));
[~, ind_2]= min(abs(data_precip.time(end)-data_HIRHAM.time));

data_HIRHAM.Snowfallmweq(ind_1:ind_2) = data_precip.pr*3 /1000 / 24;
% data_test = AvgTable(data_precip,'three-hourly','mean');
% 
% stairs(data_precip.time(1:50),data_precip.pr(1:50))
% stairs(data_test.time(1:50),data_test.pr(1:50))


end
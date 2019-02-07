function [data_GCnet_final] = LoadStationData(station)

filename = sprintf('./Output/%s/data_%s_combined_hour.txt',station,station);

%% Loading data
% header
delimiter = '\t';
endRow = 1;
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, endRow, 'Delimiter', delimiter, 'ReturnOnError', false);
fclose(fileID);
for i = 1:length(dataArray)
    temp = dataArray{i};
    header{i} = temp{1};
end
clearvars endRow formatSpec fileID  ans dataArray

count = length(header);
while isempty(header{count})
    header(count) = [];
    count = count -1;
end

% data
delimiter = '\t';
startRow = 2;

formatSpec = strcat(repmat('%f',1,length(header)),'%[^\n\r]');
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,...
    'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
dataArray (:,(length(header)+1):end) = [];

data_GCnet_old = table(dataArray{:}, 'VariableNames',header);
clearvars filename delimiter startRow formatSpec fileID dataArray ans;

VarNames = data_GCnet_old.Properties.VariableNames;
data_GCnet_old=standardizeMissing(data_GCnet_old,-999);
data_GCnet_final = ResampleTable(data_GCnet_old);
clearvars data_GCnet_old header

data_GCnet_final.Albedo = data_GCnet_final.ShortwaveRadiationUpWm2./ ...
    data_GCnet_final.ShortwaveRadiationDownWm2;

data_GCnet_final.Albedo(data_GCnet_final.Albedo>1)=NaN;
data_GCnet_final.Albedo(data_GCnet_final.Albedo<0)=NaN;

switch station
    case 'Summit'
    time_start = datenum('01-Jul-2000 01:00:00');
    otherwise
    time_start = data_GCnet_final.time(1);
end
switch station
    case 'CP1'
    time_end = datenum('31-Dec-2010');
    otherwise
    time_end = min(data_GCnet_final.time(end), datenum(2015,1,1));
end

ind_GCnet = find(and(data_GCnet_final.time>=time_start, ...
    data_GCnet_final.time<=time_end));
data_GCnet_final = data_GCnet_final(ind_GCnet,:);

end
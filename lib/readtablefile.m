function data_out = readtablefile(filename,delimiter)

% reading the number of column
 fid = fopen(filename,'rt');
 tLines = fgets(fid);
 numCols = numel(strfind(tLines,delimiter)) + 1;
 fclose(fid);
 
%  header
endRow = 1;
formatSpec = strcat(repmat('%s',[1,numCols]),'%[^\n\r]');

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
startRow = 2;
formatSpec = strcat(repmat('%f', 1,length(header)),'%[^\n\r]');
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,...
    'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
dataArray (:,(length(header)+1):end) = [];

data_out=table;
for i=1:length(header)
    data_out.(header{i}) = dataArray{:,i};
end
end
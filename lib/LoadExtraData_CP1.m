function [data_out] = LoadExtraData_CP1(data)

filename = '.\Input\GCnet\Additional files\CP1_2014-.txt';
delimiter = ',';
formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
fclose(fileID);
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,3,4,5,6,7,8,9,10,11,12,13,15,16,17,18,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45]

    rawData = dataArray{col};
    for row=1:size(rawData, 1);

        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

rawNumericColumns = raw(:, [2,3,4,5,6,7,8,9,10,11,12,13,15,16,17,18,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45]);
rawCellColumns = raw(:, [1,14,19]);
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

TIMESTAMP = rawCellColumns(:, 1);
RECORD = cell2mat(rawNumericColumns(:, 1));
LoggerID = cell2mat(rawNumericColumns(:, 2));
Year = cell2mat(rawNumericColumns(:, 3));
Day_of_Year = cell2mat(rawNumericColumns(:, 4));
Hour = cell2mat(rawNumericColumns(:, 5));
sw_in_Avg1 = cell2mat(rawNumericColumns(:, 6));
sw_ref_Avg = cell2mat(rawNumericColumns(:, 7));
net_rad_Avg = cell2mat(rawNumericColumns(:, 8));
tc_snow_Avg1 = cell2mat(rawNumericColumns(:, 9));
tc_snow_Avg2 = cell2mat(rawNumericColumns(:, 10));
tc_snow_Avg3 = cell2mat(rawNumericColumns(:, 11));
tc_snow_Avg4 = cell2mat(rawNumericColumns(:, 12));
tc_snow_Avg5 = rawCellColumns(:, 2);
tc_snow_Avg6 = cell2mat(rawNumericColumns(:, 13));
tc_snow_Avg7 = cell2mat(rawNumericColumns(:, 14));
tc_snow_Avg8 = cell2mat(rawNumericColumns(:, 15));
tc_snow_Avg9 = cell2mat(rawNumericColumns(:, 16));
tc_snow_Avg10 = rawCellColumns(:, 3);
tc_air_Avg1 = cell2mat(rawNumericColumns(:, 17));
tc_air_Avg2 = cell2mat(rawNumericColumns(:, 18));
t_air_Avg1 = cell2mat(rawNumericColumns(:, 19));
t_air_Avg2 = cell2mat(rawNumericColumns(:, 20));
rh_Avg1 = cell2mat(rawNumericColumns(:, 21));
rh_Avg2 = cell2mat(rawNumericColumns(:, 22));
U_Avg1 = cell2mat(rawNumericColumns(:, 23));
U_Avg2 = cell2mat(rawNumericColumns(:, 24));
Dir_Avg1 = cell2mat(rawNumericColumns(:, 25));
Dir_Avg2 = cell2mat(rawNumericColumns(:, 26));
pressure_Avg = cell2mat(rawNumericColumns(:, 27));
SD_1_Avg = cell2mat(rawNumericColumns(:, 28));
SD_2_Avg = cell2mat(rawNumericColumns(:, 29));
sw_in_Max1 = cell2mat(rawNumericColumns(:, 30));
sw_in_Std1 = cell2mat(rawNumericColumns(:, 31));
net_rad_Std = cell2mat(rawNumericColumns(:, 32));
tc_air_Max1 = cell2mat(rawNumericColumns(:, 33));
tc_air_Max2 = cell2mat(rawNumericColumns(:, 34));
tc_air_Min1 = cell2mat(rawNumericColumns(:, 35));
tc_air_Min2 = cell2mat(rawNumericColumns(:, 36));
U_Max1 = cell2mat(rawNumericColumns(:, 37));
U_Max2 = cell2mat(rawNumericColumns(:, 38));
U_Std1 = cell2mat(rawNumericColumns(:, 39));
U_Std2 = cell2mat(rawNumericColumns(:, 40));
TRef_Avg = cell2mat(rawNumericColumns(:, 41));
Battery = cell2mat(rawNumericColumns(:, 42));


%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;
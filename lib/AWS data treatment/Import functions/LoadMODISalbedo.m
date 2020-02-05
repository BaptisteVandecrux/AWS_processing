function [data_modis] = LoadMODISalbedo(is_GCnet,station)
if is_GCnet
    filename = 'Input\Albedo\ALL_YEARS_MOD10A1_C6_500m_d_nn_daily.txt';

    formatSpec = '%2f%5f%4f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fileID);
    data_modis = table(dataArray{1:end-1}, 'VariableNames', ...
        {'station','year','day','albedo'});
    clearvars filename formatSpec fileID dataArray ans;
    
    filename = 'Input\Albedo\Gc-net_documentation_Nov_10_2000.csv';
    delimiter = ';';
    formatSpec = '%s%s%s%s%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
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

    GCnetCode = table;
    GCnetCode.ID = cell2mat(rawNumericColumns(:, 1));
    GCnetCode.Name = rawCellColumns(:, 1);
    GCnetCode.Northing = cell2mat(rawNumericColumns(:, 2));
    GCnetCode.Easting = cell2mat(rawNumericColumns(:, 3));
    GCnetCode.Elevation = cell2mat(rawNumericColumns(:, 4));
    GCnetCode(1,:) = [];

    clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;
    
    if strcmp(station,'CP1')
        ind = strfind_cell(GCnetCode.Name,'Crawford Pt.');
    elseif strcmp(station,'SouthDome')
        ind = strfind_cell(GCnetCode.Name,'South Dome');        
    elseif strcmp(station,'SwissCamp')
        ind = strfind_cell(GCnetCode.Name,'Swiss Camp');        
    else
        ind = strfind_cell(GCnetCode.Name,station);
    end
    
    if ~isempty(ind)
        fprintf('%s''s ID number is %i\n',station, ind);
        
        data_modis = data_modis(...
            data_modis.station == GCnetCode.ID(ind) - 1, :);
    else
        disp('No MODIS albedo for this station')
        data_modis = [];
        return
        
    end
else
    % Loading MODIS data
    filename = 'Input\Albedo\ALL_YEARS_MOD10A1_C6_500m_d_nn_at_PROMICE_daily_columns_cumulated.txt';

    formatSpec = '%4f%4f%9f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%f%[^\n\r]';

    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fileID);
    PROMICE_MODIS = [dataArray{1:end-1}];
    clearvars filename formatSpec fileID dataArray ans;
    
%     Loading station codes
    filename = 'Input\Albedo\PROMICE station codes.txt';
    delimiter = ' ';
    formatSpec = '%*s%*s%*s%s%s%*s%*s%s%*s%*s%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
    fclose(fileID);

    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,3,4]
        % Converts strings in the input cell array to numbers. Replaced non-numeric
        % strings with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1);
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
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

    rawNumericColumns = raw(:, [1,3,4]);
    rawCellColumns = raw(:, 2);

    PromiceCode = table;
    PromiceCode.Code = cell2mat(rawNumericColumns(:, 1));
    PromiceCode.Name = rawCellColumns(:, 1);
    PromiceCode.Lat = cell2mat(rawNumericColumns(:, 2));
    PromiceCode.Lon = cell2mat(rawNumericColumns(:, 3));
    clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns;

    ind = strfind_cell(PromiceCode.Name,station) -1;
    if ~isempty(ind)
        fprintf('%s''s ID number is %i\n',station, ind);
        data_modis = table;
        data_modis.station = strfind_cell(PromiceCode.Name,station)*ones(size(PROMICE_MODIS(:,1)));
        data_modis.year = PROMICE_MODIS(:,1);
        data_modis.day = PROMICE_MODIS(:,2);
        data_modis.albedo = PROMICE_MODIS(:,ind+3);
    else
% if cannot find station then we give table "data_MODIS" empty
% later on the station climatology in albedo will be used instead
        ind = 18;
    % Ask Jason Box (jeb@geus.dk) to provide MODIS time series at other stations
    fprintf('No MODIS data available for %s\n',station);
        data_modis = table;
        data_modis.station = 18*ones(size(PROMICE_MODIS(:,1)));
        data_modis.year = PROMICE_MODIS(:,1);
        data_modis.day = PROMICE_MODIS(:,2);
        data_modis.albedo = NaN(size(data_modis.day));
    end
end

data_modis.time = datenum(data_modis.year,1,data_modis.day);
data_modis = standardizeMissing(data_modis,999);

end


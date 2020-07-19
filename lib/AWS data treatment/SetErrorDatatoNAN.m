
function [data] = SetErrorDatatoNAN(data, station,vis)
% read error_data_log from station and set data between time1 and time2 to NAN

     [~,sheet_list] =xlsfinfo('.\Input\ErrorData_AllStations.xlsx');
     if ~ismember(station,sheet_list)
         disp('No error data file found for this station')
         return
     end
     
opts = spreadsheetImportOptions("NumVariables", 3);

% Specify sheet and range
opts.Sheet = station;
opts.DataRange = "A1:C100";

% Specify column names and types
opts.VariableNames = ["AirTemperature1C", "VarName2", "VarName3"];
opts.SelectedVariableNames = ["AirTemperature1C", "VarName2", "VarName3"];
opts.VariableTypes = ["string", "string", "string"];
opts = setvaropts(opts, [1, 2, 3], "WhitespaceRule", "preserve");
opts = setvaropts(opts, [1, 2, 3], "EmptyFieldRule", "auto");
ErrorDataAllStations = readtable(".\Input\ErrorData_AllStations.xlsx", opts, "UseExcel", false);
ErrorDataAllStations = table2cell(ErrorDataAllStations);
numIdx = cellfun(@(x) ~isnan(str2double(x)), ErrorDataAllStations);
ErrorDataAllStations(numIdx) = cellfun(@(x) {str2double(x)}, ErrorDataAllStations(numIdx));
while strcmp(ErrorDataAllStations{length(ErrorDataAllStations(:,1)),1},"")
    ErrorDataAllStations(length(ErrorDataAllStations(:,1)),:) = [];
end

variable_name = ErrorDataAllStations(:,1);
date1 = ErrorDataAllStations(:,2);
date2 = ErrorDataAllStations(:,3);
clear opts
    
    %% Removing
    % for length of csv file: set variables given in the first column (weather_name)
    % in the time interval [date1, date2] to NaN
    for i = 1:length(variable_name)
        if ~ismember(variable_name{i},data.Properties.VariableNames)
            continue
        end
        try 
            ind1 = dsearchn(data.time,datenum(date1{i},'dd-mm-yyyy HH:MM:SS'));
            ind2 = dsearchn(data.time,datenum(date2{i},'dd-mm-yyyy HH:MM:SS'));
        catch me
            ind1 = dsearchn(data.time,datenum(date1{i},'dd-mmm-yyyy'));
            ind2 = dsearchn(data.time,datenum(date2{i},'dd-mmm-yyyy'));
        end
        %update Baptiste
         data.(variable_name{i})(ind1:ind2) = NaN;
    end
              
end
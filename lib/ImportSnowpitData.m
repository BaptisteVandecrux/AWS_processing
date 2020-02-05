function [tableout] = ImportSnowpitData()
    [~, ~, raw, dates] = xlsread('.\Input\Greenland_snow_pit_SWE.xlsx','snow_pit_SWE_compiled_by_J_Box_','A2:P10000','',@convertSpreadsheetExcelDates);
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
    raw(cellfun(@(x) isempty(x),raw(:,1)),:) = [];
    dates(cellfun(@(x) isempty(x),dates(:,1)),:) = [];

    cellVectors = raw(:,[1,12,13,14,16]);
    raw = raw(:,[2,3,4,5,6,7,8,9,10,11]);
    dates = dates(:,15);

    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),dates); % Find non-numeric cells
    dates(R) = {NaN}; % Replace non-numeric Excel dates with NaN

    data = reshape([raw{:}],size(raw));
    tableout = table;
    tableout.Station = cellVectors(:,1);
    tableout.Date = datestr(datenum(data(:,6),data(:,5),data(:,4)));
    tableout.SWE_pit = data(:,10);
    clearvars data raw dates cellVectors R;
end


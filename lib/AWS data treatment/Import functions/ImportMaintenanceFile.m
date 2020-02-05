function maintenance = ImportMaintenanceFile(station)

 [~, SHEETS]   = xlsfinfo('Input/maintenance.xlsx');
if sum(strcmp(SHEETS,station))==0
    station = 'PROMICE';
end

[~, ~, raw] = xlsread('Input/maintenance.xlsx', station);
    raw = raw(2:end,:);
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
    
    cellVectors = raw(:,2);
    dates = raw(:,1);
    raw = raw(:,3:end);

    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),dates); % Find non-numeric cells
%     dates(R) = {NaN}; % Replace non-numeric Excel dates with NaN

    data_imp = reshape([raw{:}],size(raw));
    maintenance = table;

    maintenance.date = datenum(dates,'dd-mm-yyyy');
    maintenance.reported = cellVectors(:,1);
    maintenance.SR1beforecm = data_imp(:,1);
    maintenance.SR1aftercm = data_imp(:,2);
    maintenance.SR2beforecm = data_imp(:,3);
    maintenance.SR2aftercm = data_imp(:,4);
    maintenance.T1beforecm = data_imp(:,5);
    maintenance.T1aftercm = data_imp(:,6);
    maintenance.T2beforecm = data_imp(:,7);
    maintenance.T2aftercm = data_imp(:,8);
    maintenance.W1beforecm = data_imp(:,9);
    maintenance.W1aftercm = data_imp(:,10);
    maintenance.W2beforecm = data_imp(:,11);
    maintenance.W2aftercm = data_imp(:,12);
    maintenance.NewDepth1m = data_imp(:,13);
    maintenance.NewDepth2m = data_imp(:,14);
    maintenance.NewDepth3m = data_imp(:,15);
    maintenance.NewDepth4m = data_imp(:,16);
    maintenance.NewDepth5m = data_imp(:,17);
    maintenance.NewDepth6m = data_imp(:,18);
    maintenance.NewDepth7m = data_imp(:,19);
    maintenance.NewDepth8m = data_imp(:,20);
    maintenance.NewDepth9m = data_imp(:,21);
    maintenance.NewDepth10m = data_imp(:,22);
    clearvars data_imp raw dates cellVectors R;
end
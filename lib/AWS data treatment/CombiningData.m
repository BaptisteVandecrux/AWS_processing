function [data, R2, RMSE, ME] = CombiningData(station,sec_station, data, data_aux, vis, PlotGapFill, OutputFolder)
% [data] = CombiningData(station, sec_station, data, data_aux, vis, OutputFolder)
%   This function compares each weather variable in data and data_aux during their
%   overlapping period by plotting one vs the other. Fits a regression line 
%   from one to the other.
%
%  Input
%       station: string with the name of the main weather station
%       sec_station : string with the name of the secondary station
%       data : table containing the data from te main station
%       data_aux: table containing the data from the secondary station.
%       vis : string containing 'on' or 'off' depending on whether the figures
%       should be visible or not
%       OutputFolder : string containing the path to the folder where plots
%       should be saved
%
%   Output
%       data : table containing the combined data
% =========================================================================
% data = ResampleTable(data);
% data_aux = ResampleTable(data_aux);

% list of variable name in data in which gaps should be filled
VarName = { 'AirTemperature1C', 'AirTemperature2C',...
    'ShortwaveRadiationDownWm2', 'NetRadiationWm2', ...
    'AirPressurehPa', 'RelativeHumidity1Perc',...
    'RelativeHumidity2Perc', 'WindSpeed1ms', 'WindSpeed2ms'};

R2 = NaN(1,length(VarName)+1);
RMSE = NaN(1,length(VarName)+1);
ME = NaN(1,length(VarName)+1);

data = UpdateInstrumentHeight(data, data_aux, 'RelativeHumidity1Perc');
data = UpdateInstrumentHeight(data, data_aux, 'RelativeHumidity2Perc');
data = UpdateInstrumentHeight(data, data_aux, 'AirTemperature1C');
data = UpdateInstrumentHeight(data, data_aux, 'AirTemperature2C');
data = UpdateInstrumentHeight(data, data_aux, 'WindSpeed1ms');
data = UpdateInstrumentHeight(data, data_aux, 'WindSpeed2ms');

for i = 1:length(VarName)
    if ~ismember(VarName{i},data_aux.Properties.VariableNames) || sum(~isnan(data_aux.(VarName{i})))<10
        fprintf('%s was not found in %s data.\n', VarName{i}, sec_station);
        continue
    end
    
    fprintf('\tin %s using %s\n',VarName{i},sec_station);
    if ~isempty(strfind(VarName{i},'RelativeHumidity'))
        data_aux.(VarName{i}) = RHice2water(data_aux.(VarName{i}),data_aux.AirTemperature2C+273.15,data_aux.AirPressurehPa);
        data.(VarName{i}) = RHice2water(data.(VarName{i}),data.AirTemperature2C+273.15,data.AirPressurehPa);
    end
    
    [data, R2(i), RMSE(i), ME(i)] = RecoverData(sec_station,data,VarName{i},...
        data_aux,VarName{i}, vis,PlotGapFill,OutputFolder);
    
    if ~isempty(strfind(VarName{i},'RelativeHumidity'))
        data_aux.(VarName{i}) = RHwater2ice(data_aux.(VarName{i}),data_aux.AirTemperature2C+273.15,data_aux.AirPressurehPa);
        data.(VarName{i}) = RHwater2ice(data.(VarName{i}),data.AirTemperature2C+273.15,data.AirPressurehPa);
    end
end

if and(ismember('LongwaveRadiationDownWm2',data.Properties.VariableNames),...
        ismember('LongwaveRadiationDownWm2',data_aux.Properties.VariableNames))
    if sum(~isnan(data_aux.LongwaveRadiationDownWm2))>10
        [data, R2(end), RMSE(end), ME(end)] = RecoverData(sec_station,data,'LongwaveRadiationDownWm2',...
        data_aux,'LongwaveRadiationDownWm2',vis,PlotGapFill,OutputFolder);
    end
end

% if strcmp(sec_station,'KANUbabis')
%     ind = find(and(data_aux.time>=datenum('19-Aug-2010 07:00:00'),...
%         data_aux.time<=datenum('12-Mar-2012 05:00:00')));
%     ind2 = find(and(data.time>=datenum('19-Aug-2010 07:00:00'),...
%         data.time<=datenum('12-Mar-2012 05:00:00')));
%     export_height = data_aux.ValidationHeightm(ind) - data_aux.ValidationHeightm(ind(1));
%     data.SnowHeight1m(ind2) = export_height +data.SnowHeight1m(ind2(1));
%     data.SnowHeight2m(ind2) = export_height +data.SnowHeight2m(ind2(1));
% end
          
end


function [data, R2, RMSE, ME] = CombiningData(station,sec_station, data,...
    data_aux,VarName, vis, PlotGapFill, OutputFolder)
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

R2 = NaN(1,length(VarName));
RMSE = NaN(1,length(VarName));
ME = NaN(1,length(VarName));

data = UpdateInstrumentHeight(data, data_aux, 'RelativeHumidity1Perc');
data = UpdateInstrumentHeight(data, data_aux, 'RelativeHumidity2Perc');
data = UpdateInstrumentHeight(data, data_aux, 'AirTemperature1C');
data = UpdateInstrumentHeight(data, data_aux, 'AirTemperature2C');
data = UpdateInstrumentHeight(data, data_aux, 'WindSpeed1ms');
data = UpdateInstrumentHeight(data, data_aux, 'WindSpeed2ms');

for i = 1:length(VarName)
    
    if ~ismember(VarName{i},data_aux.Properties.VariableNames) ...
            || sum(~isnan(data_aux.(VarName{i})))<1000
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
        
end


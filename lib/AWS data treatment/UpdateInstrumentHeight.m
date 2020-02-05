function data = UpdateInstrumentHeight(data, data_aux, VarName1, VarName2)
if ~exist('VarName2')
    VarName2 = VarName1;
end

    ind_common1 = find(and(data.time<=data_aux.time(end)+0.0001,...
        data.time>=data_aux.time(1)-0.0001));
    ind_common2 = find(and(data_aux.time<=data.time(end)+0.0001,...
        data_aux.time>=data.time(1)-0.0001));

    if length(ind_common1) == length(ind_common2)
        indnan1 = isnan(data.(VarName1)(ind_common1));
        ind_no_nan2 = ~isnan(data_aux.(VarName2)(ind_common2));
        
        ind_change_common = and(indnan1,ind_no_nan2);
        ind_change1 = ind_common1(ind_change_common);
        ind_change2 = ind_common2(ind_change_common);
        
    else
        error(sprintf('Missing time steps in %s',VarName1))
    end
    switch VarName1
        case 'RelativeHumidity1Perc'
            HeightName = 'HumiditySensorHeight1m';
        case 'RelativeHumidity2Perc'
            HeightName = 'HumiditySensorHeight2m';
        case 'AirTemperature1C'
            HeightName = 'TemperatureSensorHeight1m';
        case 'AirTemperature2C'
            HeightName = 'TemperatureSensorHeight2m';
        case 'WindSpeed1ms'
            HeightName = 'WindSensorHeight1m';
        case 'WindSpeed2ms'
            HeightName = 'WindSensorHeight2m';
        otherwise
            error('Field %s unknown', VarName1)
    end
            
    if sum(strcmp(data_aux.Properties.VariableNames,HeightName))>0
        data.(HeightName)(ind_change1) = ...
            data_aux.(HeightName)(ind_change2);
    else
        error('No height field %s was found.', HeightName)
    end
 
end
function data = RenameTable(data)
for i = 1:size(data,2)
    switch data.Properties.VariableNames{i}
        case 'SWup'
            data.Properties.VariableNames{i} = 'ShortwaveRadiationUpWm2';
        case 'SWdown'
            data.Properties.VariableNames{i} = 'ShortwaveRadiationDownWm2';
        case 'LWup'
            data.Properties.VariableNames{i} = 'LongwaveRadiationUpWm2';
        case 'LWdown'
            data.Properties.VariableNames{i} = 'LongwaveRadiationDownWm2';
        case 'ta_2m'
            data.Properties.VariableNames{i} = 'AirTemperature1C';
            data.AirTemperature2C = data.AirTemperature1C;
            data.AirTemperature3C = NaN*data.AirTemperature1C;
            data.AirTemperature4C = NaN*data.AirTemperature1C;
        case 'rh'
            data.Properties.VariableNames{i} = 'RelativeHumidity1Perc';
            data.RelativeHumidity2Perc = data.RelativeHumidity1Perc;
        case 'ws'
            data.Properties.VariableNames{i} = 'WindSpeed1ms';
            data.WindSpeed2ms = data.WindSpeed1ms;
        case 'ps'
            data.Properties.VariableNames{i} = 'AirPressurehPa';
    end

    data.WindSensorHeight1m = 2*ones(size(data.time));
    data.WindSensorHeight2m = 2*ones(size(data.time));
    data.TemperatureSensorHeight1m = 2*ones(size(data.time));
    data.TemperatureSensorHeight2m = 2*ones(size(data.time));
    data.HumiditySensorHeight1m = 2*ones(size(data.time));
    data.HumiditySensorHeight2m = 2*ones(size(data.time));
end
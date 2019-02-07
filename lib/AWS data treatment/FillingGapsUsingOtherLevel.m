function data = FillingGapsUsingOtherLevel(data, VarName1,VarName2)
            %timestamps of missing data
            ind_nan = find(isnan(data.(VarName1)));
            data.(VarName1)(ind_nan) = data.(VarName2)(ind_nan);
            
            switch VarName1
                case 'AirTemperature1C'
                    data.TemperatureSensorHeight1m(ind_nan) = ...
                        data.TemperatureSensorHeight2m(ind_nan);
                case 'AirTemperature2C'
                    data.TemperatureSensorHeight2m(ind_nan) = ...
                        data.TemperatureSensorHeight1m(ind_nan);
                case 'RelativeHumidity1Perc'
                    data.HumiditySensorHeight1m(ind_nan) = ...
                        data.HumiditySensorHeight2m(ind_nan);
                case 'RelativeHumidity2Perc'
                    data.HumiditySensorHeight2m(ind_nan) = ...
                        data.HumiditySensorHeight1m(ind_nan);
                case 'WindSpeed1ms'
                    data.WindSensorHeight1m(ind_nan) = ...
                        data.WindSensorHeight2m(ind_nan);
                case 'WindSpeed2ms'
                    data.WindSensorHeight2m(ind_nan) = ...
                        data.WindSensorHeight1m(ind_nan);
            end
end
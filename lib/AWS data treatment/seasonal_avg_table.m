function [T_avg_out] = seasonal_avg_table(data)
    ind_temp = find(strcmp('AirTemperatureC',data.Properties.VariableNames));
    if isempty(ind_temp)
        data.AirTemperatureC = data.AirTemperature2C;
    end

    ind = [find(strcmp('time',data.Properties.VariableNames)), ...
        find(strcmp('AirTemperatureC',data.Properties.VariableNames))];
    
    T_avg = AvgTable(data(:,ind),'yearly','mean',90);
    temp = datevec(T_avg.time);
    T_avg.Year = temp(:,1);
    if data.time(1)>datenum(temp(1,1),1,15)
        T_avg.AirTemperatureC(1) = NaN;
    end
    if data.time(end)<datenum(temp(end,1),12,15)
        T_avg.AirTemperatureC(end) = NaN;
    end
 
    temp = datevec(data.time);
    ind_JJA = ismember(temp(:,2),[6 7 8]);
    data_JJA = data(ind_JJA,ind);
 
    Tavg_JJA = AvgTable(data_JJA,'yearly','mean',90);
    temp = datevec(Tavg_JJA.time);
    Tavg_JJA.Year = temp(:,1);
    if data.time(1)>datenum(temp(1,1),6,5)
        Tavg_JJA.AirTemperatureC(1) = NaN;
    end
    if data.time(end)<datenum(temp(end,1),8,25)
        Tavg_JJA.AirTemperatureC(end) = NaN;
    end
    
    years = union(T_avg.Year,Tavg_JJA.Year);
    T_avg_out = table;
    T_avg_out.Year = sort(years);
    T_avg_out.avg_year = sort(years);
    T_avg_out.avg_JJA = sort(years);
    for i=1:length(years)
        i1 = find(T_avg.Year==T_avg_out.Year(i));
        i2 = find(Tavg_JJA.Year==T_avg_out.Year(i));
        T_avg_out.avg_year(i) = T_avg.AirTemperatureC(i1);
        if ~isempty(i2)
            T_avg_out.avg_JJA(i) = Tavg_JJA.AirTemperatureC(i2);
        else
            T_avg_out.avg_JJA(i) = NaN;
        end
    end        
    
end
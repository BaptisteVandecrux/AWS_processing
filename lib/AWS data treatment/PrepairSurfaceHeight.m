function [H_1_ts_smoothed] = PrepairSurfaceHeight(H_1_ts,hampel_period,hampel_var)
% interpolating over small gaps

    table_temp = table(H_1_ts.Time,H_1_ts.Data);
    table_temp.Properties.VariableNames = {'Time','Data'};
    table_temp = InterpTable(table_temp,48);
    H_1_ts.Data = table_temp.Data;
    
     % filtering peaks and noise with hampel filter
    H_1_ts_smoothed = H_1_ts;
    ind_nan = isnan(H_1_ts.Data);

    H_1_ts_smoothed.Data = hampel(H_1_ts.Data,hampel_period,hampel_var);

    H_1_ts_smoothed.Data(ind_nan) = NaN;

end


    
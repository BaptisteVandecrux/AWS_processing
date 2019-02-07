function [ts_3, h1, h2] = SurfaceHeightSmoothing(ts,KeyWord,Value)
% This function smoothes the surface height time series  and interpolates
% over the periods where data is not available

    InterpMethod = 'pchip';
if strcmp(KeyWord,'Interp')
    InterpMethod = Value;
end
    % filtering peaks and noise with hampel filter
    ts_2 = ts;
    ind_nan = isnan(ts.Data);
    ts_2.Data = hampel(ts.Data,24*14,0.00001);
    ts_2.Data(ind_nan) = NaN;
    ts_3 = ts_2;   

    %interpolating missing values
    nanx = isnan(ts_2.Data);
%     t    = 1:numel(ts_2.Data);
%     ts_3.Data(nanx) = interp1(t(~nanx), ts_2.Data(~nanx), t(nanx),InterpMethod);
    
    % subtracting first non-NaN value to start at 0 in old and new ts
    ind = find(~isnan(ts_3.Data));
	ts.Data = ts.Data - ts_3.Data(ind(1));
    ts_3.Data = ts_3.Data - ts_3.Data(ind(1));
    
    % plotting orgininal data
    scatter(ts.Time,ts.Data,'or','LineWidth',2)
    hold on
    % plotting final data
    h1 = plot(ts_2,'b','LineWidth',2);

    ts_4 = ts_3;
    ts_4.Data(~nanx) = NaN;
    h2 = plot(ts_4,'g','LineWidth',2);    
end
function [snowfall_weq, rainfall, T_rain, c]=Precipitation(time, T, LRin_AWS,...
    RH, Surface_Height, c)


% PRECIPITATION -----------------------------------------------------------------------
snowfall_weq = zeros(size(LRin_AWS));
rainfall = zeros(size(LRin_AWS));
T_rain = c.T_0*ones(size(LRin_AWS));

switch c.precip_scheme
    case 1
        snowing = (LRin_AWS >= c.sigma*T.^4 );   
        % assuming equal precipitation rate over entire transect
%         raining = (LRin_AWS >= c.sigma*T_AWS.^4 &...
%                 T - c.T_0 > c.T_solidprecip);
        % assuming extrapolated values can be used for precipitation estimates
        if sum(snowing) > 0
            snowfall_weq(snowing) = c.prec_rate./3600*c.dt_obs/c.dev;
        end
        
%         if sum(raining) > 0
%             rainfall(raining) = c.prec_rate./3600*c.dt_obs/c.dev;
%         end
        
    case 2
        % Scheme from Liston & Sturm 1998.
        % precipitation when RH > 80% with intensity equal to the number of
        % RH points above 80 during the time step divided by the total 
        % number of RH point above 80 during the whole season.
        
        snowing = and(RH >= 80 , T - c.T_0  <= c.T_solidprecip);   
        % assuming equal precipitation rate over entire transect
        raining = and(RH >= 80 , T - c.T_0 > c.T_solidprecip);
        % assuming extrapolated values can be used for precipitation estimates
        if sum(snowing) > 0
            snowfall_intensity = (RH(snowing) - 80)./ 20;
            snowfall_weq(snowing) = snowfall_intensity.*c.prec_rate./3600*c.dt_obs/c.dev;
        end% in m of snowend
        if sum(raining) >0
            rainfall(raining) = c.prec_rate/3600.*c.dt_obs/c.dev ;          % in m of water
        end
        
    case 3
        %% METHOD 3: Taking snowfall from surface height measurements.
        % + tuning using snowpit
        % + leaving blank when surface height not available so that it is
        % filled by RCM data.
        
        ind_nan = isnan(Surface_Height);
        Surface_Height = hampel(Surface_Height,7*24,0.1);
        Surface_Height(ind_nan) = NaN;
        
        % Calculating a first estimate of snowfall from surface height
        % incremements.
        for k=1:length(snowfall_weq)
            if k>1
                dSurface_Height= -(Surface_Height(k) - Surface_Height(k-1)); %in real m
            else
                dSurface_Height= 0;
            end
            if dSurface_Height< 0
                % if the surface height increase, it means that snow is
                % falling
                snowfall_weq(k) = -dSurface_Height*c.rho_snow(k)/c.rho_water ; %in m weq
            end
        end
            
        % Loading the snowpit dataset and selecting the snowpits available
        % at the station of interest
        [pit_data] = ImportSnowpitData();
        [subl] = ImportSublimationEstimate(c,time);

        if strcmp(c.station,'DYE-2_long')
            ind = strcmp(pit_data.Station,'DYE-2');
        else
            ind = strcmp(pit_data.Station,c.station);
        end
        pit_data = pit_data(ind,:);
        time_mod = datenum(time,1,1);

        date_pit = datenum(pit_data.Date);
        ind = and(date_pit>time_mod(1),date_pit<time_mod(end));
        pit_data = pit_data(ind,:);
    pit_data.SWE_uncor = NaN(size(pit_data,1),1);

if size(pit_data,1)>0  
            
    pit_data.SWE_uncor = NaN(size(pit_data,1),1);
    pit_data.tot_subl = NaN(size(pit_data,1),1);
    
    for i=1:size(pit_data,1)
        % closest time step to the snowpit survey date
        date_end = datenum(pit_data.Date(i,:));
        [~, pit_data.ind_end(i)] = min(abs(date_end - time_mod));
        [~, pit_data.ind_end_in_subl(i)] = min(abs(date_end - subl.time));
        temp = datevec(date_end);
        
        % We assume winter accumulation starts on 1st September
        date_start = datenum(temp(:,1)-1,09,01);
        [~, pit_data.ind_start(i)] = min(abs(time_mod-date_start));
        [~, pit_data.ind_start_in_subl(i)] = min(abs(date_start - subl.time));
        date_start = time_mod(pit_data.ind_start(i));
        
        % summing the sublimation that occured since the 1st Sept. until
        % the snowpit survey
        pit_data.tot_subl(i) = sum(subl.estim( ...
            pit_data.ind_start_in_subl(i):pit_data.ind_end_in_subl(i))); % in mm weq

        pit_data.SWE_uncor(i) = sum(snowfall_weq(...
            pit_data.ind_start(i):pit_data.ind_end(i)))*1000 ...
            + pit_data.tot_subl(i);

%         datestr(date_start)
%         datestr(date_end)
%         figure
%         hold on
%         plot(time_mod,Surface_Height)
%          plot(time_mod([pit_data.ind_start(i) pit_data.ind_start(i)]), [0 3])
%          plot(time_mod([pit_data.ind_end(i) pit_data.ind_end(i)]), [0 3])
%         datetick('x')
%         pause
        % cancelling cases where the beginning of accumulation period is
        % not available
        if abs(date_start - datenum(temp(:,1)-1,09,01))>30
            pit_data.SWE_uncor(i) = NaN;
            continue
        end
        if sum(isnan(Surface_Height(...
            pit_data.ind_start(i):pit_data.ind_end(i)))) > length(...
            pit_data.ind_start(i):pit_data.ind_end(i))*0.1
            % cancelling cases where too many surface height meeasurements
            % are missing
            pit_data.SWE_uncor(i) = NaN;
        end
    end
end

if and(size(pit_data,1)>0      , sum(~isnan(pit_data.SWE_uncor))>=1)
    ind_good_years = ~isnan(pit_data.SWE_uncor);
    bias_uncor = mean(pit_data.SWE_uncor(ind_good_years) - pit_data.SWE_pit(ind_good_years));
    RMSE_uncor = sqrt(mean((pit_data.SWE_uncor(ind_good_years) - pit_data.SWE_pit(ind_good_years)).^2));

    % applying a correction factor on the snowfall rates to nullify the
    % mean bias
    corr_fact = (mean(pit_data.SWE_uncor(ind_good_years)) - bias_uncor)...
        /mean(pit_data.SWE_uncor(ind_good_years));
    snowfall_weq = snowfall_weq .* corr_fact;
    snowfall_weq(isnan(Surface_Height)) = NaN;
%     time_mod = datenum(time,1,1);
    pit_data.SWE_cor = NaN(size(pit_data,1),1);
    
    % now we compare once again the corrected snowfall to the snowpit
    % dataset to get the new performance.
    for i=1:size(pit_data,1)
        pit_data.SWE_cor(i) = nansum(snowfall_weq(...
            pit_data.ind_start(i):pit_data.ind_end(i)))*1000 + pit_data.tot_subl(i);
        temp = datevec(time_mod(pit_data.ind_end(i)));

        if abs(time_mod(pit_data.ind_start(i)) - datenum(temp(:,1)-1,09,01))>30
            pit_data.SWE_cor(i) = NaN;
        elseif sum(isnan(Surface_Height(...
            pit_data.ind_start(i):pit_data.ind_end(i)))) > length(...
            pit_data.ind_start(i):pit_data.ind_end(i))*0.1
            % cancelling cases where too many surface height meeasurements
            % are missing
            pit_data.SWE_cor(i) = NaN;
        end
    end
    
    bias_cor = ...
        nanmean(pit_data.SWE_cor - pit_data.SWE_pit);
    RMSE_cor = ...
        sqrt(nanmean((pit_data.SWE_cor - pit_data.SWE_pit).^2));
        
    PlottingSnowfallAdjustment(Surface_Height, pit_data, ...
        bias_uncor, RMSE_uncor, bias_cor, RMSE_cor,...
        corr_fact,time_mod,  c);

    pit_data(:,[1 6:9]) = [];
    filename = sprintf('%s/SWE_%s.txt',c.OutputFolder,c.station);
    writetable(pit_data,filename,'Delimiter',';');
else
        snowfall_weq = snowfall_weq .* 1.25;
end
% if strcmp(c.station, 'CP1')
%         snowfall_weq = snowfall_weq .* 1.09;
% elseif strcmp(c.station, 'DYE-2')
%         snowfall_weq = snowfall_weq .* 1.2;
% end

end

% if sum(raining) >0
%     T_rain(raining) = T(raining);
% end

% NB: The temperature of the newly accumulated snow is set by the surface energy balance.
% The temperature of the rain water is assumed equal to the air temperature (or 0 C when air temperature is below freezing).
end

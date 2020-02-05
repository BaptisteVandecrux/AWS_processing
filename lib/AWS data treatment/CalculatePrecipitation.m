function [data_out] = CalculatePrecipitation(data,data_RCM,station, OutputFolder,vis)
% This function calculates the precipitation at a AWS. Choice is given
% between different approach (see function Precipitation.m). It also reads
% the modelled precipitation from RCM output, scales it using available
% station-derived precipitation and uses it to fill the gap in the
% station-derived series.
%
% Baptiste Vandecrux
% b.vandecrux@gmail.com
% 2018
% =========================================================================
data_save = data;
    opts.precip_scheme = 3;
    opts.T_0 = 273.15;
    opts.prec_rate = 0.001;
    opts.sigma = 5.67 * 10^-8; 
    opts.dt_obs = 3600;
    opts.dev = 1;
    opts.rho_snow = ones(size(data.time)) * 315;
    opts.station = station;
    opts.verbose = 1;
    opts.mean_accum = 0.3;
    opts.rho_water = 1000;
    opts.OutputFolder = OutputFolder;

    DV  = datevec(data.time);  % [N x 6] array

    time_decyear = DV(:,1) + ...
        (datenum(DV(:,1),DV(:,2),DV(:,3))-datenum(DV(:,1),1,1))...
        ./(datenum(DV(:,1),12,32)-datenum(DV(:,1),1,1));
    
    opts.vis = vis;
    [data.Snowfallmweq, ~, ~, ~] = Precipitation(time_decyear, data.AirTemperature1C,...
        data.LongwaveRadiationDownWm2, data.RelativeHumidity1Perc, data.SurfaceHeightm, opts);
    
    data.Snowfallmweq(isnan(data.SurfaceHeightm))=NaN;
    data.Snowfallmweq(data.Snowfallmweq>300*nanmean(data.Snowfallmweq)) = NaN;
    data_out = data;
    
%% cropping observation and RCM data to compare them
    ind_start = max(find(~isnan(data.Snowfallmweq),1,'first'),...
        find(data.Snowfallmweq~=0,1,'first'));
    ind_end = find(~isnan(data.Snowfallmweq),1,'last');
    data = data(ind_start:ind_end,:);
    data.Snowfallmweq(isnan(data.Snowfallmweq)) = nanmean(data.Snowfallmweq);

    data_RCM_cropped =data_RCM;
    data_RCM_cropped(data_RCM_cropped.time<data.time(1)-1/48,:) = [];
    data_RCM_cropped(data_RCM_cropped.time>data.time(end)+1/48,:) = [];
    data(data.time<data_RCM_cropped.time(1)-1/48,:) = [];
    data(data.time>data_RCM_cropped.time(end)+1/48,:) = [];

    model = fitlm(cumsum(data_RCM_cropped.Snowfallmweq),cumsum(data.Snowfallmweq));
    
    % applying correction
    data_RCM_cor = data_RCM;
    data_RCM_cor.Snowfallmweq = data_RCM.Snowfallmweq * model.Coefficients.Estimate(2);
       
    data_RCM_cropped_cor = data_RCM_cropped;
    data_RCM_cropped_cor.Snowfallmweq = data_RCM_cropped.Snowfallmweq * model.Coefficients.Estimate(2);

%% Replacing values
    ind_nan = isnan(data_out.Snowfallmweq);
    data_out.Snowfallmweq_Origin(~ind_nan) = 0;

    ind_common_1 = and(data_out.time<=data_RCM_cor.time(end)+0.0001,...
        data_out.time>=data_RCM_cor.time(1)-0.0001);
    ind_to_replace = and(ind_common_1,ind_nan);
    ind_to_replace_in_common = ...
        ind_to_replace(find(ind_common_1,1,'first'):find(ind_common_1,1,'last'));
    
    % updating origin
	data_out.Snowfallmweq_Origin(ind_to_replace) = 4;
    
    % testing that no NaN was left
    ind_not_replaced = and(~ind_common_1,ind_nan);
    if sum(ind_not_replaced) > 0
        warning('Some timesteps could not be replaced using RCM data because of RCM time coverage.')
    end
    % finding the time steps in the RCM data that are NaN in the station
    % data
    ind_common_2 = find(and(data_RCM_cor.time<=data_out.time(end)+0.0001,...
        data_RCM_cor.time>=data_out.time(1)-0.0001));
    ind_nan2 = find(ind_nan);
    ind_replacement = ind_common_2(ind_to_replace_in_common);
    
    % replacing data
	data_out.Snowfallmweq(ind_to_replace) = ...
        data_RCM_cor.Snowfallmweq(ind_replacement);
    
    data_out.Rainfallmweq = data_out.Snowfallmweq*0;
    data_out.Rainfallmweq(ind_common_1) = ...
        data_RCM.Rainfallmweq(ind_common_2);
    
%% plotting  

    f = figure('Visible',vis);
    plot(data.time,data.Snowfallmweq)
    hold on
    plot(data_RCM_cropped.time,data_RCM_cropped.Snowfallmweq)
    plot(data_RCM_cropped_cor.time,data_RCM_cropped_cor.Snowfallmweq)
    datetick('x','mm-yyyy')
      axis tight
    legend('station','RCM','RCM adjusted')
    title(station)
    xlabel('Time')
    ylabel('Precipitation (m weq)')
    orient('landscape')
    print(f,sprintf('%s/precip1',OutputFolder),'-dpng')

    f = figure('Visible',vis);
    subplot(1,2,1)
    scatter(cumsum(data_RCM_cropped.Snowfallmweq),cumsum(data.Snowfallmweq))
    hold on
    plot([0 max(cumsum(data.Snowfallmweq))],[0 max(cumsum(data.Snowfallmweq))])
    axis tight square
    box on
    title('before tuning')
    xlabel('RCM cumulated precipitation (m weq)')
    ylabel('AWS cumulated precipitation (m weq)')
    
    subplot(1,2,2)
    scatter(cumsum(data_RCM_cropped_cor.Snowfallmweq),cumsum(data.Snowfallmweq))
    hold on
    plot([0 max(cumsum(data.Snowfallmweq))],[0 max(cumsum(data.Snowfallmweq))])
    axis tight square
    box on
    xlabel('RCM cumulated precipitation (m weq)')
    ylabel('AWS cumulated precipitation (m weq)')
    title(sprintf('After tuning (x %0.2f)',model.Coefficients.Estimate(2)))
    print(f,sprintf('%s/precip2',OutputFolder),'-dtiff')
    
    f = figure('Visible',vis);
    subplot(2,1,1)
    plot(data_out.time,data_out.Snowfallmweq,'LineWidth',1.5)
    hold on
    plot(data.time,data.Snowfallmweq,'LineWidth',1.5)
    datetick('x','mm-yyyy')
      axis tight
    xlabel('Time')
    ylabel('Precipitation (m weq)')
    title(station)

    subplot(2,1,2)
    plot(data_out.time,cumsum(data_out.Snowfallmweq),'LineWidth',1.5)
    datetick('x','mm-yyyy')
      axis tight
    xlabel('Time')
    ylabel('Cumulated precipitation \newline             (m weq)','Interpreter','tex')
    print(f,sprintf('%s/precip3',OutputFolder),'-dtiff')
    
    pr = table(data_out.time,data_out.Snowfallmweq);
    pr.Properties.VariableNames = {'time','pr'};
    if length(pr.time)>365*24
        pr_yr = AvgTable(pr,'yearly','sum');
        f = figure('Visible',vis);
        plot(pr_yr.time,pr_yr.pr,'--o')
        hold on
        Plotlm(pr_yr.time,pr_yr.pr);
        plot(data.time,data.SurfaceHeightm/20)
        title(station)
        datetick('x','mm-yy')
        print(f,sprintf('%s/precip4',OutputFolder),'-dtiff')
    else
     pr_yr.time=NaN;
     pr_yr.pr=NaN;  
    end


end
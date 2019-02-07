function [data] = CalculatePrecipitation(data,data_HIRHAM,station, OutputFolder,vis)
% This function calculates the precipitation at a AWS. Choice is given
% between different approach (see function Precipitation.m). It also reads
% the modelled precipitation from HIRHAM output, scales it using available
% station-derived precipitation and uses it to fill the gap in the
% station-derived series.
%
% Baptiste Vandecrux
% b.vandecrux@gmail.com
% 2018
% =========================================================================

    c.precip_scheme = 3;
    c.T_0 = 273.15;
    c.prec_rate = 0.001;
    c.sigma = 5.67 * 10^-8; 
    c.dt_obs = 3600;
    c.dev = 1;
    c.rho_snow = ones(size(data.time)) * 315;
    c.station = station;
    c.verbose = 1;
    c.mean_accum = 0.3;
    c.rho_water = 1000;
    c.OutputFolder = sprintf('./Output/%s',c.station);

    DV  = datevec(data.time);  % [N x 6] array

    time_decyear = DV(:,1) + ...
        (datenum(DV(:,1),DV(:,2),DV(:,3))-datenum(DV(:,1),1,1))...
        ./(datenum(DV(:,1),12,32)-datenum(DV(:,1),1,1));
    
c.vis = vis;
    

    [data.Snowfallmweq, ~, ~, c] = Precipitation(time_decyear, data.AirTemperature1C,...
        data.LongwaveRadiationDownWm2, data.RelativeHumidity1Perc, data.SurfaceHeightm, c);
    
    data.Snowfallmweq(isnan(data.SurfaceHeightm))=NaN;
    
    data_before = data;
    
        % selecting indexes on which correction will be calculated
        ind1_HH = find(~isnan(data_HIRHAM.Snowfallmweq),1,'first');
        ind2_HH = find(~isnan(data_HIRHAM.Snowfallmweq),1,'last');

        time_HH = data_HIRHAM.time(ind1_HH:ind2_HH);
        pr_HH = data_HIRHAM.Snowfallmweq(ind1_HH:ind2_HH);

        ind_start = max(find(~isnan(data.Snowfallmweq),1,'first'),...
            find(data.Snowfallmweq~=0,1,'first'));
        ind_end = find(~isnan(data.Snowfallmweq),1,'last');

        time_obs = data.time(ind_start:ind_end);
        pr_obs = data.Snowfallmweq(ind_start:ind_end);
        pr_obs(isnan(pr_obs)) = nanmean(pr_obs);

        pr_HH(time_HH<time_obs(1)) = [];
        time_HH(time_HH<time_obs(1)) = [];

        pr_HH(time_HH>time_obs(end)) = [];
        time_HH(time_HH>time_obs(end)) = [];

        pr_obs(time_obs<time_HH(1)) = [];
        time_obs(time_obs<time_HH(1)) = [];

        pr_obs(time_obs>time_HH(end)) = [];
        time_obs(time_obs>time_HH(end)) = [];
        
         pr_HH(time_HH<time_obs(1)) = [];
        time_HH(time_HH<time_obs(1)) = [];

        pr_HH(time_HH>time_obs(end)) = [];
        time_HH(time_HH>time_obs(end)) = [];
        
    f = figure('Visible',vis);
    plot(data.time,data.Snowfallmweq,'LineWidth',1.5)
    hold on
    plot(data_HIRHAM.time(~isnan(data_HIRHAM.Snowfallmweq)),...
            data_HIRHAM.Snowfallmweq(~isnan(data_HIRHAM.Snowfallmweq)),...
            'LineWidth',1.5)
    datetick('x','mm-yyyy')
      axis tight
    legend('station','HIRHAM')
    title(station)
    xlabel('Time')
    ylabel('Precipitation (m weq)')
    orient('landscape')
    print(f,sprintf('%s/precip1',OutputFolder),'-dpdf')

    f = figure('Visible',vis);
    subplot(1,2,1)
    scatter(cumsum(pr_HH),cumsum(pr_obs))
    hold on
    plot([0 max(cumsum(pr_obs))],[0 max(cumsum(pr_obs))])
    axis tight square
    box on
    title('before tuning')
    xlabel('HIRHAM cumulated precipitation (m weq)')
ylabel('AWS cumulated precipitation (m weq)')

    model = fitlm(cumsum(pr_HH),cumsum(pr_obs));
    % applying correction
    data_HIRHAM.Snowfallmweq = data_HIRHAM.Snowfallmweq * model.Coefficients.Estimate(2);
    
        % recalculating
         ind1_HH = find(~isnan(data_HIRHAM.Snowfallmweq),1,'first');
        ind2_HH = find(~isnan(data_HIRHAM.Snowfallmweq),1,'last');

        time_HH = data_HIRHAM.time(ind1_HH:ind2_HH);
        pr_HH = data_HIRHAM.Snowfallmweq(ind1_HH:ind2_HH);

        ind_start = max(find(~isnan(data.Snowfallmweq),1,'first'),...
            find(data.Snowfallmweq~=0,1,'first'));
        ind_end = find(~isnan(data.Snowfallmweq),1,'last');

        time_obs = data.time(ind_start:ind_end);
        pr_obs = data.Snowfallmweq(ind_start:ind_end);
        pr_obs(isnan(pr_obs)) = nanmean(pr_obs);

        pr_HH(time_HH<time_obs(1)) = [];
        time_HH(time_HH<time_obs(1)) = [];

        pr_HH(time_HH>time_obs(end)) = [];
        time_HH(time_HH>time_obs(end)) = [];

        pr_obs(time_obs<time_HH(1)) = [];
        time_obs(time_obs<time_HH(1)) = [];

        pr_obs(time_obs>time_HH(end)) = [];
        time_obs(time_obs>time_HH(end)) = [];

         pr_HH(time_HH<time_obs(1)) = [];
        time_HH(time_HH<time_obs(1)) = [];

        pr_HH(time_HH>time_obs(end)) = [];
        time_HH(time_HH>time_obs(end)) = [];
    
        
        subplot(1,2,2)
    scatter(cumsum(pr_HH),cumsum(pr_obs))
    hold on
    plot([0 max(cumsum(pr_obs))],[0 max(cumsum(pr_obs))])
    axis tight square
    box on
xlabel('HIRHAM cumulated precipitation (m weq)')
ylabel('AWS cumulated precipitation (m weq)')
    title(sprintf('After tuning (x %0.2f)',model.Coefficients.Estimate(2)))
    print(f,sprintf('%s/precip2',OutputFolder),'-dtiff')

    % Replacing values
    %     [data] = RecoverData('HIRHAM',data,'Snowfallmweq',...
    %     data_HIRHAM,'Snowfallmweq', vis,'yes',OutputFolder);
    ind_common = and(data.time<=data_HIRHAM.time(end)+0.0001,...
        data.time>=data_HIRHAM.time(1)-0.0001);
    data1 = data(ind_common,:);
    
    ind_common_2 = and(data_HIRHAM.time<=data.time(end)+0.0001,...
        data_HIRHAM.time>=data.time(1)-0.0001);
    data3 = data_HIRHAM(ind_common_2,:); 
    
	data.Snowfallmweq_Origin(isnan(data1.Snowfallmweq)) = 4;

    data1.Snowfallmweq(isnan(data1.Snowfallmweq)) = ...
        data3.Snowfallmweq(isnan(data1.Snowfallmweq));
    data.Snowfallmweq(ind_common) = data1.Snowfallmweq;
    
    data.Snowfallmweq(isnan(data.Snowfallmweq)) = ...
        nanmean(data.Snowfallmweq);
    
    f = figure('Visible',vis);
    subplot(2,1,1)
    plot(data.time,data.Snowfallmweq,'LineWidth',1.5)
    hold on
    plot(data_before.time,data_before.Snowfallmweq,'LineWidth',1.5)
    datetick('x','mm-yyyy')
      axis tight
    xlabel('Time')
    ylabel('Precipitation (m weq)')
    title(station)

    subplot(2,1,2)
    plot(data.time,cumsum(data.Snowfallmweq),'LineWidth',1.5)
    datetick('x','mm-yyyy')
      axis tight
    xlabel('Time')
    ylabel('Cumulated precipitation \newline             (m weq)','Interpreter','tex')
    print(f,sprintf('%s/precip3',OutputFolder),'-dtiff')
    
    pr = table(data.time,data.Snowfallmweq);
    pr.Properties.VariableNames = {'time','pr'};
    pr_yr = AvgTable(pr,'yearly','sum');
    
    
    f = figure('Visible',vis);
    plot(pr_yr.time,pr_yr.pr,'--o')
    hold on
    Plotlm(pr_yr.time,pr_yr.pr);
    plot(data.time,data.SurfaceHeightm/20)
    title(station)
    datetick('x','mm-yy')
    print(f,sprintf('%s/precip4',OutputFolder),'-dtiff')

end
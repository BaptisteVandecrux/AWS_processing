function [data] = AdjustHeight(data,station,OutputFolder, vis)
% This function reads the maintenance information of a station and shift the
% surface height record by the appropriate distance whenever the sonic
% ranger was raised or lowered during maintenance. It also performes some
% smoothing and averages the observation from the two sonic rangers.
%
% Baptiste Vandecrux
% b.vandecrux@gmail.com
% 2018
% ========================================================================

%% load maintenance data
    maintenance = ImportMaintenanceFile(station);
% vis = 'on'
    H_1_before = maintenance.SR1beforecm ; % height of first sensor before maintenance
    H_2_before = maintenance.SR2beforecm; % height of second sensor before maintenance
    H_1_after = maintenance.SR1aftercm; % height of first sensor after maintenance
    H_2_after = maintenance.SR2aftercm; % height of second sensor after maintenance
            date_change = maintenance.date;

    % convert data into time series object for easier manipulation
    H_1_ts = timeseries(data.SnowHeight1m, data.time,'Name', 'Height Sonic Ranger (1)');
    H_2_ts  = timeseries(data.SnowHeight2m, data.time,'Name', 'Height Sonic Ranger (2)');

%% applying shifts to rconstruct surface height
    H_1_ts_new = H_1_ts;
    H_2_ts_new = H_2_ts;
   
        % the shifting is done in the function below
        disp('SR1')
        [H_1_ts_new] =...
            HeightCorrection(H_1_ts_new, date_change, ...
            H_1_before, H_1_after, OutputFolder,'_1');
        
        disp('SR2')
        [H_2_ts_new] =...
            HeightCorrection(H_2_ts_new, date_change,...
            H_2_before, H_2_after, OutputFolder,'_2');
           
%% plot surface height adjustment process
    f = figure('Visible',vis);
    ha = tight_subplot(2,2,.01, [.2 .01], 0.15);
    
            set(f,'CurrentAxes',ha(1)) 
    plot(H_1_ts)
    axis tight
    box on
    ylimit=get(gca,'YLim');
    for i =1:length(date_change)
        if datenum(date_change(i))<min(data.time) ||datenum(date_change(i)) > max(data.time)
            continue
        end
        h = line(datenum([date_change(i) date_change(i)]),[ylimit(1), ylimit(2)]);
        h.Color ='r';
        h.LineWidth = 2;
    end
    set_monthly_tick(data.time); 
    set(gca,'XTickLabels',[]);
    handle = title('from SR#1 before adjustment');
    v = axis;
    set(handle,'Units','normalized'); 
    set(handle,'Position',[0.5 0.9]); 
    box on

            set(f,'CurrentAxes',ha(3)) 
    plot(H_1_ts_new)
    axis tight
    ylimit=get(gca,'YLim');
    for i =1:length(date_change)
        if datenum(date_change(i))<min(data.time) ||datenum(date_change(i)) > max(data.time)
            continue
        end
        h = line(datenum([date_change(i) date_change(i)]),[ylimit(1), ylimit(2)]);
        h.Color ='r';
        h.LineWidth = 2;
    end
    set_monthly_tick(data.time);

    box on
    xlabel('Date')
    handle = title('from SR#1 after adjustment');
         v = axis;
         set(handle,'Units','normalized'); 
         set(handle,'Position',[0.5 0.9]); 
    box on

    if sum(~isnan(H_2_ts.Data))>10
                set(f,'CurrentAxes',ha(2)) 
        plot(H_2_ts)
        axis tight
        ylimit=get(gca,'YLim');
        for i =1:length(date_change)
            if datenum(date_change(i))<min(data.time) ||datenum(date_change(i)) > max(data.time)
                continue
            end
            h = line(datenum([date_change(i) date_change(i)]),[ylimit(1), ylimit(2)]);
            h.Color ='r';
            h.LineWidth = 2;
        end
        axis tight
        box on
        set(gca,'yaxislocation','right','XTickLabel',[]);
        set_monthly_tick(data.time);
        handle = title('from SR#2 before adjustment');
        %         v = axis;
        set(handle,'Units','normalized');
        set(handle,'Position',[0.5 0.9]);
        
        set(f,'CurrentAxes',ha(4))
        plot(H_2_ts_new)
        axis tight
        box on
        ylimit=get(gca,'YLim');
        for i =1:length(date_change)
            if datenum(date_change(i))<min(data.time) ||datenum(date_change(i)) > max(data.time)
                continue
            end
            h = line(datenum([date_change(i) date_change(i)]),[ylimit(1), ylimit(2)]);
            h.Color ='r';
            h.LineWidth = 2;
        end
        axis tight
        set_monthly_tick(data.time);
        datetick('x','yyyy', 'keeplimits', 'keepticks')
        xticklabels = get(gca,'XTickLabel');
        for i =1:length(xticklabels)
            if floor(i/2)==i/2
                xticklabels(i,:) = '    ';
            end
        end
        set(gca,'XTickLabel',xticklabels);
        xlabel('Date')
        set(gca,'yaxislocation','right');
        handle = title('from SR#2 after adjustment');
        v = axis;
        set(handle,'Units','normalized');
        set(handle,'Position',[0.5 0.9]);
        legend('data', 'maintenance on the station','Location','SouthEast')
    else
        legend('data', 'maintenance on the station','Location','SouthEast')
        set(ha(2),'Visible','off')
        set(ha(4),'Visible','off')
    end
    print(f, sprintf('%s/Height_adj',OutputFolder), '-dpng')
    
    f = figure('Visible',vis);
    plot(H_1_ts_new), hold on, plot(H_2_ts_new)
    axis tight
    ylimit = get(gca,'YLim');
    for i =1:length(date_change)
        if datenum(date_change(i))<min(data.time) ||datenum(date_change(i)) > max(data.time)
            continue
        end
        h = line(datenum([date_change(i) date_change(i)]),[ylimit(1), ylimit(2)]);
        h.Color ='r';
        h.LineWidth = 1.5;
    end
    axis tight
    legend('Sonic ranger #1','Sonic ranger #2', 'Maintenance','Location','SouthEast')
    set_monthly_tick(data.time);
    ylabel('Surface Height (m)')
    xlabel('Date')
    title(station)
    print(f, sprintf('%s/Height_align',OutputFolder), '-dpng')
    
     %% smoothing instrument height
    % Prepair surface height data
    hampel_period = 24*10;
    hampel_var = 0.001;

    [H_1_ts_smoothed] = PrepairSurfaceHeight(H_1_ts_new,hampel_period,hampel_var);
    [H_2_ts_smoothed] = PrepairSurfaceHeight(H_2_ts_new,hampel_period,hampel_var);
    
    f = figure('Visible',vis);
    ha = tight_subplot(2,1,.01, [.2 .01], 0.15);
    set(f,'CurrentAxes',ha(1)) 
    hold on
    plot(H_1_ts,'LineWidth',2)
    plot(H_1_ts_smoothed,'LineWidth',2) 
    set_monthly_tick(H_1_ts.Time)
    axis tight
    set(gca,'XTickLabel','')
    xlabel('')
    ylabel('Surface height (m)')
    ylim([min(H_1_ts_smoothed.Data) max(H_1_ts_smoothed.Data)])
    
    if sum(~isnan(H_2_ts.Data))>10
        set(f,'CurrentAxes',ha(2)) 
        hold on
        plot(H_2_ts,'LineWidth',2)
        plot(H_2_ts_smoothed,'LineWidth',2)
        set_monthly_tick(H_1_ts.Time)
        axis tight
        xlabel('')
        ylabel('Surface height (m)')
        ylim([min(H_2_ts_smoothed.Data) max(H_2_ts_smoothed.Data)])
    end
    print(f, sprintf('%s/Height_smoothing',OutputFolder), '-dpng')
%% Merge the readings of the two sonic rangers:
    % Warning: taking the nan-mean of the two sonic ranger heights leads to
    % artificial shifts:
    % H1= [1 1 1 1]; 
    % H2= [3 3 3 NaN];
    % nanmean(H1,H2) = [2 2 2 1];
    % to avoid that we apply nanmean to the hourly increments and
    % reconstruct the surface height from that

    %     H_merged = nanmean([H_1_ts_new.Data ,H_2_ts_new.Data],2 );
    dH1 = 0*H_1_ts_smoothed.Data;
    dH2 = 0*H_2_ts_smoothed.Data;
     
    dH1(2:end) = H_1_ts_smoothed.Data(2:end)-H_1_ts_smoothed.Data(1:end-1);
%     dH1(isnan(dH1)) = 0;
    dH2(2:end) = H_2_ts_smoothed.Data(2:end)-H_2_ts_smoothed.Data(1:end-1);
%     ind = and(isnan(dH1), ~isnan(dH1));
%     dH1(ind) = 0;
%     dH2 = NaN*H_2_ts_smoothed.Data;
    dH1(dH1>2) = NaN;
    dH2(dH2>2) = NaN;

    aux = nanmean([dH1, dH2],2);
    aux(isnan(aux)) = 0;

    H_merged = cumsum(aux) + H_1_ts_smoothed.Data(find(~isnan(H_1_ts_smoothed.Data),1,'first'));
    H_merged(isnan(nanmean([H_1_ts_smoothed.Data ,H_2_ts_smoothed.Data],2)))= NaN;
    
    % now we need to realign the reconstructed
    prev_is_nan = [0; isnan(H_merged(1:end-1))];
    is_non_nan = ~isnan(H_merged);
    is_end_of_gap = find(and(prev_is_nan,is_non_nan));


    for i = 1:length(is_end_of_gap)
        H_merged(is_end_of_gap(i):end) = H_merged(is_end_of_gap(i):end) - H_merged(is_end_of_gap(i)) ...
            + nanmean([H_1_ts_smoothed.Data(is_end_of_gap(i)),H_2_ts_smoothed.Data(is_end_of_gap(i))]);    
    end
% figure
% hold on
% plot(H_1_ts_smoothed,'o-')
% plot(H_2_ts_smoothed,'o-')
% plot(H_1_ts_smoothed.Time,H_merged,'o-')
%         plot(H_1_ts_smoothed.Time,H_merged,'o-')
% 
% datetick('x')


%% saving result
    % updating the dataset 'data' with the merged and processed surface height
    data.SurfaceHeightm = H_merged ;
        
end



 
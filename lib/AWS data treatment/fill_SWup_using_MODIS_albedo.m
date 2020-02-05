function [data, data_modis] = fill_SWup_using_MODIS_albedo(...
    data, station, is_GCnet, OutputFolder , AlbedoStandardValue, data_RCM, vis)
% this function loads MODIS albedo for GCnet or PROMICE stations and
% applies it on the available downward shortwave radiation to reconstruct
% missing upward shortwave radiation
    
% Uploading MODIS albedo data
try data_modis = LoadMODISalbedo(is_GCnet,station);
catch me
    disp('WARNING: MODIS data not found')
    data_modis = [];
end
try data_AVHRR = LoadAVHRRalbedo(station);
catch me
    disp('WARNING: AVHRR data not found')
    data_AVHRR = data_modis;
    data_AVHRR.albedo = data_modis.time*NaN;
end

if ~isempty(data_modis)
    
    %% station, MODIS and AVHRR albedo climatology
    avg_modis = NaN(1,365);
    for i = 62 :301
        avg_modis(i) = nanmean(data_modis.albedo(data_modis.day==i));
    end
    avg_modis(isnan(avg_modis)) = AlbedoStandardValue;
    
    avg_avhrr = NaN(1,365);
    for i = 62 :301
        avg_avhrr(i) = nanmean(data_AVHRR.albedo(data_AVHRR.day==i));
    end
    avg_avhrr(isnan(avg_avhrr)) = AlbedoStandardValue;

    % Now we calculate the albedo given by the station
    albedo = data.ShortwaveRadiationUpWm2./data.ShortwaveRadiationDownWm2;
    albedo(albedo>1)=NaN;
    albedo(albedo<0.5)=NaN;
    albedo(data.ShortwaveRadiationUpWm2_Origin~=0) = NaN;
    albedo_station = table(data.time,...
        albedo,...
        'VariableNames',{'time','albedo'});
    albedo_station = AvgTable(albedo_station,'daily','mean');

    DV  = datevec(albedo_station.time);  % [N x 6] array
    DV  = DV(:, 1:3);   % [N x 3] array, no time
    DV2 = DV;
    DV2(:, 2:3) = 0;    % [N x 3], day before 01.Jan
    albedo_station.day=datenum(DV) - datenum(DV2);
    albedo_station.year=DV(:,1);

    albedo_avg_station = NaN(1,365);

    for i = 62 :301
        albedo_avg_station(i) = nanmean(albedo_station.albedo(albedo_station.day==i));
    end
    albedo_avg_station(isnan(albedo_avg_station)) = 0.8;

    %% Plotting climatologies
    f = figure('Visible',vis);
    [ha, ~] = tight_subplot(1, 3, 0.1, [0.15 0.15], 0.1);
    set(f,'CurrentAxes',ha(1))
        hold on
        list_year = unique(data_modis.year);
        leg_text = cell(0);

        for i=1:length(list_year)
            temp = data_modis(data_modis.year==list_year(i),:);
            plot(temp.day,temp.albedo)
            leg_text = [leg_text, num2str(list_year(i))];
        end

        plot(62:301,avg_modis(62:301),'r','LineWidth',4)
        leg_text = [leg_text, 'Average'];

%         legendflex(leg_text, 'ref', gca, ...
%                            'anchor',  [2 6] , ...
%                            'buffer',[0 10], ...
%                            'ncol',3, ...
%                            'fontsize',13);
        axis tight
        box on
        ylabel('Albedo')
        title('MODIS')
        xlabel('Day of the year')
        xlimit = get(gca,'XLim');
    ylim([0.5 1])

    set(f,'CurrentAxes',ha(2))
        hold on
        list_year = unique(data_AVHRR.year);
%         leg_text = cell(0);

        for i=1:length(list_year)
            temp = data_AVHRR(data_AVHRR.year==list_year(i),:);
            plot(temp.albedo)
%             leg_text = [leg_text, num2str(list_year(i))];
        end

        plot(62:301,avg_avhrr(62:301),'r','LineWidth',4)
%         leg_text = [leg_text, 'Average'];
%         legendflex(leg_text, 'ref', gca, ...
%                            'anchor',  [2 6] , ...
%                            'buffer',[0 10], ...
%                            'ncol',3, ...
%                            'fontsize',13);
        axis tight
        box on
        ylabel('Albedo')
        title('AVHRR')
        xlabel('Day of the year')
        xlimit = get(gca,'XLim');
    ylim([0.5 1])

    set(f,'CurrentAxes',ha(3))
        hold on
        list_year = unique(albedo_station.year);
        leg_text = cell(0);

        for i=1:length(list_year)
            temp = albedo_station(albedo_station.year==list_year(i),:);
            plot(temp.day,temp.albedo)
            leg_text = [leg_text, num2str(list_year(i))];
        end

    plot(62:301,albedo_avg_station(62:301),'r','LineWidth',4)
    leg_text = [leg_text, 'Average'];
    title('Weather station')
%     legendflex(leg_text, 'ref', gca, ...
%                        'anchor',  [2 6] , ...
%                        'buffer',[0 10], ...
%                        'ncol',3, ...
%                        'fontsize',13);
    ylabel('Albedo')
    xlabel('Day of the year')
    xlim(xlimit)
    ylim([0.5 1])
    box on
    print(f, sprintf('%s/albedo_MODIS_station_climatology',OutputFolder), '-dpng')
    
    %% cropping albedo data
    ind = and(data_modis.time<=data.time(end),...
        data_modis.time>=data.time(1));
    data_modis = data_modis(ind,:);
    ind = and(data_AVHRR.time<=data.time(end),...
        data_AVHRR.time>=data.time(1));
    data_AVHRR = data_AVHRR(ind,:);

    %% Plotting yearly comparison
    DV = datevec(data.time);
    list_year = unique(DV(:,1));
    list_year = list_year(or(ismember(list_year,data_modis.year),...
        ismember(list_year,data_AVHRR.year)));
%     here are plotted all the year by year comparison of MODIS vs. station
%     albedos

    f = figure('Visible',vis);
    ha = tight_subplot(4,4, [0.03 0.01],[0.15 0.15],0.05);
    count = 0;
    count_plot =1;
    for i = 1:length(list_year)
        count = count+1;
        if count == 17
                print(f, sprintf('%s/albedo_yearly_comp_%i',OutputFolder,count_plot), '-dpng')
                count_plot = count_plot+1;
                
                f = figure('Visible',vis);
                ha = tight_subplot(4,4, [0.03 0.01],[0.15 0.15],0.05);
                count = 1;
        end
        temp = albedo_station(albedo_station.year==list_year(i),:);
        temp2 = data_modis(data_modis.year==list_year(i),:);
        temp3 = data_AVHRR(data_AVHRR.year==list_year(i),:);
        if ~isempty(temp)
            set(f,'CurrentAxes',ha(count))
            hold on
            plot(temp.time,temp.albedo,'r','LineWidth',2)
            if ~isempty(temp2)
                plot(temp2.time,temp2.albedo,'b','LineWidth',2)
            end
            if ~isempty(temp3)
                ind_d = and(temp3.day>=62,temp3.day<=301);
                plot(temp3.time(ind_d),temp3.albedo(ind_d),'m','LineWidth',2)
            end
            h_title = title(num2str(list_year(i)));
            h_title.Units = 'normalized';
            h_title.Position(1:2) = [.15 .03];
            if count==3
                h1 = plot(temp.time,temp.time,'r','LineWidth',2);
                h2 = plot(temp.time,temp.time,'b','LineWidth',2);
                h3 = plot(temp.time,temp.time,'m','LineWidth',2);
                legendflex([h1 h2 h3], {'AWS','MODIS','AVHRR'},'ref',gcf','anchor',{'n', 'n'},'nrow',1,'title',sprintf('Daily albedo at %s',station))
            end
            set_monthly_tick(temp.time)
            xlim(temp.time([1 end]))
        else
            set(ha(count),'Visible','off')
            
        end
            axis fill
            ylim([0.6 1])
            if ismember(count, 13:16)
                datetick('x','dd-mmm', 'keepticks', 'keeplimits')
                xticklabels = get(gca,'XTickLabel');
                for ii =1:length(xticklabels)
                    if floor(ii/2)==ii/2
                        xticklabels(ii,:) = '      ';
                    end
                end
                datetick('x','dd-mmm', 'keepticks', 'keeplimits')
                set(gca,'XTickLabel',xticklabels)
                set(gca, 'XTickLabelRotation',45)
            else
                xticklabels = get(gca,'XTickLabel');
                set(gca,'XTickLabel','')
            end
            if ismember(count, 4:4:16)
                set(gca,'YAxisLocation','right')
            elseif ~ ismember(count, 1:4:13)
                set(gca,'YTickLabel','')
            end

            box on
            set (gca,'XMinorTick','off','YMinorTick','on')
%             datetick('x','dd/mm','keeplimits','keepticks')
    end
    for i = 1:count
        set(ha(i),'XTickLabel',xticklabels)
        set(ha(i), 'XTickLabelRotation',45)
    end
    for i = count+1:16
                    set(ha(i),'Visible','off')
    end

    print(f, sprintf('%s/albedo_yearly_comp_%i',OutputFolder,count_plot), '-dpng')

    %% Reconstructing SWup
    if ~isempty(data_modis)
        f = figure('Visible',vis);
        plot(albedo_station.time,albedo_station.albedo)
        hold on
        plot(data_modis.time,data_modis.albedo,'LineWidth',2)
        set_monthly_tick(albedo_station.time);

        ts1 = timeseries(albedo_station.albedo,albedo_station.time);
        ts2 = timeseries(data_modis.albedo, data_modis.time);

        [ts1, ts2] = synchronize(ts1,ts2,'union');
        DV = datevec(ts1.Time);
        ind_nan = ~ismember(DV(:,2),[6 7 8]);
        ts2.Data(ind_nan) = NaN;
        ME = nanmean(ts1.Data-ts2.Data);
        title(num2str(ME));
    
        axis tight
    %     xlim([datenum('01-Jan-2000') datenum('01-Jan-2011')])
        set(gca,'YMinorTick','on','XMinorTick','on')
        ylabel('Albedo')
        xlabel('Date')
        legend('AWS','MODIS C6','Location','SouthEast')
        print(f, sprintf('%s/albedo_MODIS_station',OutputFolder), '-dpng')

        if sum(~isnan(data_modis.albedo))>10
            data_modis.albedo = interp1gap(data_modis.albedo)';
        end
        data.ShortwaveRadiationUpWm2(...
            data.ShortwaveRadiationUpWm2<0) = NaN;
        data.ShortwaveRadiationDownWm2(...
            data.ShortwaveRadiationDownWm2<0) = NaN;

        % reconstructing missing upward shortwave radiation flux using the observed
        % downward and the modis-derived albedo

        % creating variable that will receive the MODIS or average albedo
        data_modis_new = table;

        % assigning in that new variable the MODIS albedo whenever is possible
        ind_binned = discretize(data.time,data_modis.time);
        data_modis_new.time = data.time;
        data_modis_new.albedo = NaN(size(data_modis_new.time));
    %     index in newtime when modis is available
        ind_modis_newtime = ~isnan(ind_binned);
        data_modis_new.albedo(ind_modis_newtime) = ...
            data_modis.albedo(ind_binned(ind_modis_newtime));
    else
        data_modis_new = table;
        data_modis_new.time = data.time;
        data_modis_new.albedo = NaN(size(data_modis_new.time));
    end

    % where there is no modis albedo we need to take it from the
    % station climatology
    DV  = datevec(data.time);  % [N x 6] array
    DV  = DV(:, 1:3);   % [N x 3] array, no time
    DV2 = DV;
    DV2(:, 2:3) = 0;    % [N x 3], day before 01.Jan
    DayOfYear=datenum(DV) - datenum(DV2);
    DayOfYear (DayOfYear== 366)= 365;

    data_modis_new.albedo(isnan(data_modis_new.albedo)) = ...
        albedo_avg_station(DayOfYear(isnan(data_modis_new.albedo)));
    % if there is still some places where neither station ormodis albedo
    % were available, then we use the standard value
    data_modis_new.albedo(isnan(data_modis_new.albedo)) = AlbedoStandardValue;
    
    %now we should have modis/station/standard albedo for all time step
    % so we can gapfill the missing upward radiation
    data_old = data;
             
    ind_replaced = isnan(data.ShortwaveRadiationUpWm2);
    ind_replaced(data.time>datenum(2018,1,1)) = 0;
    
    data.ShortwaveRadiationUpWm2_Origin(ind_replaced) = 5;
    data.ShortwaveRadiationUpWm2(ind_replaced) = ...
        data.ShortwaveRadiationDownWm2(ind_replaced) ...
        .* data_modis_new.albedo(ind_replaced);

    if data.time(end)>today()
        ind_future = data.time>datenum(2018,1,1);
        data.ShortwaveRadiationUpWm2_Origin(ind_future) = 4;
        ind_RCM = and(data_RCM.time>datenum(2018,1,1),...
            data_RCM.time<=data.time(find(ind_future,1,'last')));
        data_RCM.albedo = data_RCM.rsus./data_RCM.ShortwaveRadiationDownWm2;
        data_RCM.albedo(data_RCM.albedo>0.9) = 0.9;
        data_RCM.albedo(data_RCM.albedo<0.4) = 0.4;
        data.ShortwaveRadiationUpWm2(ind_future) = ...
            data.ShortwaveRadiationDownWm2(ind_future) ...
            .* data_RCM.albedo(ind_RCM);
    end
    
    data.ShortwaveRadiationUpWm2(data.ShortwaveRadiationUpWm2<0) = NaN;
    data.ShortwaveRadiationUpWm2(isnan(data.ShortwaveRadiationUpWm2)) =...
        AlbedoStandardValue*data.ShortwaveRadiationDownWm2(isnan(data.ShortwaveRadiationUpWm2));

    % plotting result
    f = figure('Visible',vis);
    h1 = plot(data.time, data.ShortwaveRadiationUpWm2);
    hold on
    h2 = plot(data_old.time,data_old.ShortwaveRadiationUpWm2);
    axis tight
    set_monthly_tick(data.time);
    datetick('x','yyyy','keeplimits','keepticks')
    xlabel('Time')
    ylabel('Upward shortwave radiation (W/m^2)')
    legend([h2 h1],'available data', 'calculated using MODIS albedo')
    set(gca,'XTickLabelRotation',45)
    print(f, sprintf('%s/albedo_gapfilled_upSW',OutputFolder), '-dpng')

    data.ShortwaveRadiationDownWm2(...
        data.ShortwaveRadiationUpWm2 >= 0.97*data.ShortwaveRadiationDownWm2) = ...
        data.ShortwaveRadiationUpWm2(...
        data.ShortwaveRadiationUpWm2 >= 0.97*data.ShortwaveRadiationDownWm2)./0.95;
end
end
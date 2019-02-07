function data = TreatAndFilterData(data, opt, station,OutputFolder,vis)
% Basic data processing and filtering

% in the text files missing data is either 999 or -999
% we change them into Matlab's 'NaN'
data = standardizeMissing(data,{999,-999});

%% Resampling at each round hour to synchronize all stations   
data = ResampleTable(data);

%% converting humidity
% The instruments on PROMICE stations or HIRHAM model normally give 
% humidity with regard to water, but GCnet instruments give it with regards
% to ice. So we convert it back to humidity with regard to water for
% compatibility.
if strcmp(opt,'ConvertHumidity')
    RH_wrt_i = data.RelativeHumidity1Perc;
    T = data.AirTemperature3C + 273.15;
    pres = data.AirPressurehPa*100;
    data.RelativeHumidity1Perc = RHice2water(RH_wrt_i,T,pres);

    RH_wrt_i = data.RelativeHumidity2Perc;
    T = data.AirTemperature4C + 273.15;
    pres = data.AirPressurehPa*100;
    data.RelativeHumidity2Perc = RHice2water(RH_wrt_i,T,pres);
    clearvars  RH_wrt_i T pres
end

%% some filters for unlikely values
data.ShortwaveRadiationDownWm2(data.ShortwaveRadiationDownWm2<0) = NaN;
data.ShortwaveRadiationDownWm2(data.ShortwaveRadiationDownWm2>950) = NaN;
data.ShortwaveRadiationUpWm2(data.ShortwaveRadiationUpWm2<0) = NaN;
data.ShortwaveRadiationUpWm2(data.ShortwaveRadiationUpWm2>950) = NaN;
data.ShortwaveRadiationUpWm2(data.ShortwaveRadiationUpWm2>data.ShortwaveRadiationDownWm2) = NaN;
data.ShortwaveRadiationUpWm2(isnan(data.ShortwaveRadiationDownWm2)) = NaN;

if ismember('NetRadiationWm2',data.Properties.VariableNames)
data.NetRadiationWm2(data.NetRadiationWm2<-500) = NaN;
end
data.RelativeHumidity1Perc(data.RelativeHumidity1Perc<0) = NaN;
data.RelativeHumidity2Perc(data.RelativeHumidity2Perc<0) = NaN;
% data.RelativeHumidity1Perc(data.RelativeHumidity1Perc<40)=NaN;
% data.RelativeHumidity2Perc(data.RelativeHumidity1Perc<40)=NaN;
data.RelativeHumidity1Perc(data.RelativeHumidity1Perc>100) = 100;
data.RelativeHumidity2Perc(data.RelativeHumidity2Perc>100) = 100;

data.AirTemperature1C(data.AirTemperature1C<-70) = NaN;
data.AirTemperature1C(data.AirTemperature1C>40) = NaN;
data.AirTemperature2C(data.AirTemperature2C<-70) = NaN;
data.AirTemperature2C(data.AirTemperature2C>40) = NaN;
data.AirTemperature3C(data.AirTemperature3C<-70) = NaN;
data.AirTemperature3C(data.AirTemperature3C>40) = NaN;
data.AirTemperature4C(data.AirTemperature4C<-70) = NaN;
data.AirTemperature4C(data.AirTemperature4C>40) = NaN;
data.AirTemperature3C(data.AirTemperature3C<=-39) = NaN;
data.AirTemperature4C(data.AirTemperature4C<=-39) = NaN;

data.AirPressurehPa(data.AirPressurehPa<600)=NaN;

% issue with GCnetwind sensor during a time
    ind = and(data.WindSpeed2ms>9.5,...
    data.time<= datenum('19-Jun-1996'));
    data.WindSpeed2ms(ind)=NaN;
    ind = and(data.WindSpeed1ms>9.5,...
    data.time<= datenum('19-Jun-1996'));
    data.WindSpeed1ms(ind)=NaN;

% filter in terms of albedo
data.ShortwaveRadiationUpWm2( ...
    data.ShortwaveRadiationUpWm2 > ...
    0.95 * data.ShortwaveRadiationDownWm2) = NaN;
data.ShortwaveRadiationUpWm2( ...
    data.ShortwaveRadiationUpWm2 < ...
    0.35 * data.ShortwaveRadiationDownWm2) = NaN;

% periods when WS<0.01ms for more than 6 hours are considered erroneous
ind = data.WindSpeed1ms < 0.01;
no_wind_count = 0;
for i = 1:length(ind)
    if ind(i) == 1
        no_wind_count = no_wind_count +1;
    else
        if no_wind_count>6
            %too long period without wind, leaving flags up
        else
            % gap less than 6 hours putting down the flag
            ind((i-no_wind_count):(i-1)) = 0;
        end
    end
end

data.WindSpeed1ms(ind) = NaN;

ind = data.WindSpeed2ms < 0.01;
no_wind_count = 0;
for i = 1:length(ind)
    if ind(i) == 1
        no_wind_count = no_wind_count +1;
    else
        if no_wind_count>6
            %too long period without wind, leaving flags up
        else
            % gap less than 6 hours putting down the flag
            ind((i-no_wind_count):(i-1)) = 0;
        end
    end
end

data.WindSpeed2ms(ind) = NaN;

%% measurements less than 0.5m from the ground are discarded
data.WindSpeed1ms(data.WindSensorHeight1m < 0.5)=NaN;
data.WindSpeed2ms(data.WindSensorHeight2m < 0.5)=NaN;
data.AirTemperature1C(data.WindSensorHeight1m < 0.5)=NaN;
data.AirTemperature3C(data.WindSensorHeight1m < 0.5)=NaN;
data.AirTemperature2C(data.WindSensorHeight2m < 0.5)=NaN;
data.AirTemperature4C(data.WindSensorHeight2m < 0.5)=NaN;
data.RelativeHumidity1Perc(data.WindSensorHeight1m < 0.5)=NaN;
data.RelativeHumidity2Perc(data.WindSensorHeight2m < 0.5)=NaN;

%% measurements at unknown heights are discarded
if ~ismember(station,{'SwissCamp','KAN_U'})
    ind_issue = and(isnan(data.WindSensorHeight1m),~isnan(data.SnowHeight1m));
    
out     = zeros(size(ind_issue'));
aa      = [0,ind_issue',0];
ii      = strfind(aa, [0 1]);
out(ii) = strfind(aa, [1 0]) - ii;

    if max(out) > 3*24*30
        f= figure('Visible',vis);
        subplot(2,1,1)
        hold on
        plot(data.time, data.WindSensorHeight1m,'LineWidth',2)
        plot(data.time, data.SnowHeight1m,'LineWidth',2)
        legend('Wind sensor height','Snow height')
        ylabel('Height (m)')
        set_monthly_tick(data.time)
        set(gca,'XTickLabel','')
        axis tight
        subplot(2,1,2)
        hold on
        plot(data.time, data.WindSensorHeight2m,'LineWidth',2)
        plot(data.time, data.SnowHeight2m,'LineWidth',2)
        plot(data.time, ind_issue*5,'LineWidth',2)
        legend('Wind sensor height','Snow height')
        ylabel('Height (m)')
        xlabel('Year')
        set_monthly_tick(data.time)
        set(gca,'XTickLabelRotation',0)
        axis tight
        print(f, sprintf('%s/Height_reconstruction1',OutputFolder), '-dpng')

        maintenance = ImportMaintenanceFile(station);

        switch station
            case 'NASA-SE'
                date1 = '01-Jan-1998';
                date2 = '01-Jun-2005';
            case 'CP2'
                date1 = '01-Jan-1997';
                date2 = '01-Jun-2001';
        end

        ind_up = find(and(maintenance.date>=datenum(date1),maintenance.date<datenum(date2)));
        disp(datestr(maintenance.date(ind_up)))
        ind = and(data.time>=datenum(date1),data.time<datenum(date2));
        SurfaceHeight1 = -data.SnowHeight1m(ind);
        SurfaceHeight2 = -data.SnowHeight2m(ind);

        for i = 1: length(ind_up)-1
            ind_period = find(and(data.time(ind)>=maintenance.date(ind_up(i)),...
                min(maintenance.date(ind_up(i+1)),data.time(ind)<datenum(date2))));
            SurfaceHeight1(ind_period) = 2 + SurfaceHeight1(ind_period)...
                - SurfaceHeight1(ind_period(find(~isnan(SurfaceHeight1(ind_period)),1,'first')));
            SurfaceHeight2(ind_period) = 3.2 + SurfaceHeight2(ind_period)...
                - SurfaceHeight2(ind_period(find(~isnan(SurfaceHeight2(ind_period)),1,'first')));
        end
    %     SurfaceHeight1(SurfaceHeight1<0) = NaN;
    %     SurfaceHeight2(SurfaceHeight2<0) = NaN;

        f = figure('Visible',vis);
        plot(data.time(ind),SurfaceHeight1)
        hold on
        plot(data.time(ind),SurfaceHeight2)
        datetick('x')
        print(f, sprintf('%s/Height_reconstruction2',OutputFolder), '-dpng')

        data.WindSensorHeight1m(ind) = SurfaceHeight1;
        data.WindSensorHeight2m(ind) = SurfaceHeight2;
    end
end

%% Removing data for which height are unknown
    data.WindSpeed1ms(isnan(data.WindSensorHeight1m ))=NaN;
    data.WindSpeed2ms(isnan(data.WindSensorHeight2m ))=NaN;
    data.AirTemperature1C(isnan(data.WindSensorHeight1m ))=NaN;
    data.AirTemperature3C(isnan(data.WindSensorHeight1m ))=NaN;
    data.AirTemperature2C(isnan(data.WindSensorHeight2m ))=NaN;
    data.AirTemperature4C(isnan(data.WindSensorHeight2m ))=NaN;
    data.RelativeHumidity1Perc(isnan(data.WindSensorHeight1m ))=NaN;
    data.RelativeHumidity2Perc(isnan(data.WindSensorHeight2m ))=NaN;

%% smoothing
% see hampel filter and GCnet documentation for further details
%     data.AirTemperature1C = hampel(data.AirTemperature1C,10,1);
%     data.AirTemperature2C = hampel(data.AirTemperature2C,10,1);
%     data.RelativeHumidity1Perc = hampel(data.RelativeHumidity1Perc,10,1);
%     data.RelativeHumidity2Perc = hampel(data.RelativeHumidity2Perc,10,1);
%     data.RelativeHumidity2mPerc = hampel(data.RelativeHumidity2mPerc,10,1);
%     data.ShortwaveRadiationUpWm2 = hampel(data.ShortwaveRadiationUpWm2,5,1);
%     data.ShortwaveRadiationDownWm2 = hampel(data.ShortwaveRadiationDownWm2,5,1);
%     data.NetRadiationWm2 = hampel(data.NetRadiationWm2,5,1);
%     data.AirPressurehPa = hampel(data.AirPressurehPa,48,1); 

%%  Reconstructing temperatures from the two sensors 
% GCnet station have two temperature sensors for each of the two heights
% level. We decide to use first the data from the Thermo Couple sensor and 
% only when this one fails to use the CS500 sensor
        f = figure('Visible',vis);
        ha = tight_subplot(2,2,[0.15 0], [.15 .03], [0 0.02]);
        set(f,'CurrentAxes',ha(1))
        hold on
        scatter( data.AirTemperature1C, data.AirTemperature3C,'.')
        axis tight square
        box on
        ylimit = get(gca,'YLim');
        plot(ylimit,ylimit,'k');
        xlabel('TC level 1')
        ylabel('CS500 level 1')
        
        set(f,'CurrentAxes',ha(3))
        scatter( data.AirTemperature2C, data.AirTemperature4C,'.')
        hold on
        box on
        ylimit = get(gca,'YLim');
        plot(ylimit,ylimit,'k');
        axis tight square
        xlabel('TC level 2')
        ylabel('CS500 level 2')

% at level 1
    set(f,'CurrentAxes',ha(2));
    plot(data.time,data.AirTemperature3C)    
    hold on
    plot(data.time, data.AirTemperature1C)
    axis tight
    xlim([data.time(1) data.time(end)]);
%     set_monthly_tick(data.time); 
    set(gca,'XTickLabel',[],'XMinorTick','on');
    ylabel('Air temperature at\newline level 1 (degC)','Interpreter','tex')
    legend('from CS500','from TC')

% Second Level      
    set(f,'CurrentAxes',ha(4));
    plot(data.time,data.AirTemperature4C)
    hold on
    plot(data.time, data.AirTemperature2C)
    axis tight
    xlim([data.time(1) data.time(end)]);
%     set_monthly_tick(data.time); 
    ylabel('Air temperature at\newline level 2 (degC)','Interpreter','tex')
    datetick('x','yyyy','keeplimits','keepticks')            
    xlabel('Date')
    title(station)
    legend('from CS500','from TC')
    set(gca,'XMinorTick','on');
    print(f, sprintf('%s/T_reconstruction_%s',OutputFolder,station), '-dpng')
    
    % from now AirTemperature1C, resp.AirTemperature2C, contains a combination of the thermocouple
    % and CS500 instruments level 1, resp. 2.
    data.AirTemperature1C(isnan(data.AirTemperature1C)) = ...
        data.AirTemperature3C(isnan(data.AirTemperature1C));
    data.AirTemperature2C(isnan(data.AirTemperature2C)) = ...
        data.AirTemperature4C(isnan(data.AirTemperature2C));

%% Instrument heights
% gaps in air temperature, RH or WS might be at different period. So the
% gap filling process might end up using, at a specific time step,
% temperature from the main station and relative humidity from the
% secondary. We therefor need to keep track of the individual instrument
% heights.
data.WindSensorHeight1m(data.WindSensorHeight1m<0) = NaN;
data.WindSensorHeight2m(data.WindSensorHeight2m<0) = NaN;
data.TemperatureSensorHeight1m(data.TemperatureSensorHeight1m<0) = NaN;
data.TemperatureSensorHeight2m(data.TemperatureSensorHeight2m<0) = NaN;
data.HumiditySensorHeight1m(data.HumiditySensorHeight1m<0) = NaN;
data.HumiditySensorHeight2m(data.HumiditySensorHeight2m<0) = NaN;

% Wind, temperature or humidity sensors that
ind_nan = isnan(data.WindSensorHeight1m );
data.WindSensorHeight1m = hampel(data.WindSensorHeight1m,24*14,0.01);
data.WindSensorHeight1m (ind_nan)=NaN;

ind_nan = isnan(data.WindSensorHeight2m );
data.WindSensorHeight2m = hampel(data.WindSensorHeight2m,24*14,0.01);
data.WindSensorHeight2m (ind_nan)=NaN;

ind_nan = isnan(data.TemperatureSensorHeight1m );
data.TemperatureSensorHeight1m = hampel(data.TemperatureSensorHeight1m,24*14,0.01);
data.TemperatureSensorHeight1m (ind_nan)=NaN;

ind_nan = isnan(data.TemperatureSensorHeight2m );
data.TemperatureSensorHeight2m = hampel(data.TemperatureSensorHeight2m,24*14,0.01);
data.TemperatureSensorHeight2m (ind_nan)=NaN;

ind_nan = isnan(data.HumiditySensorHeight1m );
data.HumiditySensorHeight1m = hampel(data.HumiditySensorHeight1m,24*14,0.01);
data.HumiditySensorHeight1m (ind_nan)=NaN;

ind_nan = isnan(data.HumiditySensorHeight2m );
data.HumiditySensorHeight2m = hampel(data.HumiditySensorHeight2m,24*14,0.01);
data.HumiditySensorHeight2m (ind_nan)=NaN;

%% plot Sensor Height and compare to the reported heights
    maintenance = ImportMaintenanceFile(station);
    date_change = maintenance.date;

    f = figure('Visible',vis);
    ha = tight_subplot(3,1,.01, [.2 .01], [0.1 0.05]);
   set(ha(1),'Visible','off');
    set(f,'CurrentAxes',ha(2));
    hold on
    plot(data.time, data.WindSensorHeight1m,'b','LineWidth',2)
    plot(data.time, data.TemperatureSensorHeight1m,'Color',RGB('dark green'),'LineWidth',2)
    scatter([datenum(maintenance.date); datenum(maintenance.date)], ...
        [maintenance.W1beforecm/100; maintenance.W1aftercm/100],...
        80,'b','o','filled', 'MarkerFaceColor', 'b')
    scatter([datenum(maintenance.date); datenum(maintenance.date)], ...
        [maintenance.T1beforecm/100; maintenance.T1aftercm/100],...
        80,[51,153,255]/255,'o','filled', 'MarkerFaceColor',RGB('dark green'))

    axis tight
    ylimit=get(gca,'YLim');
    for i = 1:length(date_change)
        h = line(datenum([date_change(i) date_change(i)]),[ylimit(1), ylimit(2)]);
        h.Color = [96,96,96]/255;
        h.LineWidth = 1;
    end
    legendflex({'Wind sensor height from SR',...
        'Temp sensor height from SR',...
        'Wind sensor height from report',...
        'Temp sensor height from report',...
        'Maintenance'}, 'ref', gcf, ...
                           'anchor', {'n','n'}, ...
                           'buffer',[0 -20], ...
                           'ncol',3, ...
                           'fontsize',15,...
                           'title',station,...
                           'Interpreter','none');
    ylabel_obj = ylabel('Height above the surface (m)','Interpreter','tex');
    ylabel_obj.Units = 'Normalized';
    ylabel_obj.Position(2) = ylabel_obj.Position(2)-0.4;
    xlim([data.time(1),data.time(end)])
    set_monthly_tick(data.time); 
    box on
%     h_title = title(station);
%     h_title.Units = 'normalized';
%     h_title.Position(2) = -0.9;
    handle = title('level 1');
     set(handle,'Units','normalized'); 
     set(handle,'Position',[0.95 0.8],'fontsize',15); 
     
     
     if sum(~isnan(data.WindSensorHeight2m))>10 
        set(gca,'XTickLabels',[]);

        set(f,'CurrentAxes',ha(3));
        hold on
        plot(data.time, data.WindSensorHeight2m,'k','LineWidth',2)
        scatter(datenum(maintenance.date),maintenance.W2beforecm/100,80,'b','o','filled', 'MarkerFaceColor', 'b')
        scatter(datenum(maintenance.date),maintenance.W2aftercm/100,80,'b','d','filled', 'MarkerFaceColor', 'b')
        scatter(datenum(maintenance.date),maintenance.T2beforecm/100,80,[51,153,255]/255,'o','filled', 'MarkerFaceColor', [51,153,255]/255)
        scatter(datenum(maintenance.date),maintenance.T2aftercm/100,80,[51,153,255]/255,'d','filled', 'MarkerFaceColor', [51,153,255]/255)

        axis tight
        ylimit=get(gca,'YLim');
        for i =1:length(date_change)
            h = line(datenum([date_change(i) date_change(i)]),[ylimit(1), ylimit(2)]);
            h.Color = [96,96,96]/255;
            h.LineWidth = 1;
        end
        handle = title('level 2');
         set(handle,'Units','normalized'); 
         set(handle,'Position',[0.95 0.8],'fontsize',15); 
         box on
         ylabel('')
        xlim([data.time(1),data.time(end)])
        set_monthly_tick(data.time); 
     else
         set(ha(3),'Visible','off')
     end
         
    orient(f,'landscape')
print(f, sprintf('%s/height_wind_temp_sensors',OutputFolder),'-dpdf')

% NOT USED ANYMORE: bigger holes are being filled with the other level
% data = FillingGapsUsingOtherLevel(data, 'AirTemperature1C','AirTemperature2C');
% data = FillingGapsUsingOtherLevel(data, 'AirTemperature2C','AirTemperature1C');
% data = FilingGapsUsingOtherLevel(data, 'RelativeHumidity1Perc','RelativeHumidity2Perc');
% data = FillingGapsUsingOtherLevel(data, 'RelativeHumidity2Perc','RelativeHumidity1Perc');
% data = FillingGapsUsingOtherLevel(data, 'WindSpeed1ms','WindSpeed2ms');
% data = FillingGapsUsingOtherLevel(data, 'WindSpeed2ms','WindSpeed1ms');

%% before anything we interpolate to fill the small gaps
data = InterpTable(data,6);

end
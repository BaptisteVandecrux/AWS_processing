function [data] = SpecialTreatmentCP1(data)
   
    %% Wind direction anomaly
    data = standardizeMissing(data,{999,-999});

    data.WindDirection1deg(8722:21485) = 360 - data.WindDirection1deg(8722:21485);
    data.WindDirection1deg(data.WindDirection1deg<0)= 360 + data.WindDirection1deg(data.WindDirection1deg<0);

    diff = nanmean(data.WindDirection1deg(17314:21485))...
        - nanmean(data.WindDirection2deg(17314:21485));

    data.WindDirection1deg(8722:21485) = data.WindDirection1deg(8722:21485) - diff;
    data.WindDirection1deg(data.WindDirection1deg<0)= 360 + data.WindDirection1deg(data.WindDirection1deg<0);

%         diff = nanmean(data.WindDirection1deg(17221:21485)) - nanmean(data_CP2.WindDirection1deg(1:4219));
    diff = 15.9515;
    data.WindDirection1deg(8722:21485) = data.WindDirection1deg(8722:21485) - diff;
    data.WindDirection1deg(data.WindDirection1deg<0)= 360 + data.WindDirection1deg(data.WindDirection1deg<0);

%         diff = nanmean(data.WindDirection2deg(17221:21485)) - nanmean(data_CP2.WindDirection2deg(1:4219));
    diff =    15.3678;
    data.WindDirection2deg(8722:21485) = data.WindDirection2deg(8722:21485) - diff;
    data.WindDirection2deg(data.WindDirection2deg<0)= 360 + data.WindDirection2deg(data.WindDirection2deg<0);

    %% from 07-Jun-1999 to 01-Jun-2000 time at CP1 was shifted
%         f = figure('Visible',vis);
%         subplot(2,1,1)
    ind_CP1 = and(data.time>datenum('27-May-1999'), data.time<datenum('03-Jun-2000'));
%         ind_CP2 = and(data_CP2.time>datenum('27-May-1999'), data_CP2.time<datenum('03-Jun-2000'));
%         ind_SC = and(data_SC.time>datenum('27-May-1999'), data_SC.time<datenum('03-Jun-2000'));
%         plot(data.time(ind_CP1), data.ShortwaveRadiationDownWm2(ind_CP1))
%         hold on
%         plot(data_CP2.time(ind_CP2), data_CP2.ShortwaveRadiationDownWm2(ind_CP2))
%         plot(data_SC.time(ind_SC), data_SC.ShortwaveRadiationDownWm2(ind_SC))
%         axis tight
%         set(gca,'XMinorTick','on','XTickLabel',[])
%         legend('CP1','CP2','Swiss Camp')
%         ylabel('Downward Radiation (W/m2)')

%         ind = find(ind_CP1);
%         data(ind+7,5:35) = data(ind,5:35);
%         data(ind(1):ind(1)+7,5:35)= array2table(NaN(8,31));
%         clearvars ind_CP1 diff ind

%         subplot(2,1,2)
%         ind_CP1 = and(data.time>datenum('27-May-1999'), data.time<datenum('03-Jun-2000'));
%         ind_CP2 = and(data_CP2.time>datenum('27-May-1999'), data_CP2.time<datenum('03-Jun-2000'));
%         ind_SC = and(data_SC.time>datenum('27-May-1999'), data_SC.time<datenum('03-Jun-2000'));
%         plot(data.time(ind_CP1), data.ShortwaveRadiationDownWm2(ind_CP1))
%         hold on
%         plot(data_CP2.time(ind_CP2), data_CP2.ShortwaveRadiationDownWm2(ind_CP2))
%         plot(data_SC.time(ind_SC), data_SC.ShortwaveRadiationDownWm2(ind_SC))
%         axis tight
%         set(gca,'XMinorTick','on')
%         set_monthly_tick(time_obs); 
%         datetick('x','yyyy','keeplimits','keepticks')
%         legend('CP1','CP2','Swiss Camp')
%         ylabel('Downward Radiation (W/m2)')

%% Shifting temperature / pressure
    data.AirTemperature1C(data.AirTemperature1C<-200) = ...
        data.AirTemperature1C(data.AirTemperature1C<-200)+273.15;
    data.AirTemperature2C(data.AirTemperature2C<-200) = ...
        data.AirTemperature2C(data.AirTemperature2C<-200)+273.15;
    data.AirTemperature3C(data.AirTemperature3C<-200) = ...
        data.AirTemperature3C(data.AirTemperature3C<-200)+273.15;
    data.AirTemperature4C(data.AirTemperature4C<-200) = ...
        data.AirTemperature4C(data.AirTemperature4C<-200)+273.15;
    data.AirPressurehPa(data.AirPressurehPa<100) = data.AirPressurehPa(data.AirPressurehPa<100)+791.6;
    data.AirPressurehPa(data.AirPressurehPa>1000) = data.AirPressurehPa(data.AirPressurehPa>1000) - 389.9;
end
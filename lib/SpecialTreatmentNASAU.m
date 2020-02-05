function data = SpecialTreatmentNASAU(data)

%%
% figure
% plot(data_sav.ShortwaveRadiationUpWm2)
% datestr(data.time(8870))
% hold on
ind1 = dsearchn(data.time,datenum('31-May-1996 13:59:57'));
ind2 = max(ind1,length(data.time));

data.ShortwaveRadiationUpWm2(ind1:ind2) = ...
    data.ShortwaveRadiationUpWm2(ind1:ind2)*2.76205;
% plot(data.ShortwaveRadiationUpWm2)

ind1 = dsearchn(data.time,datenum('30-May-1996'));
ind2 = dsearchn(data.time,datenum('21-May-1997'));
data.AirPressurehPa(ind1:ind2) = ...
    data.AirPressurehPa(ind1:ind2)-423;

ind1 = dsearchn(data.time,datenum('28-Jun-2016'));
ind2 = dsearchn(data.time,datenum('21-May-2019'));
data.AirPressurehPa(ind1:ind2) = ...
    data.AirPressurehPa(ind1:ind2)-40;

    ind = and(data.WindSpeed2ms>9.5,...
    data.time<= datenum('19-Jun-1997'));
    data.WindSpeed2ms(ind)=NaN;
    ind = and(data.WindSpeed1ms>9.5,...
    data.time<= datenum('19-Jun-1997'));
    data.WindSpeed1ms(ind)=NaN;
end
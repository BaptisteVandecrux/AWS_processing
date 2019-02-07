function data = SpecialTreatmentNASAU(data)

%%
% figure
% plot(data_sav.ShortwaveRadiationUpWm2)
% datestr(data.time(8870))
% hold on
ind1 = dsearchn(data.time,datenum('31-May-1996 13:59:57'));
ind2 = max(ind1,length(data.time));

data.ShortwaveRadiationUpWm2(ind1:ind2)=data.ShortwaveRadiationUpWm2(ind1:ind2)*2.5;
% plot(data.ShortwaveRadiationUpWm2)


%%
end
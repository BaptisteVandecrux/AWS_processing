%% Data files overview
clear all
close all
clc

station_list = {'CP1', 'DYE-2', 'NASA-SE', 'Summit',...
     'NASA-E','NASA-U','SouthDome','TUNU-N','Saddle',...
      'NGRIP', 'GITS', 'Humboldt','NEEM','KULU','SwissCamp'};

% no HIRHAM data available
% station_list = {'NEEM'};
% No Snow temp data from GCNet
% station_list = {'KULU'};
% double data detected in date.time... check later
% station_list = {'NGRIP','Saddle','SwissCamp'};

for i = 1:length(station_list)
    station = station_list{i};
    try 
        [data] = ImportGCnetData(station);
         fprintf('%s\t %s\t %s\t %0.1f %%\t %0.1f %%\n',...
        station, datestr(data.time(1),'dd-mmm-yyyy'),datestr(data.time(end),'dd-mmm-yyyy'),...'
        sum(~isnan(data.AirTemperature1C))/length(data.AirTemperature1C)*100,...
        sum(~isnan(data.ShortwaveRadiationDownWm2))/length(data.ShortwaveRadiationDownWm2)*100);

    catch me
        fprintf('%s no file\n',station);
    end
   end


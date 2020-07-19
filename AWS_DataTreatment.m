%% AWS_DataTreatment
% Now does data extraction, treatment and gap filling for both PROMICE and
% GCnet stations

%adding relevant folders to the Matlab path
clear all 
close all
clc

addpath(genpath('lib'))
addpath(genpath('Input'),genpath('Output'))

% variable indicating whether you want the plots to be visible ('on') or
% not ('off'). They are printed in files anyway.
vis = 'off';

% Plot comparisons of AWS data with RCM data, which is used
% to fill data gaps ('no' or 'yes')
PlotGapFill = 'yes';

% Using tilt correction from jaws
tilt_correct = 'yes';

% setting default plotting parameters
set(0,'defaultfigurepaperunits','centimeters');
set(0,'DefaultAxesFontSize',15)
set(0,'defaultfigurecolor','w');
set(0,'defaultfigureinverthardcopy','off');
set(0,'defaultfigurepaperorientation','portrait');
set(0,'defaultfigurepapersize',[29.7  18 ]);
set(0,'defaultfigurepaperposition',[.25 .25 [29.7 18 ]-0.5]);
set(0,'DefaultTextInterpreter','none');
set(0, 'DefaultFigureUnits', 'centimeters');
set(0, 'DefaultFigurePosition', [.25 .25 [29.7 18 ]-0.5]);
warning('off','MATLAB:print:CustomResizeFcnInPrint')
% some constants
T_0 = 273.15;

% select station here
station_list = {'KAN_M'}; %{Stationname{15:24}};

% it is also possible to loop through all or part of the PROMICE stations
% here loading a station list:
% Stationname = ["KPC_L";"KPC_U";"SCO_L";"SCO_U";"MIT";"TAS_L";"TAS_U";"TAS_A";"QAS_L";"QAS_U";"QAS_A";"NUK_L";"NUK_U";"NUK_K";"NUK_N";"KAN_B";"KAN_L";"KAN_M";"KAN_U";"UPE_L";"UPE_U";"THU_L";"THU_U";"SwissCamp";"CP1";"NASA-U";"GITS";"Humboldt";"Summit";"TUNU-N";"DYE-2";"JAR";"Saddle";"SouthDome";"NASA-E";"CP2";"NGRIP";"NASA-SE";"KAR";"JAR2";"KULU";"FA-1";"FA-2";"EKT"];
% station_list = {Stationname{15:24}};

% Choice RCM
RCM = 'RACMO';

%% start looping through station list
for i = 1: length(station_list)
    station = station_list{i};

    fprintf('Processing station: %s\n',station)
    disp('--------------')

    % here we start a log that saves the output of the command prompt
    % we make sure that it does not overwrite anything
    % it will continue to write in the file as long as the command diary('off')
    % is not run at the end of the script
    OutputFolder = sprintf('Output/%s_%s',station,RCM);
    mkdir(OutputFolder);

    i_file = 1;
    NameFile = sprintf('%s/log_%i.txt',OutputFolder,i_file)  ;
    while exist(NameFile, 'file') == 2
        i_file = i_file + 1;
        NameFile = sprintf('%s/log_%i.txt',OutputFolder,i_file)  ;
    end
    diary(NameFile)
    clearvars NameFile i_file

%%  ==================== Loading data ============================
% this section loads the data from the GCnet station to the table "data"
% It uses the GCnet files as they are. In a first time it reads the header
% part which lists the variable names. Different files might contain
% different number of variables so adjust the "endRow_header" accordingly.
% In a second time it reads the data

% --------------- Loading data from MAIN STATION ----------------------
disp('Loading data')
tic

% Loading GC-Net station list
filename = '.\Input\GCnet\NamesStations.csv';
delimiter = ''; formatSpec = '%s%[^\n\r]'; fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
fclose(fileID); name_GCnet = dataArray{:, 1};
clearvars filename delimiter formatSpec fileID dataArray ans;

name_PROMICE = dir('./Input/PROMICE');
name_PROMICE = {name_PROMICE.name};

% Looking for station in GC-Net station list
if sum(~cellfun(@isempty,strfind(name_GCnet,station)))>0
    is_GCnet = 1;
    [data] = ImportGCnetData(station,tilt_correct);
    
% Looking for station in PROMICE station list
elseif sum(~cellfun(@isempty,strfind(name_PROMICE,station)))>0
    is_GCnet = 0;
    [data] = ImportPROMICEData(station);
elseif strcmp(station,'IMAU')
    is_GCnet = 0;
    data = ImportIMAUfile();
    
else
    error('Station unknown')
end

toc 
disp('---------------------')

%%  --------- Loading data from SECONDARY STATIONS for gap filling ----------
disp('Loading secondary data')
tic
 sec_stations_names = {};
 data_sec_stations = {};
switch station
    case 'CP1'
        % Loading data from CP2
        sec_stations_names{1} = 'CP2';
        data_sec_stations{1} = LoadDataCP2(vis, OutputFolder);

        % Loading data from Swiss Camp
        sec_stations_names{2} = 'SC';
        data_sec_stations{2} = LoadDataSC(vis, OutputFolder);
   
    case 'DYE-2'
        % Loading data from KAN-U    
        sec_stations_names{1} = 'KANU';
        data_sec_stations{1} = LoadDataKANU(vis, OutputFolder);
        data_sec_stations{1}.LongwaveRadiationDownWm2 ...
            = NaN(size(data_sec_stations{1}.LongwaveRadiationDownWm2));

    case 'Summit'
        sec_stations_names = {'NOAA', 'Miller'};
        [data_sec_stations{1}, data_sec_stations{2}] = ...
            LoadDataSummit(OutputFolder,vis);

    case 'KAN_U'
        try data_sec_stations{1} = LoadDataKANUbabis() ;
            sec_stations_names{1} = 'KANUbabis';
        catch me
            disp('NUK_K can be gap-filled with KOB station. Contact bav@geus.dk for more info.')
        end
    case 'NUK_K'
        try data_sec_stations{1} = LoadDataKOB(OutputFolder,vis) ;
            sec_stations_names{1} = 'KOB';
        catch me
            disp('NUK_K can be gap-filled with KOB station. Contact bav@geus.dk for more info.')
        end
end
clearvars ind


% ----------------- Loading RCM data -----------------------------------  
    [data_RCM] = LoadRCMData(station,RCM);
    
toc 
disp('---------------------')
   
%% Data filtering
    disp('Filtering data')

    % Treat and filter the data - chose to convert humidity being measured
    % in ice to water - or not
%     data = TreatAndFilterData(data,'ConvertHumidity', station, OutputFolder, vis);
tic
       data = TreatAndFilterData(data,' ', station, OutputFolder, vis);
   toc     
disp('---------------------')
	
%% Starting to keep track of the origin
	% the following field will contain a code which indicates where the data
	% comes from:
	% 0 -> original data
	% 1 -> CP2 (used to fill gaps in CP1)
	% 2 -> Crawford point (used to fill gaps in CP1)
	% 3 -> RCM data (used to fill gaps in all stations)
	% 4 -> any radiation data calculated from MODIS albedo (used to fill gaps
	% in all stations)
	% 5 -> KANU (used for Dye 2)
	% 6 -> from a previous year
	% 7 -> babis' reconstruction of KANU
	
	data.ShortwaveRadiationDownWm2_Origin = zeros(size(data.time));
	data.ShortwaveRadiationUpWm2_Origin = zeros(size(data.time));
	data.AirPressurehPa_Origin = zeros(size(data.time));
	data.AirTemperature1C_Origin = zeros(size(data.time));
	data.AirTemperature2C_Origin = zeros(size(data.time));
	data.WindSpeed1ms_Origin= zeros(size(data.time));
	data.WindSpeed2ms_Origin= zeros(size(data.time));
	data.RelativeHumidity1Perc_Origin = zeros(size(data.time));
	data.RelativeHumidity2Perc_Origin = zeros(size(data.time));
	data.LongwaveRadiationUpWm2_Origin = zeros(size(data,1),1);
	data.LongwaveRadiationDownWm2_Origin = zeros(size(data,1),1);
	data.Snowfallmweq_Origin = zeros(size(data,1),1);
	
	if ~ismember('LongwaveRadiationDownWm2',data.Properties.VariableNames)
	    data.LongwaveRadiationDownWm2 = NaN(size(data.time));
	end
	
%% =================== Cropping at defined periods ========================
	% this part allow to split the original GCnet station record into smaller
	% periods where data has less gaps.
	% If not needed, just use one period that includes all the data of the
	% GCnet station.

    time_start = [];
    time_end = [];

	switch station
        case 'GITS'
            switch RCM
                case 'CanESM_hist'
                    time_start = datenum('01-Jun-1966 00:00:00');
                    time_end = datenum('31-Dec-2012 00:00:00');
                case {'CanESM_rcp26', 'CanESM_rcp45', 'CanESM_rcp85'}
                    time_start = datenum('01-Jun-1966 00:00:00');
                    time_end = datenum('31-Dec-2100 00:00:00');
                otherwise
                    time_start = datenum('01-Jun-1966 00:00:00');
                    time_end = datenum('31-Dec-2017 23:00:00');
            end

	    case 'NUK_K'
	    time_start = datenum('01-Sep-2014 00:00:00');	
	    time_end = datenum('01-Sep-2017 00:00:00');
        
        case 'KAN_U'
	    time_start = datenum('01-May-2012 00:00:00');
	    time_end = datenum('31-Dec-2016 00:00:00');
        
        case 'NGRIP'
        time_end = datenum('31-Dec-2009 23:00:00');
    end
    
    if isempty(time_start)
        time_start = data.time(1);
    end
    if isempty(time_end)
        time_end = data.time(end);
    end
	
	% here the RCM file is cropped to the desired period 
 	ind_RCM = and(data_RCM.time>=time_start, data_RCM.time<=time_end);
    data_RCM = data_RCM(ind_RCM,:);
    
	ind_RCM = find(and(data_RCM.time>=time_start, data_RCM.time<=time_end));
	if ~isempty(ind_RCM)
	    if time_end>data_RCM.time(end)
	        added_rows  = array2table([[data_RCM.time(end)+1/24:1/24:time_end]',...
                NaN( length([data_RCM.time(end)+1/24:1/24:time_end]),size(data_RCM,2)-1)],...
                'VariableNames',data_RCM.Properties.VariableNames);
	        data_RCM = [data_RCM;  added_rows];
	    end
    end

	% here we crop the data
	ind_AWS = find(and(data.time>=time_start, data.time<=time_end));
	data = data(ind_AWS,:);
	
	% if we want to append data from RCM before the start of the
	% station (time_start<data.time(1))
	if time_start < data.time(1)
	    num_missing_hour = floor((data.time(1)-time_start)*24);
	    table_aux = array2table(NaN(num_missing_hour,size(data,2)),'VariableNames',data.Properties.VariableNames);
	    for ii = 1:num_missing_hour
	        table_aux.time(end-ii+1) = data.time(1) - ii/24;
	    end
	    data = [table_aux; data];
    end
	% if we want  to append data from RCM after the end of the
	% station (time_start<data.time(1))
	if time_end > data.time(end)
	    num_missing_hour = floor((time_end- data.time(end))*24);
	    table_aux = array2table(NaN(num_missing_hour,size(data,2)),'VariableNames',data.Properties.VariableNames);
	    table_aux.time = data.time(end) + [1:num_missing_hour]'/24;
	    data = [data; table_aux];
	end

%%  =================== Filling gaps ======================================
% In this section we fill the gaps at Crawford Point using the data from
% CP2 station and from Swiss Camp
 disp('Filling gaps')
tic
    PlotWeather(data,'OutputFolder',OutputFolder,'vis',vis);

    if ~isempty(ind_RCM) && isempty(sec_stations_names)
        sec_stations_names = {sec_stations_names{:}, RCM};
        data_sec_stations = {data_sec_stations{:}, data_RCM};
    end
    
    VarList = {'AirTemperature1C', 'AirTemperature2C',...
    'ShortwaveRadiationDownWm2', 'NetRadiationWm2', ...
    'AirPressurehPa', 'RelativeHumidity1Perc',...
    'RelativeHumidity2Perc', 'WindSpeed1ms', 'WindSpeed2ms',...
    'LongwaveRadiationDownWm2'};

    clearvars summary_table
    summary_table = array2table(NaN(length(sec_stations_names)*3, length(VarList)));
    summary_table.Properties.VariableNames = VarList;

    count = 1;
    for i = 1:3:(length(sec_stations_names))*3
        summary_table.Properties.RowNames{i} = [sec_stations_names{count} '_PartOfDataset'];
        summary_table.Properties.RowNames{i+1} = [sec_stations_names{count} '_RMSD'];
        summary_table.Properties.RowNames{i+2} = [sec_stations_names{count} '_R2'];
        count = count +1 ;
    end
    
    if ~isempty(sec_stations_names)
        for i = 1:length(sec_stations_names)
            SubFolder = sprintf('%s/Filling gaps with %s',OutputFolder,sec_stations_names{i});
            mkdir(SubFolder);
            
            [data,  summary_table{(i-1)*3+3,:}, summary_table{(i-1)*3+2,:}, ~] ...
                = CombiningData(station, sec_stations_names{i},...
                data,data_sec_stations{i},VarList, vis, PlotGapFill, SubFolder);
            
            data = InterpTable(data,6);
        end
    end
      
    for i = 1:length(VarList)
        VarName = VarList{i};
        Origin = sprintf('%s_Origin',VarName);
        for j = 1:length(sec_stations_names)
            switch sec_stations_names{j}
                case 'CP2'
                    ind_sec_station =  1;
                case 'SC'
                    ind_sec_station =  2;
                case 'KANU'
                    ind_sec_station =  3;
                case {'RCM','RACMO','MAR','HIRHAM','CanESM_hist','CanESM_rcp26','CanESM_rcp45','CanESM_rcp85'}
                    ind_sec_station =  4;  
                case 'last_year'
                    ind_sec_station =  6; 
                case 'KANUbabis'
                    ind_sec_station =  7;  
                case 'KOB'
                    ind_sec_station =  8;
                case 'NOAA'
                    ind_sec_station =  9;
                case 'Miller'
                    ind_sec_station =  10;
                % 5 is left for modis
            end
            if ismember(Origin,data.Properties.VariableNames)
                counts = sum(data.(Origin) == ind_sec_station);
                summary_table.(VarList{i})((j-1)*3+1) =  counts/length(data.(Origin))*100;
            else
                continue
            end
        end
    end
    writetable(summary_table,...
        sprintf('%s/GapFillingReport.txt',OutputFolder),...
        'WriteRowNames',true,'Delimiter','\t');

VarNames = data.Properties.VariableNames;
if ~ismember('LongwaveRadiationUpWm2',data.Properties.VariableNames)
    data.LongwaveRadiationUpWm2 = NaN(size(data,1),1);
end
toc
disp('---------------------')

%% ============ Reconstruction of surface height ==========================
% The sonic rangers are used to measure surface height. It is important to
% determine the instruments height as done above.
% It can be also used to track the surface evolution on longer periods.
% However the station is located in the accumulation area and gets buried a
% bit more every year. Every now and then the station is lifted and its
% mast extended. This changes the surface height as seen by the sonic
% ranger and needs to be corrected.
disp('Surface height adjustement')
tic
[data] = AdjustHeight(data,station,OutputFolder,vis);
toc
disp('---------------------')
 
%% ================ Precipitation =============================
disp('Calculating precipitation from station')
tic
data = CalculatePrecipitation(data,data_RCM,station, OutputFolder,vis);
toc
 disp('---------------------')

%% =================== Subsurface temperatures ============================
% The depth scale takes the surface as zero depth for each time step with
% increasing positive depth downward.
disp('Processing subsurface temperature measurement')
tic
ind_therm = find(contains(data.Properties.VariableNames,'IceTemp'));
data_therm = table2array(data(:,ind_therm));
if sum(sum(~isnan(data_therm)))>10
    data = SubsurfaceTemperatureProcessing(data,station,is_GCnet,OutputFolder,vis);
end
toc
disp('---------------------')

%% =============== Gap-fillin of upward shortwave radiation ===============
disp('Using MODIS data to gap-fill upward shortwave radiation')
tic
count_plot = 1;
if strcmp(station,'NUK_K')
    AlbedoStandardValue = 0.6;
else
    AlbedoStandardValue = 0.8;
end

[data, data_modis] = fill_SWup_using_MODIS_albedo(data,...
    station, is_GCnet, OutputFolder, AlbedoStandardValue, data_RCM, vis);

toc
disp('--------------------')
	    
%% ============  Last plot and origin ================================
% Instrument heights
disp('Plotting weather data and origin')
tic
f = figure('Visible',vis);
hold on
plot(data.time,data.WindSensorHeight2m)
plot(data.time,data.TemperatureSensorHeight2m)
plot(data.time,data.HumiditySensorHeight2m)
axis tight
box on
set_monthly_tick(data.time)
legend('Wind','Temperature','Humidity')
xlabel('Time')
ylabel('Instrument height')
print(f,sprintf('%s/instr_height',OutputFolder),'-dtiff')

% plot all climate variables
PlotWeather(data,'OutputFolder',OutputFolder,'vis','on');

% print the origin distribution for each variable    
VarList = {'ShortwaveRadiationDownWm2','ShortwaveRadiationUpWm2',...
    'AirTemperature2C','RelativeHumidity2Perc','AirPressurehPa',...
    'WindSpeed2ms','LongwaveRadiationDownWm2','Snowfallmweq'};
SourceList = {'Original', 'CP2', 'SC', 'KAN_U','RCM','MODIS','last year','KANU_babis','KOB'};

source = array2table(zeros(length(SourceList),length(VarList)));
source.Properties.VariableNames = VarList;
source.Properties.RowNames = SourceList;

for i = 1:length(VarList)
    
    VarName = VarList{i};
    Origin = sprintf('%s_Origin',VarName);
    x = 0:length(SourceList)-1;
    counts = zeros(size(x));
    for j = 1:length(x)
        counts(j) = sum(data.(Origin) == x(j));
        source.(VarList{i})(j) =  counts(j)/length(data.(Origin))*100;
    end
end
writetable(source,sprintf('%s/source.txt',OutputFolder),'WriteRowNames',true,'Delimiter','\t');
toc
disp('--------------------')

%% ====================== Writing data to file ===========================
	tic
	disp('Writing data to file')
	data_final = table;
        DV  = datevec(data.time);  % [N x 6] array
	data_final.Year = DV(:,1);
	data_final.MonthOfYear = DV(:,2);
	data_final.HourOfDayUTC = DV(:,4);
	data_final.DayOfYear = datenum(DV(:,1),DV(:,2),DV(:,3))-datenum(DV(:,1),0,0);
	data_final.AirPressurehPa = data.AirPressurehPa;
	data_final.AirPressurehPa_Origin = data.AirPressurehPa_Origin;
    
	data_final.AirTemperature1C = data.AirTemperature1C;
	data_final.AirTemperature1C_Origin = data.AirTemperature1C_Origin;
	data_final.AirTemperature2C = data.AirTemperature2C;
	data_final.AirTemperature2C_Origin = data.AirTemperature2C_Origin;
    
	data_final.RelativeHumidity1 = data.RelativeHumidity1Perc;
	data_final.RelativeHumidity1_Origin = data.RelativeHumidity1Perc_Origin;
	data_final.RelativeHumidity2 = data.RelativeHumidity2Perc;
	data_final.RelativeHumidity2_Origin = data.RelativeHumidity2Perc_Origin;

	data_final.WindSpeed1ms = data.WindSpeed1ms;
	data_final.WindSpeed1ms_Origin = data.WindSpeed1ms_Origin;
	data_final.WindSpeed2ms = data.WindSpeed2ms;
	data_final.WindSpeed2ms_Origin = data.WindSpeed2ms_Origin;

	data_final.WindDirection1d = data.WindDirection1deg;
	data_final.WindDirection2d = data.WindDirection2deg;

    data_final.ShortwaveRadiationDownWm2 = data.ShortwaveRadiationDownWm2;
	data_final.ShortwaveRadiationDownWm2_Origin = data.ShortwaveRadiationDownWm2_Origin;
	data_final.ShortwaveRadiationUpWm2 = data.ShortwaveRadiationUpWm2;
	data_final.ShortwaveRadiationUpWm2_Origin = data.ShortwaveRadiationUpWm2_Origin;
	data_final.Albedo = min(1, max(0, data_final.ShortwaveRadiationUpWm2 ./ data_final.ShortwaveRadiationDownWm2));
	data_final.LongwaveRadiationDownWm2	 = data.LongwaveRadiationDownWm2;
	data_final.LongwaveRadiationDownWm2_Origin	 = data.LongwaveRadiationDownWm2_Origin;
	data_final.LongwaveRadiationUpWm2	 = data.LongwaveRadiationUpWm2;
	data_final.LongwaveRadiationUpWm2_Origin	 = data.LongwaveRadiationUpWm2_Origin;
	
	data_final.HeightSensorBoomm = data.WindSensorHeight1m;
	data_final.HeightStakesm = data.WindSensorHeight2m;
	for i = 1:10
	    VarName = sprintf('IceTemperature%iC',i);
	    if sum(strcmp(VarName,data.Properties.VariableNames))>0
	        data_final.(VarName) = data.(VarName);
	    end
	end
	
	data_final.time =               data.time;
	data_final.HeightWindSpeed1m = data.WindSensorHeight1m;
	data_final.HeightWindSpeed2m = data.WindSensorHeight2m;
    
	data_final.HeightTemperature1m = data.TemperatureSensorHeight1m;
	data_final.HeightTemperature2m = data.TemperatureSensorHeight2m;
    
	data_final.HeightHumidity1m = data.HumiditySensorHeight1m;
	data_final.HeightHumidity2m = data.HumiditySensorHeight2m;
    
	data_final.SurfaceHeightm =     data.SurfaceHeightm;    
	data_final.Snowfallmweq =     data.Snowfallmweq;
	data_final.Rainfallmweq =     data.Rainfallmweq;
    
	for i = 1:10
	    VarName = sprintf('DepthThermistor%im',i);
	    if sum(strcmp(VarName,data.Properties.VariableNames))>0
	        data_final.(VarName) = data.(VarName);
	    end
	end
	
	% Control time span
	% ind_end = find(data_final.time<datenum('01-Jan-2011'),1,'last');
	% data_final = data_final(1:ind_end,:);
	filename = sprintf('%s/data_%s_combined_hour.txt',OutputFolder,station);
	varnames = data_final.Properties.VariableNames;
	
	fid = fopen(filename,'w');
	for i = 1:length(varnames)
	    if i ==length(varnames)
	        fprintf(fid, sprintf('%s\n',varnames{i}));
	    else
	        fprintf(fid, sprintf('%s\t',varnames{i}));
	    end
	end
	
	fclose(fid);
	M=table2array(data_final);
	M(isnan(M)) = -999;
	FastDLMwrite(filename, M, '\t');
	diary('off');
	toc
	disp('--------------------')
	disp('Finnished!')
	disp('--------------------')
	disp('')
    
end


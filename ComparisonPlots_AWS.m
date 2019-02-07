clearvars
close all
clc
addpath(genpath('../../Code/matlab_functions'))
addpath(genpath('Input'),genpath('Output'))
set(0,'defaultfigurepaperunits','centimeters');
set(0,'defaultfigurepaperorientation','landscape');
set(0,'defaultfigurepapersize',[29.7 21]);
set(0,'defaultfigurepaperposition',[.25 .25 [29.7 21]-0.5]);
set(0, 'DefaultfigureUnits', 'centimeters');
set(0, 'DefaultfigurePosition', [.25 .25 [29.7 21]-0.5]);
set(0,'DefaultAxesFontSize',15)

set(0,'defaultfigurepaperunits','centimeters');
set(0,'DefaultAxesFontSize',15)
set(0,'defaultfigurecolor','w');
set(0,'defaultfigureinverthardcopy','off');
set(0,'defaultfigurepaperorientation','portrait');
set(0,'defaultfigurepapersize',[29.7  16 ]);
set(0,'defaultfigurepaperposition',[.25 .25 [29.7 16 ]-0.5]);
set(0,'DefaultTextInterpreter','none');
set(0, 'DefaultFigureUnits', 'centimeters');
set(0, 'DefaultFigurePosition', [.25 .25 [29.7 16 ]-0.5]);
warning('off','MATLAB:print:CustomResizeFcnInPrint')


vis = 'on';
station_list = {'CP1', 'DYE-2', 'NASA-SE', 'Summit','Saddle','NASA-E','NASA-U','TUNU-N','SouthDome'};

%% Load data
disp ('Loading data')
tic
data = LoadData_AWS(station_list);
toc

%% Plotting albedo
tic
disp('Plotting Albedo')
AlbedoPlot(station_list,data,vis);
toc

%% Plotting historical temperature
tic
disp('Plotting historical temperatures')
HistoricalTemperaturePlot(station_list,data,vis);
toc

%% Plotting RCM temperatures
tic
disp('Plotting historical temperatures')
RCMTemperaturePlot(station_list,data, vis);
toc

%% Plotting comparison of accumulation with ice cores
% tic
% disp('Plotting historical temperatures')
% ComparisonAccumIceCore(station_list,data, vis);
% toc

%% Plotting temperature trend analysis
tic
disp('Plotting temperature trends')
summary_table = TemperatureTrendAnalysis(station_list,data,vis);
toc
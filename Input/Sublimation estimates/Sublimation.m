   % extract run parameters
    OutputFolder = uigetdir('./Output');

    load(strcat(OutputFolder,'/run_param.mat'))
    c.OutputFolder = OutputFolder;
    % extract surface variables
    namefile = sprintf('%s/surf-bin-%i.nc',OutputFolder,1);
    finfo = ncinfo(namefile);
    names={finfo.Variables.Name};
    time = ncread(namefile,'time');
    sublimation = ncread(namefile,'sublimation');
    
time = (time+datenum(1900,1,1));
DV = datevec(time);
DV1 = DV;
DV1(:,2:end) = 0;
DV2 =DV1;
DV2(:,1) = DV2(:,1)+1;

dec_year = DV(:,1) + (datenum(DV) - datenum(DV1))./(datenum(DV2)-datenum(DV1));

% figure
% plot(time,dec_year)
% datetick('x')
% grid on
% set(gca,'XMinorGrid','on','YMinorGrid','on')


FastDLMwrite(sprintf('%s_sublimation.txt',c.station),[dec_year sublimation],';')
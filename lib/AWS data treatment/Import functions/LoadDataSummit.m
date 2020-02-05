function [data_NOAA, data_Miller] = LoadDataSummit(OutputFolder,vis)

    % Loading NOAA
    filename = '.\Input\Secondary data\data_NOAA.nc';
    finfo = ncinfo(filename);

    data_NOAA = table();
    for i=1:length(finfo.Variables)
        data_NOAA.(finfo.Variables(i).Name) = ...
            double(ncread(filename,finfo.Variables(i).Name));
    end
    
    data_NOAA.time = data_NOAA.time + datenum(1900,1,1);
    data_NOAA = ResampleTable(data_NOAA);
      
    data_NOAA.rh = RHwater2ice(data_NOAA.rh,data_NOAA.ta_2m+273.15,data_NOAA.ps);
    [~, ind1] = min(abs(data_NOAA.time - datenum('16-May-2015 18:00:00')));
    [~, ind2] = min(abs(data_NOAA.time - datenum('01-Aug-2019 00:00:00')));

    data_NOAA.rh(ind1:end) = NaN;

    % Loading Miller
    filename = '.\Input\Secondary data\summit_30min_jan2011tojun2014_seb_20160926.cdf';
    finfo = ncinfo(filename);

    data_Miller = table();
    for i=5:39
        data_Miller.(finfo.Variables(i).Name) = ...
            double(ncread(filename,finfo.Variables(i).Name));
    end
    data_Miller.ss = datenum(data_Miller.yyyy,data_Miller.mm,data_Miller.dd,data_Miller.hh,data_Miller.nn,data_Miller.ss);
    data_Miller(:,1:6) = [];
    data_Miller.Properties.VariableNames{1} = 'time';

    data_Miller = AvgTable(data_Miller,'hourly','mean');
    data_Miller= standardizeMissing(data_Miller,-999);
    data_Miller.Properties.VariableNames = ...
    {'time' 'SWup' 'SWdown' 'LWup' 'LWdown' 'rime_swup' 'rime_swdown' 'rime_lwup' 'rime_lwdn'...
        'Tsurf' 'zenith' 'sh_bulk' 'lh_bulk' 'lh_grad' 'ustar_bulk' ...
        'sh_cv' 'ustar_cv' 'ri_grad' 'cond_flux' 'cond_flux_toplevel'...
        'storage_flux' 'ps' 'ws' 'wd' 'rh' 'ta_2m' 'ta_10m' 'lwp' 'pwv'};
    
    

%% Renaming
data_NOAA = RenameTable(data_NOAA);
data_Miller = RenameTable(data_Miller);

data_NOAA = TreatAndFilterData(data_NOAA,'','NOAA',OutputFolder,vis);
data_Miller = TreatAndFilterData(data_Miller,'','Miller',OutputFolder,vis);

end
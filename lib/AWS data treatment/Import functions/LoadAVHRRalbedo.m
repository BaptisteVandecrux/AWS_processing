function [data_AVHRR] = LoadAVHRRalbedo(station)
    % Loading station list
    opts = delimitedTextImportOptions("NumVariables", 5);
    opts.DataLines = [2, Inf];
    opts.Delimiter = ";";
    opts.VariableNames = ["ID", "Stationname", "Northing", "Easting", "Elevationmasl"];
    opts.VariableTypes = ["double", "string", "double", "double", "double"];
    opts = setvaropts(opts, 2, "WhitespaceRule", "preserve");
    opts = setvaropts(opts, 2, "EmptyFieldRule", "auto");
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    AWS = readtable("..\..\Data\AVHRR\AWS.csv", opts);
    clear opts
    switch station
        case 'SC'
            station = "SwissCamp";
        case 'CP1'
            station = "CrawfordPt";
        case 'South Dome'
            station = "SouthDome";
    end
    ind = find(strcmp(AWS.Stationname,station));

    % loading albedo data
    filename = "..\..\Data\AVHRR\AVHRR_AWS_sites.nc";
    data_AVHRR = table();
    data_AVHRR.time = ncread(filename,'time')+datenum(1900,1,1);
    tmp = ncread(filename,'sal');
    data_AVHRR.albedo = tmp(ind,:)';
    data_AVHRR = standardizeMissing(data_AVHRR,-999);
    data_AVHRR = AvgTable(data_AVHRR,'daily','mean');
    data_AVHRR = standardizeMissing(data_AVHRR,0);
    ind_nan = isnan(data_AVHRR.albedo);
    if sum(~ind_nan)>2
    data_AVHRR.albedo(ind_nan)=interp1(data_AVHRR.time(~ind_nan),...
        data_AVHRR.albedo(~ind_nan),data_AVHRR.time(ind_nan));
    end
    DV  = datevec(data_AVHRR.time);  % [N x 6] array
    DV  = DV(:, 1:3);   % [N x 3] array, no time
    DV2 = DV;
    DV2(:, 2:3) = 0;    % [N x 3], day before 01.Jan
    data_AVHRR.year = DV(:,1);
    data_AVHRR.day = datenum(DV) - datenum(DV2);
end

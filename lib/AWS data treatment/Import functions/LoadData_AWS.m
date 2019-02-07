function data = LoadData_AWS(station_list)
    for ii = 1:length(station_list)
        fprintf('%i / %i\n',ii,length(station_list))
        station = station_list{ii};
        filename = sprintf('./Output/%s/data_%s_combined_hour.txt',station,station);
        OutputFolder = sprintf('./Output/%s',station);

        % Loading data
        % header
        delimiter = '\t';
        endRow = 1;
        formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, endRow, 'Delimiter', delimiter, 'ReturnOnError', false);
        fclose(fileID);
        for i = 1:length(dataArray)
            temp = dataArray{i};
            header{i} = temp{1};
        end
        clearvars endRow formatSpec fileID  ans dataArray

        count = length(header);
        while isempty(header{count})
            header(count) = [];
            count = count -1;
        end

        % data
        delimiter = '\t';
        startRow = 2;

        formatSpec = strcat(repmat('%f',1,length(header)),'%[^\n\r]');
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,...
            'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
        fclose(fileID);
        dataArray (:,(length(header)+1):end) = [];

        data_GCnet_old = table(dataArray{:}, 'VariableNames',header);
        clearvars filename delimiter startRow formatSpec fileID dataArray ans;

        VarNames = data_GCnet_old.Properties.VariableNames;
        data_GCnet_final=standardizeMissing(data_GCnet_old,-999);
        clearvars data_GCnet_old header

        data_GCnet_final.Albedo = data_GCnet_final.ShortwaveRadiationUpWm2./ ...
            data_GCnet_final.ShortwaveRadiationDownWm2;

        data_GCnet_final.Albedo(data_GCnet_final.Albedo>1)=NaN;
        data_GCnet_final.Albedo(data_GCnet_final.Albedo<0)=NaN;
        data{ii} = data_GCnet_final;

        data{ii}.Albedo = min(1,max(0,data{ii}.ShortwaveRadiationUpWm2./data{ii}.ShortwaveRadiationDownWm2));

        data{ii}.Albedo(data{ii}.Albedo==1) = NaN;
        data{ii}.Albedo(data{ii}.Albedo==0) = NaN;
        data{ii}.Albedo(data{ii}.ShortwaveRadiationDownWm2<=75) = NaN;
        data{ii}.Albedo(data{ii}.ShortwaveRadiationUpWm2<=75) = NaN;
    end
end

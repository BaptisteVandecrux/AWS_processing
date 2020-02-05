function[subl] = ImportSublimationEstimate(c, time)
    % Loading the sublimation estimates
    filename = ['./Input/Sublimation estimates/' c.station '_sublimation.txt'];

    if exist(filename)==0
        disp('Warning: No sublimation file found in Input/Sublimation estimate')
        subl = table();
        subl.time = time;
        subl.estim = time * 0;
    else
        delimiter = ';';
        formatSpec = '%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
        fclose(fileID);
        subl = table(dataArray{1:end-1}, 'VariableNames', {'time','estim'});
        clearvars filename delimiter formatSpec fileID dataArray ans;
        subl.time = datenum(subl.time,1,1); 
    end

end
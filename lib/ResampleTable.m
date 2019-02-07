function [data_new] = ResampleTable(data)
% ResampleData resamples a table every round hour.
%   data is the input table containing at least a field 'time' with Matlab
%   timestamps.
%
%   data_new is a table containing in 'time' the new time stamps (full 
%   hours) and all the other variables contained in data interpolated on
%   the new time time stamps.
%

 
    time_start = data.time(1);
    % finding full hour equal or preceding the first time stamp in
    % data.time
    if floor((time_start - floor(time_start))/(1/24)) ~= ...
        ((time_start - floor(time_start))/(1/24))

        time_start = floor(time_start) + floor((time_start - floor(time_start))/(1/24))*(1/24)+ 1/24;
    end

    time_end = data.time(end);
    % finding full hour equal or following the last time stamp in
    % data.time
    if floor((time_end - floor(time_end))/(1/24)) ~= ...
        ((time_end - floor(time_end))/(1/24))

        time_end = floor(time_end) + floor((time_end - floor(time_end))/(1/24))*(1/24) - 1/24;
    end

    % new time stamps
    new_time = [time_start:1/24:time_end]';
    VarNames = data.Properties.VariableNames;
    data_new = table;
    data_new.time = new_time;

%     time_step = unique(data.time(2:end) - data.time(1:end-1));
%     if length(time_step) >1
%         error('uneven time step')
%     end
%     data.time = data.time + time_step/2;
%     new_time_step = unique(new_time(2:end)-new_time(1:end-1));
%     new_time_step=new_time_step(1);
%     if length(new_time_step) >1
%         error('uneven time step')
%     end
    % interpolating all variables at the new time stamps
    for i = 1:size(data,2)
        if ~strcmp(VarNames{i},'time')
            if isnumeric(data.(VarNames{i}))
                interp_values = interp1(data.time, data.(VarNames{i}), new_time,'linear','extrap');
                data_new.(VarNames{i}) = interp_values;
                %if some data was interpolated between points of different origins,
                %we just round the interpolated origin to keep it integer
                if ~isempty(strfind(VarNames{i},'Origin'))
                    data_new.(VarNames{i}) = round(data_new.(VarNames{i}));
                end
            else
                for j = 1:length(new_time)
                    [~,ind] = min(abs(data.time-new_time(j)));
                    data_new.(VarNames{i})(j) = data.(VarNames{i})(ind);
                end
            end
        end
    end
end
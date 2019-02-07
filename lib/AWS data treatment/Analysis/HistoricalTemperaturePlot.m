function HistoricalTemperaturePlot(station_list_in,data,vis)                          
    station_list = {station_list_in{:},...
        'Ilulissat','Kangerlussuaq','Tasilaq'}; %,'Summit_Box'};

    %% Extracting data from the GCnet station and averaging
T_avg = {};
    for i = 1:length(station_list_in)
       [T_avg{i}] = seasonal_avg_table(data{i});
       fprintf('%s data loaded\n',station_list_in{i});
    end

    %% loading Kangerlussuaq

    filename = 'C:\Users\bava\OwnCloud_new\Data\Historical Weather\4231_T_monthly_seasonal_annual.txt';
    startRow = 2;

    formatSpec = '%4f%6f%6f%6f%6f%6f%6f%6f%6f%6f%6f%6f%6f%7f%7f%7f%7f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(fileID);
    data_Kanger = table(dataArray{1:end-1}, 'VariableNames', ...
        {'Year','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec','DJF','MAM','JJA','SON','ANN'});
    clearvars filename startRow formatSpec fileID dataArray ans;
    data_Kanger(:,14:end) = [];
    data_Kanger = standardizeMissing(data_Kanger,999.9);
    data_Kanger = standardizeMissing(data_Kanger,999);

    %% loading Ilulissat

    filename = 'C:\Users\bava\OwnCloud_new\Data\Historical Weather\ilulissat.dat';
    startRow = 2;
    formatSpec = '%4f%5f%5f%5f%5f%5f%5f%5f%5f%5f%5f%5f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(fileID);
    data_Ilulissat = table(dataArray{1:end-1}, 'VariableNames', ....
        {'Year','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'});
    clearvars filename startRow formatSpec fileID dataArray ans;
    data_Ilulissat = standardizeMissing(data_Ilulissat,-999);
    for i = 1:12
        data_Ilulissat.(data_Ilulissat.Properties.VariableNames{i+1}) = ...
            data_Ilulissat.(data_Ilulissat.Properties.VariableNames{i+1})./10;
    end

    %% loading Summit
%     filename = 'C:\Users\bava\OwnCloud_new\Data\Historical Weather\4416_T_monthly_seasonal_annual.txt';
%     startRow = 2;
%     formatSpec = '%4f%6f%6f%6f%6f%6f%6f%6f%6f%6f%6f%6f%6f%7f%7f%7f%7f%f%[^\n\r]';
%     fileID = fopen(filename,'r');
%     dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
%     fclose(fileID);
%     data_Summit = table(dataArray{1:end-1}, 'VariableNames', {'Year','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec','DJF','MAM','JJA','SON','ANN'});
%     clearvars filename startRow formatSpec fileID dataArray ans;
%     data_Summit(:,14:end) = [];
%     data_Summit = standardizeMissing(data_Summit,999.9);
%     data_Summit = standardizeMissing(data_Summit,999);

    %% loading Tasilaq

    filename = 'C:\Users\bava\OwnCloud_new\Data\Historical Weather\DMI temperature precipitation\gr_monthly_all_1784_2016.csv';
    delimiter = ';';

    formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);

    fclose(fileID);

    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
        % Converts strings in the input cell array to numbers. Replaced non-numeric
        % strings with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1)
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\.]*)+[\,]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\.]*)*[\,]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if any(numbers=='.')
                    thousandsRegExp = '^\d+?(\.\d{3})*\,{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, '.', 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric strings to numbers.
                if ~invalidThousandsSeparator
                    numbers = strrep(numbers, '.', '');
                    numbers = strrep(numbers, ',', '.');
                    numbers = textscan(numbers, '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch me
            end
        end
    end


    rawNumericColumns = raw(:, [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]);
    rawCellColumns = raw(:, 17);

    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
    rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

    data_Tasilaq = table;
    data_Tasilaq.stat_no = cell2mat(rawNumericColumns(:, 1));
    data_Tasilaq.elem_no = cell2mat(rawNumericColumns(:, 2));
    data_Tasilaq.year = cell2mat(rawNumericColumns(:, 3));
    data_Tasilaq.jan = cell2mat(rawNumericColumns(:, 4));
    data_Tasilaq.feb = cell2mat(rawNumericColumns(:, 5));
    data_Tasilaq.mar = cell2mat(rawNumericColumns(:, 6));
    data_Tasilaq.apr = cell2mat(rawNumericColumns(:, 7));
    data_Tasilaq.may = cell2mat(rawNumericColumns(:, 8));
    data_Tasilaq.jun = cell2mat(rawNumericColumns(:, 9));
    data_Tasilaq.jul = cell2mat(rawNumericColumns(:, 10));
    data_Tasilaq.aug = cell2mat(rawNumericColumns(:, 11));
    data_Tasilaq.sep = cell2mat(rawNumericColumns(:, 12));
    data_Tasilaq.oct = cell2mat(rawNumericColumns(:, 13));
    data_Tasilaq.nov = cell2mat(rawNumericColumns(:, 14));
    data_Tasilaq.dec = cell2mat(rawNumericColumns(:, 15));

    clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;

    ind = data_Tasilaq.stat_no == 4360;
    data_Tasilaq = data_Tasilaq(ind,:);
    data_Tasilaq(:,[1 2]) = [];
    data_Tasilaq(123:end,:) = [];

    %% yearly and seasonal average

    T_avg{length(T_avg)+1} = TempAvg(data_Ilulissat);
    T_avg{length(T_avg)+1} = TempAvg(data_Kanger);
    T_avg{length(T_avg)+1} = TempAvg(data_Tasilaq);
%     T_avg{length(T_avg)+1} = TempAvg(data_Summit);

    %% Loading extra years
    for i = length(station_list_in)+1:length(station_list_in)+2
    switch i
    %     case 7 %Tasilaq doesnt need extra data
    %         stat_no = 4360;
        case length(station_list_in)+1
            stat_no= 4221;
        case length(station_list_in)+2
            stat_no = 04231;
    end

    filename = sprintf( ...
    'C:/Users/bava/OwnCloud_new/Data/Historical Weather/DMI temperature precipitation/2014-2016/%i_2014_2016.csv',...
    stat_no);
    delimiter = ';';
    formatSpec = '%s%s%s%s%s%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
    fclose(fileID);
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,2,3,4,5,6]
        % Converts strings in the input cell array to numbers. Replaced non-numeric
        % strings with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1)
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\.]*)+[\,]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\.]*)*[\,]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if any(numbers=='.')
                    thousandsRegExp = '^\d+?(\.\d{3})*\,{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, '.', 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric strings to numbers.
                if ~invalidThousandsSeparator
                    numbers = strrep(numbers, '.', '');
                    numbers = strrep(numbers, ',', '.');
                    numbers = textscan(numbers, '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch me
            end
        end
    end

    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells

    data_extra = table;
    data_extra.Station = cell2mat(raw(:, 1));
    data_extra.year = cell2mat(raw(:, 2));
    data_extra.month = cell2mat(raw(:, 3));
    data_extra.day = cell2mat(raw(:, 4));
    data_extra.hour = cell2mat(raw(:, 5));
    data_extra.AirTemperatureC = cell2mat(raw(:, 6));

    clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me R;

    data_extra.time = datenum(data_extra.year,data_extra.month,data_extra.day,data_extra.hour,0,0);
    data_extra(:,1:5) = [];
    data_extra(1,:) = [];
    data_extra = fliplr(data_extra);
    data_extra =ResampleTable(data_extra);
    [T_avg_extra] = seasonal_avg_table(data_extra);


    T_avg{i} = vertcat(T_avg{i}, T_avg_extra);
    end
    
    station_list_save = station_list;
    T_avg_save = T_avg;

    %% Plot Yearly average

for ii = 1:2
    if ii==1 
        station_list = {station_list_save{1:length(station_list_in)}};
        T_avg = {T_avg_save{1:length(station_list_in)}};
    else
        station_list = {station_list_save{(length(station_list_in)+1):end}};
        T_avg = {T_avg_save{(length(station_list_in)+1):end}};
    end

    f=figure('Visible',vis);
    ha = tight_subplot(2,1,0.002,0.07,[0.07 0.4]);
    lm = {};
    axes(ha(1))
    hold on
        leg_text={};
    for i = 1:length(station_list)
        h(i)=plot(T_avg{i}.Year, T_avg{i}.avg_year, ...
            'LineWidth',2);
        [lm{i}, ~] = Plotlm(T_avg{i}.Year(~isnan(T_avg{i}.avg_year)), ...
            T_avg{i}.avg_year(~isnan(T_avg{i}.avg_year)), ...
            'LineWidth',1, 'Annotation','off');
    %     set(ah,'position',get(ah,'position')-[1 0 0 0]);
         fprintf('%s %i %i\n',station_list{i}, ...
            min(T_avg{i}.Year(~isnan(T_avg{i}.avg_year))),...
            max(T_avg{i}.Year(~isnan(T_avg{i}.avg_year))))
        leg_text{i} = sprintf('%s (%0.2f ^o/dec pvalue %0.2f)', ...
            station_list{i},lm{i}.Coefficients.Estimate(2)*10, ...
             max(lm{i}.Coefficients.pValue));
    end  

    box on
    set(gca,'YMinorTick','on','XMinorTick','on','XTickLabel','')
    axis tight
    if ii==2
        xlim([1990 2014])
    else
        xlim([1997 2014])
    end   
    h_title = title(sprintf('a) Annual Mean'));
    h_title.Units = 'normalized';
    h_title.Position = [0.15 0.85 0];
    h_leg = legend(h,leg_text, 'Location','EastOutside');
    h_leg.Units = 'normalized';
    h_leg.Position(1) = 0.63;
    legend boxoff
    ylabel('Air Temperature (degC)')

    % plot JJA average
    axes(ha(2))
    h=[];
    hold on
    lm = {};
    % data from inland station
            leg_text={};
    for i = 1:length(T_avg)
        h(i)=plot(T_avg{i}.Year, T_avg{i}.avg_JJA,...
            'LineWidth',2);
        [lm{i}, ah]=Plotlm(T_avg{i}.Year(~isnan(T_avg{i}.avg_JJA)), ...
            T_avg{i}.avg_JJA(~isnan(T_avg{i}.avg_JJA)), ...
            'LineWidth',1, 'Annotation','off');
         fprintf('%s %i %i\n',station_list{i}, ...
            min(T_avg{i}.Year(~isnan(T_avg{i}.avg_JJA))),...
            max(T_avg{i}.Year(~isnan(T_avg{i}.avg_JJA))))
        leg_text{i} = sprintf('%s (%0.2f ^o/dec pvalue %0.2f)', ...
        station_list{i},lm{i}.Coefficients.Estimate(2)*10,...
         max(lm{i}.Coefficients.pValue));
    end

    h_leg = legend(h,leg_text, 'Location','EastOutside');
    h_leg.Units = 'normalized';
    h_leg.Position(1) = 0.63;
    legend boxoff
    xlabel('Date')
    % axis tight
    box on
    axis tight
    if ii==2
        xlim([1990 2014])
    else
        xlim([1997 2014])
    end
    set(gca,'YMinorTick','on','XMinorTick','on')
    ylabel('Air Temperature (degC)')
    h_title=title(sprintf('b) JJA average'));
    h_title.Units = 'normalized';
    h_title.Position = [0.15 0.85 0];
    print(f,sprintf('./Output/data_overview/Comp_Historical_Temperature_%i',ii),'-dtiff');
end

    station_list = station_list_save;
    T_avg = T_avg_save;
    
    %% Trend analysis annual values
    clc
    trend_annual = table;
    trend_annual.no = (1:6)';

    trend_annual.start_year(1) = 1998;
    trend_annual.end_year(1) = 2010;

    trend_annual.start_year(2) = 1998;
    trend_annual.end_year(2) = 2015;

    trend_annual.start_year(3) = 2000;
    trend_annual.end_year(3) = 2015;

    % trend_annual.start_year(4)= 2001;
    % trend_annual.end_year(4) = 2014;
    % 
    % trend_annual.start_year(5) = 2001;
    % trend_annual.end_year(5) = 2010;
    % 
    % trend_annual.start_year(6) = 1985;
    % trend_annual.end_year(6) = 2014;

    for i =1:length(station_list)
        temp = strrep(station_list{i},'-','');

        name_slope = sprintf('slope_%s',temp);
        name_pvalue = sprintf('pvalue_%s',temp);
        name_rmse = sprintf('rmse_%s',temp);

        trend_annual.(name_slope) = (1:length(trend_annual.no))';
        trend_annual.(name_pvalue) = (1:length(trend_annual.no))';
        trend_annual.(name_rmse) = (1:length(trend_annual.no))';

        years = T_avg{i}.Year;
        T_year = T_avg{i}.avg_year;
        years_nonan = years(~isnan(T_year)); %years for which annual average is available

        for j = 1:length(trend_annual.no)
            % we calculate things only if start and end years of the period are
            % available
            if ismember(trend_annual.start_year(j),years_nonan) && ...
                    ismember(trend_annual.end_year(j),years_nonan)
                years_period = (trend_annual.start_year(j):trend_annual.end_year(j))';
                T_period = T_year(ismember(years,years_period));

                lm = fitlm(years_period, T_period);
                trend_annual.(name_slope)(j) = lm.Coefficients.Estimate(2)*10;
                trend_annual.(name_pvalue)(j) = max(lm.Coefficients.pValue);
                trend_annual.(name_rmse)(j) = lm.RMSE;
            else
                trend_annual.(name_slope)(j) = NaN;
                trend_annual.(name_pvalue)(j) = NaN;
                trend_annual.(name_rmse)(j) = NaN;
            end
        end
    end

    writetable(trend_annual,'./Output/data_overview/trend_annual.csv','Delimiter' ,';');

    %% trend analysis for JJA means
    trend_JJA = table;
    trend_JJA.no = (1:6)';

    trend_JJA.start_year(1) = 1995;
    trend_JJA.end_year(1) = 2010;

    trend_JJA.start_year(2) = 1997;
    trend_JJA.end_year(2) = 2014;

    trend_JJA.start_year(3) = 1998;
    trend_JJA.end_year(3) = 2014;

    trend_JJA.start_year(4) = 2001;
    trend_JJA.end_year(4) = 2014;

    trend_JJA.start_year(5) = 2001;
    trend_JJA.end_year(5) = 2010;

    trend_JJA.start_year(6) = 1985;
    trend_JJA.end_year(6) = 2014;



    for i =1:length(station_list)
        temp = strrep(station_list{i},'-','');

        name_slope = sprintf('slope_%s',temp);
        name_pvalue = sprintf('pvalue_%s',temp);
        name_rmse = sprintf('rmse_%s',temp);

        trend_JJA.(name_slope) = (1:length(trend_JJA.no))';
        trend_JJA.(name_pvalue) = (1:length(trend_JJA.no))';
        trend_JJA.(name_rmse) = (1:length(trend_JJA.no))';

        years = T_avg{i}.Year;
        T_year = T_avg{i}.avg_JJA;
        years_nonan = years(~isnan(T_year)); %years for which annual average is available

        for j = 1:length(trend_JJA.no)
            % we calculate things only if start and end years of the period are
            % available
            if ismember(trend_JJA.start_year(j),years_nonan) && ...
                    ismember(trend_JJA.end_year(j),years_nonan)
                years_period = (trend_JJA.start_year(j):trend_JJA.end_year(j))';
                T_period = T_year(ismember(years,years_period));

                lm = fitlm(years_period, T_period);
                trend_JJA.(name_slope)(j) = lm.Coefficients.Estimate(2)*10;
                trend_JJA.(name_pvalue)(j) = max(lm.Coefficients.pValue);
                trend_JJA.(name_rmse)(j) = lm.RMSE;
            else
                trend_JJA.(name_slope)(j) = NaN;
                trend_JJA.(name_pvalue)(j) = NaN;
                trend_JJA.(name_rmse)(j) = NaN;
            end
        end
    end
    writetable(trend_JJA,'./Output/data_overview/trend_JJA.csv','Delimiter' ,';');

end

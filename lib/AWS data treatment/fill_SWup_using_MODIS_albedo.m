function [data, data_modis] = fill_SWup_using_MODIS_albedo(...
    data, station, is_GCnet, OutputFolder , AlbedoStandardValue, vis)
% this function loads MODIS albedo for GCnet or PROMICE stations and
% applies it on the available downward shortwave radiation to reconstruct
% missing upward shortwave radiation
    
%% Uploading MODIS albedo data
if is_GCnet
    filename = '..\MODIS_C6\ALL_YEARS_MOD10A1_C6_500m_d_nn_daily.txt';

    formatSpec = '%2f%5f%4f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fileID);
    data_modis = table(dataArray{1:end-1}, 'VariableNames', ...
        {'station','year','day','albedo'});
    clearvars filename formatSpec fileID dataArray ans;
    
    filename = 'Input\GCnet\Gc-net_documentation_Nov_10_2000.csv';
    delimiter = ';';
    formatSpec = '%s%s%s%s%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
    fclose(fileID);
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,3,4,5]
        % Converts strings in the input cell array to numbers. Replaced non-numeric
        % strings with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1);
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\.]*)+[\,]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\.]*)*[\,]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if any(numbers=='.');
                    thousandsRegExp = '^\d+?(\.\d{3})*\,{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, '.', 'once'));
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric strings to numbers.
                if ~invalidThousandsSeparator;
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

    rawNumericColumns = raw(:, [1,3,4,5]);
    rawCellColumns = raw(:, 2);

    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
    rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

    GCnetCode = table;
    GCnetCode.ID = cell2mat(rawNumericColumns(:, 1));
    GCnetCode.Name = rawCellColumns(:, 1);
    GCnetCode.Northing = cell2mat(rawNumericColumns(:, 2));
    GCnetCode.Easting = cell2mat(rawNumericColumns(:, 3));
    GCnetCode.Elevation = cell2mat(rawNumericColumns(:, 4));
    GCnetCode(1,:) = [];

    clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;
    
    if strcmp(station,'CP1')
        ind = strfind_cell(GCnetCode.Name,'Crawford Pt.');
    elseif strcmp(station,'SouthDome')
        ind = strfind_cell(GCnetCode.Name,'South Dome');        
    elseif strcmp(station,'SwissCamp')
        ind = strfind_cell(GCnetCode.Name,'Swiss Camp');        
    else
        ind = strfind_cell(GCnetCode.Name,station);
    end
    
    if ~isempty(ind)
        fprintf('%s''s ID number is %i\n',station, ind);
        
        data_modis = data_modis(...
            data_modis.station == GCnetCode.ID(ind) - 1, :);
    else
        data_modis = [];
    end
else
    % Loading MODIS data
%    filename = 'C:\Users\bava\ownCloud\Phd_owncloud\Data\MODIS_C6\data\ALL_YEARS_MOD10A1_C6_500m_d_nn_at_PROMICE_daily_columns_cumulated.txt';
    filename = '..\MODIS_C6\data\ALL_YEARS_MOD10A1_C6_500m_d_nn_at_PROMICE_daily_columns_cumulated.txt';

    formatSpec = '%4f%4f%9f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%8f%f%[^\n\r]';

    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fileID);
    PROMICE_MODIS = [dataArray{1:end-1}];
    clearvars filename formatSpec fileID dataArray ans;
    
%     Loading station codes
    filename = '..\MODIS_C6\data\PROMICE station codes.txt';
    delimiter = ' ';
    formatSpec = '%*s%*s%*s%s%s%*s%*s%s%*s%*s%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
    fclose(fileID);

    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,3,4]
        % Converts strings in the input cell array to numbers. Replaced non-numeric
        % strings with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1);
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if any(numbers==',');
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, ',', 'once'));
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric strings to numbers.
                if ~invalidThousandsSeparator;
                    numbers = textscan(strrep(numbers, ',', ''), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch me
            end
        end
    end

    rawNumericColumns = raw(:, [1,3,4]);
    rawCellColumns = raw(:, 2);

    PromiceCode = table;
    PromiceCode.Code = cell2mat(rawNumericColumns(:, 1));
    PromiceCode.Name = rawCellColumns(:, 1);
    PromiceCode.Lat = cell2mat(rawNumericColumns(:, 2));
    PromiceCode.Lon = cell2mat(rawNumericColumns(:, 3));
    clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns;

    ind = strfind_cell(PromiceCode.Name,station) -1;
    if ~isempty(ind)
        fprintf('%s''s ID number is %i\n',station, ind);
        data_modis = table;
        data_modis.station = strfind_cell(PromiceCode.Name,station)*ones(size(PROMICE_MODIS(:,1)));
        data_modis.year = PROMICE_MODIS(:,1);
        data_modis.day = PROMICE_MODIS(:,2);
        data_modis.albedo = PROMICE_MODIS(:,ind+3);
    else
% if cannot find station then we give table "data_MODIS" empty
% later on the station climatology in albedo will be used instead
        ind = 18;
    % Ask Jason Box (jeb@geus.dk) to provide MODIS time series at other stations
    fprintf('No MODIS data available for %s\n',station);
        data_modis = table;
        data_modis.station = 18*ones(size(PROMICE_MODIS(:,1)));
        data_modis.year = PROMICE_MODIS(:,1);
        data_modis.day = PROMICE_MODIS(:,2);
        data_modis.albedo = NaN(size(data_modis.day));
    end


end

    data_modis = standardizeMissing(data_modis,999);

    DV  = datevec(data.time);  % [N x 6] array

    ind = find(data_modis.year==DV(1,1),1,'first');
    if ~isempty(ind)
        data_modis = data_modis(ind:end,:);
    end
    ind = find(data_modis.year>DV(end,1),1,'first');
    if ~isempty(ind)
        data_modis = data_modis(1:ind-1,:);
    end
    
    % from the MODIS albedo we construct an average albedo depending on the day
    % of the year. It will be used when MODIS data is not available.
    albedo_avg = NaN(1,365);
    for i = 62 :301
        albedo_avg(i) = nanmean(data_modis.albedo(data_modis.day==i));
    end
    albedo_avg(isnan(albedo_avg)) = AlbedoStandardValue;

    % Now we calculate the albedo given by the station
    albedo = data.ShortwaveRadiationUpWm2./data.ShortwaveRadiationDownWm2;
    albedo(albedo>1)=NaN;
    albedo(albedo<0.5)=NaN;
    albedo(data.ShortwaveRadiationUpWm2_Origin~=0) = NaN;
    albedo_tab = table(data.time,...
        albedo,...
        'VariableNames',{'time','albedo'});
    albedo_tab = AvgTable(albedo_tab,'daily','mean');

    DV  = datevec(albedo_tab.time);  % [N x 6] array
    DV  = DV(:, 1:3);   % [N x 3] array, no time
    DV2 = DV;
    DV2(:, 2:3) = 0;    % [N x 3], day before 01.Jan
    albedo_tab.day=datenum(DV) - datenum(DV2);
    albedo_tab.year=DV(:,1);

    albedo_avg_station = NaN(1,365);

    for i = 62 :301
        albedo_avg_station(i) = nanmean(albedo_tab.albedo(albedo_tab.day==i));
    end
    albedo_avg_station(isnan(albedo_avg_station)) = 0.8;

    f = figure('Visible',vis);
    [ha, ~] = tight_subplot(1, 2, 0.1, [0.15 0.3], 0.1);
    set(f,'CurrentAxes',ha(1))
    hold on
    list_year = unique(data_modis.year);
    leg_text = cell(0);

    for i=1:length(list_year)
        temp = data_modis(data_modis.year==list_year(i),:);
        plot(62:301,temp.albedo)
        leg_text = [leg_text, num2str(list_year(i))];
    end

    plot(62:301,albedo_avg(62:301),'r','LineWidth',4)
    leg_text = [leg_text, 'Average'];

    legendflex(leg_text, 'ref', gca, ...
                       'anchor',  [2 6] , ...
                       'buffer',[0 10], ...
                       'ncol',3, ...
                       'fontsize',13);


    axis tight
    box on
    ylabel('Albedo')
    title('MODIS')
    xlabel('Day of the year')
    xlimit = get(gca,'XLim');
    ylimit = get(gca,'YLim');
    set(f,'CurrentAxes',ha(2))
    hold on
    list_year = unique(albedo_tab.year);
    leg_text = cell(0);

    for i=1:length(list_year)
        temp = albedo_tab(albedo_tab.year==list_year(i),:);
        plot(temp.day,temp.albedo)
        leg_text = [leg_text, num2str(list_year(i))];
    end

    plot(62:301,albedo_avg_station(62:301),'r','LineWidth',4)
    leg_text = [leg_text, 'Average'];
    title('Weather station')
    legendflex(leg_text, 'ref', gca, ...
                       'anchor',  [2 6] , ...
                       'buffer',[0 10], ...
                       'ncol',3, ...
                       'fontsize',13);
    ylabel('Albedo')
    xlabel('Day of the year')
    xlim(xlimit)
    ylim([max(0,ylimit(1)), min(1,ylimit(2))])
    box on
    print(f, sprintf('%s/albedo_MODIS_station_climatology',OutputFolder), '-dpng')


    data_modis.time = datenum(data_modis.year,1,data_modis.day);
    list_year = 2001:2016;
%     here are plotted all the year by year comparison of MODIS vs. station
%     albedos

    f = figure('Visible',vis);
    ha = tight_subplot(4,4, [0.03 0.01],[0.15 0.15],0.05);
    for i = 1:length(list_year)
        temp = albedo_tab(albedo_tab.year==list_year(i),:);
        temp2 = data_modis(data_modis.year==list_year(i),:);
        if ~isempty(temp)
            set(f,'CurrentAxes',ha(i))
            hold on
            plot(temp.time,temp.albedo,'r','LineWidth',2)
            plot(temp2.time,temp2.albedo,'b','LineWidth',2)
            h_title = title(num2str(list_year(i)));
            h_title.Units = 'normalized';
            h_title.Position(1:2) = [.15 .03];
            if i==3
                legendflex({'AWS','MODIS'},'ref',gcf','anchor',{'n', 'n'},'nrow',1,'title',sprintf('Daily albedo at %s',station))
            end
            set_monthly_tick(temp.time)
            xlim(temp.time([1 end]))
        else
            set(ha(i),'Visible','off')
            
        end
            axis fill
            ylim([0.6 1])
            if ismember(i, 13:16)
                datetick('x','dd-mmm', 'keepticks', 'keeplimits')
                xticklabels = get(gca,'XTickLabel');
                for ii =1:length(xticklabels)
                    if floor(ii/2)==ii/2
                        xticklabels(ii,:) = '      ';
                    end
                end
                set(gca,'XTickLabel',xticklabels)
                set(gca, 'XTickLabelRotation',45)
            else
                set(gca,'XTickLabel','')
            end
            if ismember(i, 4:4:16)
                set(gca,'YAxisLocation','right')
            elseif ~ ismember(i, 1:4:13)
                set(gca,'YTickLabel','')
            end

            box on
            set (gca,'XMinorTick','off','YMinorTick','on')
%             datetick('x','dd/mm','keeplimits','keepticks')
    end
    print(f, sprintf('%s/albedo_MODIS_station_comp',OutputFolder), '-dpng')

%             subplot(1,2,2)
%             CompareData(station, 'MODIS', temp, 'albedo', temp2,'albedo');
%             plot(0:1,0:1,'k')
%             axis tight square
%             xlim([0 1])
%             ylim([0 1])
    f = figure('Visible',vis);
    plot(albedo_tab.time,albedo_tab.albedo)
    hold on
    plot(data_modis.time,data_modis.albedo,'LineWidth',2)
    set_monthly_tick(albedo_tab.time);

    axis tight
%     xlim([datenum('01-Jan-2000') datenum('01-Jan-2011')])
    set(gca,'YMinorTick','on','XMinorTick','on')
    ylabel('Albedo')
    xlabel('Date')
    legend('AWS','MODIS C6','Location','SouthEast')
    print(f, sprintf('%s/albedo_MODIS_station',OutputFolder), '-dpng')

    if sum(~isnan(data_modis.albedo))>10
        data_modis.albedo = interp1gap(data_modis.albedo)';
    end
    data.ShortwaveRadiationUpWm2(...
        data.ShortwaveRadiationUpWm2<0) = NaN;
    data.ShortwaveRadiationDownWm2(...
        data.ShortwaveRadiationDownWm2<0) = NaN;

    % reconstructing missing upward shortwave radiation flux using the observed
    % downward and the modis-derived albedo
    
    % creating variable that will receive the MODIS or average albedo
    data_modis_new = table;
    
    % assigning in that new variable the MODIS albedo whenever is possible
    ind_binned = discretize(data.time,data_modis.time);
    data_modis_new.time = data.time;
    data_modis_new.albedo = NaN(size(data_modis_new.time));
%     index in newtime when modis is available
    ind_modis_newtime = ~isnan(ind_binned);
    data_modis_new.albedo(ind_modis_newtime) = ...
        data_modis.albedo(ind_binned(ind_modis_newtime));
    
    % where there is no modis albedo we need to take it from the
    % station climatology
    DV  = datevec(data.time);  % [N x 6] array
    DV  = DV(:, 1:3);   % [N x 3] array, no time
    DV2 = DV;
    DV2(:, 2:3) = 0;    % [N x 3], day before 01.Jan
    DayOfYear=datenum(DV) - datenum(DV2);
    DayOfYear (DayOfYear== 366)= 365;
    
    data_modis_new.albedo(isnan(data_modis_new.albedo)) = ...
        albedo_avg_station(DayOfYear(isnan(data_modis_new.albedo)));
    
    % if there is still some places where neither station ormodis albedo
    % were available, then we use the standard value
    data_modis_new.albedo(isnan(data_modis_new.albedo)) = AlbedoStandardValue;
    
    %now we should have modis/station/standard albedo for all time step
    % so we can gapfill the missing upward radiation
    data_old = data;
                
    data.ShortwaveRadiationUpWm2_Origin(isnan(data.ShortwaveRadiationUpWm2)) = 5;

    data.ShortwaveRadiationUpWm2(isnan(data.ShortwaveRadiationUpWm2)) = ...
        data.ShortwaveRadiationDownWm2(isnan(data.ShortwaveRadiationUpWm2)) ...
        .* data_modis_new.albedo(isnan(data.ShortwaveRadiationUpWm2));
    
    data.ShortwaveRadiationUpWm2(data.ShortwaveRadiationUpWm2<0) = NaN;
    data.ShortwaveRadiationUpWm2(isnan(data.ShortwaveRadiationUpWm2)) =...
        AlbedoStandardValue*data.ShortwaveRadiationDownWm2(isnan(data.ShortwaveRadiationUpWm2));

    % plotting result
    f = figure('Visible',vis);
    h1 = plot(data.time, data.ShortwaveRadiationUpWm2);
    hold on
    h2 = plot(data_old.time,data_old.ShortwaveRadiationUpWm2);
    axis tight
    set_monthly_tick(data.time);
    datetick('x','yyyy','keeplimits','keepticks')
    xlabel('Time')
    ylabel('Upward shortwave radiation (W/m^2)')
    legend([h2 h1],'available data', 'calculated using MODIS albedo')
    set(gca,'XTickLabelRotation',45)
    print(f, sprintf('%s/albedo_gapfilled_upSW',OutputFolder), '-dpng')
    % else
    %     disp('Shortwave Up already in dataset')
    % end

    % Filtering out periods when net shortwave radiation are negative dueto
    % erroneous MODIS gapfilling values

    % netSW = data_combined.ShortwaveRadiationDownWm2 - data_combined.ShortwaveRadiationUpWm2;
    % figure('Visible',vis);
    % subplot(2,1,1)
    % plot(data_combined.time,netSW)
    % subplot(2,1,2)
    % hold on
    % 
    % plot(data_combined.time,data_combined.ShortwaveRadiationDownWm2)
    % plot(data_combined.time,data_combined.ShortwaveRadiationUpWm2)
    % legend('in','out')

    data.ShortwaveRadiationDownWm2(...
        data.ShortwaveRadiationUpWm2 >= 0.97*data.ShortwaveRadiationDownWm2) = ...
        data.ShortwaveRadiationUpWm2(...
        data.ShortwaveRadiationUpWm2 >= 0.97*data.ShortwaveRadiationDownWm2)./0.95;
    
%     netSW = data.ShortwaveRadiationDownWm2 - data.ShortwaveRadiationUpWm2;
    % figure('Visible',vis)
    % subplot(2,1,1)
    % plot(data_combined.time,netSW)
    % subplot(2,1,2)
    % hold on
    % 
    % plot(data_combined.time,data_combined.ShortwaveRadiationDownWm2)
    % plot(data_combined.time,data_combined.ShortwaveRadiationUpWm2)
% legend('in','out')

end
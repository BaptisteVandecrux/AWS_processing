function RCMTemperaturePlot(station_list,data_in,vis)
%%      Loading all RACMO-Box data
        filename = '.\Input\StationInfo.csv';
        delimiter = ';';
        startRow = 2;
        formatSpec = '%s%f%f%f%s%s%s%s%s%s%[^\n\r]';
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
        fclose(fileID);
        StationInfo = table(dataArray{1:end-1}, 'VariableNames', {'stationname','latitude','longitude','elevationm','deepfirntemperaturedegC','slopedeg','meanaccumulationm_weq','InitialheightTm','InitialheightWSm','VarName10'});
        clearvars filename delimiter startRow formatSpec fileID dataArray ans;

        % loading Box 2013 accumulation rates
        namefile = '..\Box 2013\Box_Greenland_Temperature_monthly_1840-2014_5km_cal_ver20141007.nc';
        finfo = ncinfo(namefile);
        names={finfo.Variables.Name};
        for i= 1:size(finfo.Variables,2)
            eval(sprintf('%s = ncread(''%s'',''%s'');', char(names{i}), namefile,char(names{i})));
        end
        fprintf('\nData extracted from nc files.\n');
        
%% Starting for each site        
    for kk = 1:length(station_list)
        station = station_list{kk};
        data = data_in{kk};
        disp('---------')
        disp(station)
        
        %% load HIRHAM data

        filename = sprintf('../RCM/HIRHAM_GL2/Output/Final/HIRHAM_GL2_%s_1981_2014.txt',station);
        delimiter = ',';
        formatSpec = '%f%f%f%f%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
        fclose(fileID);
        data_HIRHAM = table(dataArray{1:end-1}, 'VariableNames', ...
            {'tas', 'ps', 'relhum', 'dswrad', 'dlwrad', 'wind10','time'});
        clearvars filename delimiter formatSpec fileID dataArray ans;
        data_HIRHAM = standardizeMissing(data_HIRHAM,-999);

        % here the HIRHAM datais interpolated to hourly time steps
        data_HIRHAM = ResampleTable(data_HIRHAM);
        
        %% extracting RACMO-Box13 data
        switch station
            case 'SwissCamp'
                ind = find(strcmp('Swiss Camp',StationInfo.stationname));
            case 'SouthDome'
                ind = find(strcmp('South Dome',StationInfo.stationname));
            otherwise
                ind = find(strcmp(station,StationInfo.stationname));
        end
        c.lat = StationInfo.latitude(ind);
        c.lon = StationInfo.longitude(ind);
        
        dist = sqrt((lat-c.lat).^2 + (lon-c.lon).^2);

        [dist_sorted, ind] = sort((dist(:)));
        temp_Box = zeros(175,12);
        temp = zeros(175,12);
        for i = 1:4
            [ii , jj]  = ind2sub(size(dist),ind(i));
            for k = 1:12
                temp(:,k) = squeeze(Temperature(ii,jj,k,:));
            end
            temp_Box = temp_Box+temp;
        end
        temp_Box = temp_Box./4;
        temp_Box(1:130,:) = [];
        
        %% Loading MAR data
        if strcmp(station,'CP1')
            filename = '../RCM/MAR/MAR_CrawfordPt._1979-2014_monthly.txt';
        else
            filename = sprintf('../RCM/MAR/MAR_%s_1979-2014_monthly.txt',station);
        end
        delimiter = ',';
        formatSpec = '%f%f%f%[^\n\r]';
        fileID = fopen(filename,'r');
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
        fclose(fileID);
        data_MAR = table(dataArray{1:end-1}, 'VariableNames', {'T','Tcorr','SMB'});
        clearvars filename delimiter formatSpec fileID dataArray ans;
        data_MAR.time = datenum(1979,1:12*36,15)';
        
        %% Comparison mean annual
        data_yearly = AvgTable(data,'yearly','mean',90);
        % if first year starts later than Jan 15th: NaN
        if data.DayOfYear(1) > 15
    %         data_yearly.AirTemperature2C(1) = NaN;
            data_yearly(1,:) = [];        
        end
        % if last year ends earlier than Dec 15th: NaN
        if data.DayOfYear(end) <= 349
    %         data_yearly.AirTemperature2C(end) = NaN;
            data_yearly(end,:) = [];
        end

        data_HIRHAM_yearly = AvgTable(data_HIRHAM,'yearly','mean',90);
        data_MAR_yearly = AvgTable(data_MAR,'yearly','mean',90);

        time_Box_yearly = datenum(1970:2014,1,1);
        T_Box_yearly=NaN(length(temp_Box),1);
        for i = 1:size(temp_Box,1)
            T_Box_yearly(i) = mean(temp_Box(i,:));
        end
        T_Box_yearly(end)=NaN;

        %% Comparison mean JJA
        % calculating JJA at station
        temp = datevec(data.time);
        ind_JJA = ismember(temp(:,2),[6 7 8]);
        data_JJA = data(ind_JJA,...
            [find(strcmp(data.Properties.VariableNames,'time')) ...
            find(strcmp(data.Properties.VariableNames,'AirTemperature2C'))]);
        data_JJA = AvgTable(data_JJA,'yearly','mean',90);
        temp = datevec(data_JJA.time);
        data_JJA.time = temp(:,1);
        % if first year starts later than June: NaN
        if data.MonthOfYear(1) > 6
    %         data_JJA.AirTemperature2C(1) = NaN;
            data_JJA(1,:) = [];
        end
        % if last year ends earlier than August: NaN
        if data.MonthOfYear(end) < 8
    %         data_JJA.AirTemperature2C(end) = NaN;
            data_JJA(end,:) = [];
        end

        %calculating JJA for HIRHAM
        temp = datevec(data_HIRHAM.time);
        ind_JJA_HIRHAM = ismember(temp(:,2),[6 7 8]);
        data_HIRHAM_JJA = data_HIRHAM(ind_JJA_HIRHAM,[1 2]);
        data_HIRHAM_JJA = AvgTable(data_HIRHAM_JJA,'yearly','mean',90);

        temp = datevec(data_HIRHAM_JJA.time);
        data_HIRHAM_JJA.time = temp(:,1);

        %calculating JJA for MAR
        time_MAR = datevec(data_MAR.time);
        ind_JJA_MAR = ismember(time_MAR(:,2),[6 7 8]);
        data_MAR_JJA = data_MAR(ind_JJA_MAR,[1 4]);
        data_MAR_JJA = AvgTable(data_MAR_JJA,'yearly','mean',90);

        temp = datevec(data_MAR_JJA.time);
        data_MAR_JJA.time = temp(:,1);

        % calculating JJA for RACMO/Box13
        year_box = 1970:2014;
        T_Box_JJA=NaN(size(temp_Box,1),1);
        for i=1:size(temp_Box,1)
            T_Box_JJA(i) = mean(temp_Box(i,6:8));
        end
        % T_Box_JJA(end)=NaN;

        %% plotting
        switch station
            case 'CP1'
                station = 'Crawford Point';
            case 'DYE-2'
                station = 'Dye 2';
        end

        f = figure('Visible',vis);
        h=[];
        ha = tight_subplot(2,1,0.01,[0.08 0.01],[0.06 0.02]);
    %     ha = tight_subplot(2,1,0.01,[0.08 0.01],[0.06 0.02]);
        axes(ha(1))
        hold on
        h(1) = plot(data_HIRHAM_yearly.time, data_HIRHAM_yearly.tas-273.15,'LineWidth',2);
        [lm{1}, ~] = Plotlm(data_HIRHAM_yearly.time(end-18:end), data_HIRHAM_yearly.tas(end-18:end)-273.15,'Annotation','off');
        % set(ah2,'parent',gca)
        % set(ah2,'position',get(ah2,'position') + [0 2.1 0 0])
        h(2) = plot(time_Box_yearly,T_Box_yearly,'LineWidth',2);
        [lm{2}, ~] = Plotlm(time_Box_yearly(end-18:end),T_Box_yearly(end-18:end),'Annotation','off');
        % set(ah3,'parent',gca)
        % set(ah3,'position',get(ah3,'position') + [1000 1.1 0 0])
        h(4) = plot(data_yearly.time, data_yearly.AirTemperature2C,'LineWidth',2);
        [lm{4}, ~] = Plotlm(data_yearly.time, data_yearly.AirTemperature2C,'Annotation','off');
        % set(ah1,'parent',gca)
        % set(ah1,'position',get(ah1,'position') + [0 0 0 0])
        h(3) = plot(data_MAR_yearly.time, data_MAR_yearly.T,'LineWidth',2);
        [lm{3}, ~] = Plotlm(data_MAR_yearly.time(end-18:end), data_MAR_yearly.T(end-18:end), 'Annotation','off');
        % set(ah4,'parent',gca)
        % set(ah4,'position',get(ah2,'position') + [0 2.1 0 0])
        text = {'HIRHAM','RACMO/Box13','MAR',station};
        leg_text=[];
        for i = 1:4
            leg_text{i} = sprintf('%s (slope: %0.2f degC/dec, p-value: %0.2f)',...
                text{i}, lm{i}.Coefficients.Estimate(2)*365.25*10, max(lm{i}.Coefficients.pValue));
        end
        legend(h,leg_text,'Location','NorthWest')
        legend boxoff
        axis tight
        xlim([datenum('01-Jan-1970') datenum('01-Jan-2015')])
        box on
        set(gca,'Xtick', datenum(1970:5:2015,1,1))
        set(gca,'YMinorTick','on','XMinorTick','on','XTickLabel','')
        ylabel('Air Temperature (^{\circ}C)')
        h_title = title(sprintf('Annual Mean %s',station));
        set(h_title,'parent',gca);
        set(h_title,'position',get(h_title,'position') + [0 -1 0 ])

        h=[];
        axes(ha(2))
        hold on
        h(1) = plot(data_HIRHAM_JJA.time, data_HIRHAM_JJA.tas-273.15,'LineWidth',2);
        [lm{1}, ~] = Plotlm(data_HIRHAM_JJA.time(end-18:end), data_HIRHAM_JJA.tas(end-18:end)-273.15,'Annotation','off');
        % set(ah1,'parent',gca)
        % set(ah1,'position',get(ah1,'position') + [5 2.2 0 0])
        h(2) = plot (year_box,T_Box_JJA,'LineWidth',2);
        [lm{2}, ~] = Plotlm(year_box(end-18:end),T_Box_JJA(end-18:end),'Annotation','off');
        % set(ah2,'parent',gca)
        % set(ah2,'position',get(ah2,'position') + [6 0.7 0 0])
        h(4) = plot(data_JJA.time, data_JJA.AirTemperature2C,'LineWidth',2);
        [lm{4}, ~] = Plotlm(data_JJA.time, data_JJA.AirTemperature2C,'Annotation','off');
        % set(ah3,'parent',gca)
        % set(ah3,'position',get(ah3,'position') + [0 0.2 0 0])
        h(3) = plot(data_MAR_JJA.time, data_MAR_JJA.T,'LineWidth',2);
        [lm{3}, ~] = Plotlm(data_MAR_JJA.time(end-18:end), data_MAR_JJA.T(end-18:end),'Annotation','off');
        % set(ah1,'parent',gca)
        % set(ah1,'position',get(ah1,'position') + [5 2.2 0 0])
        axis tight
        % ylim([-20 0.5]);
        text = {'HIRHAM','RACMO/Box13','MAR',station};
        leg_text=[];
        for i = 1:4
            leg_text{i} = sprintf('%s (slope: %0.2f degC/dec, p-value: %0.2f)',...
                text{i}, lm{i}.Coefficients.Estimate(2)*10, max(lm{i}.Coefficients.pValue));
        end
        legend(h,leg_text,'Location','NorthWest')
        legend boxoff
        xlabel('Date')
        % axis tight
        box on
        xlim([1970 2015])
        set(gca,'YMinorTick','on','XMinorTick','on')
        ylabel('Air Temperature (^{\circ}C)')
        h_title = title(sprintf('JJA Mean %s',station));
        set(h_title,'parent',gca);
        set(h_title,'position',get(h_title,'position') + [0 -1 0 ])
        h = gcf; set(h, 'PaperOrientation','Portrait'); set(h, 'Position',[0.2540    0.1905   31.1150   20.4893])

        print(f,sprintf('./Output/data_overview/Comp_RCM_%s',station),'-dtiff');

    end
end
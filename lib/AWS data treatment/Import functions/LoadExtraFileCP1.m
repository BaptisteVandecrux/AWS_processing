function [data_2] = LoadExtraFileCP1()
T_0 =273.15;
    filename = 'Input\GCnet\Additional files\CP1_extra_1.csv';
    delimiter = ';';
    startRow = 2;
    formatSpec = '%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(fileID);

    data_2 = table(dataArray{4:end-14}, 'VariableNames', ...
    {'Year', 'Day_of_Year',...
    'Hour', 'ShortwaveRadiationDownWm2',...
        'ShortwaveRadiationUpWm2','NetRadiationWm2',...
        'IceTemperature1C',' IceTemperature2C', 'IceTemperature3C',...
        'IceTemperature4C','IceTemperature5C',...
        'IceTemperature6C','IceTemperature7C','IceTemperature8C',...
        'IceTemperature9C', 'IceTemperature10C', ...
        'AirTemperature1C','AirTemperature2C', 'AirTemperature3C', 'AirTemperature4C',...
        'RelativeHumidity1Perc','RelativeHumidity2Perc',...
        'WindSpeed1ms','WindSpeed2ms','WindDirection1deg','WindDirection2deg',...
        'AirPressurehPa', 'ZenithAngle1deg','ZenithAngle2deg',...
        });
    data_2(end,:) = [];

    data_2.JulianTime = data_2.Day_of_Year + data_2.Hour./24;
    clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;

        data_2.time = datenum(data_2.Year,0,data_2.JulianTime);
        time_2 = datevec(data_2.time);
        data_2.HourOfTheDay = time_2(:,4);
        time_2  = time_2(:, 1:3);   % [N x 3] array, no time
        DV2 = time_2;
        DV2(:, 2:3) = 0;    % [N x 3], day before 01.Jan
        data_2.DayOfTheYear = datenum(time_2) - datenum(DV2);
        data_2.ZenithAngledeg = (data_2.ZenithAngle1deg+data_2.ZenithAngle2deg)./2;
        data_2.ZenithAngle1deg=[];
        data_2.ZenithAngle2deg=[];
        data_2.Day_of_Year = [];
        data_2.Hour = [];
        data_2 = standardizeMissing(data_2,{999,-999});
        
        data_2.RelativeHumidity1Perc = RHwater2ice(data_2.RelativeHumidity1Perc ,...
            data_2.AirTemperature3C + T_0, data_2.AirPressurehPa*100);
        data_2.RelativeHumidity2Perc = RHwater2ice(data_2.RelativeHumidity2Perc ,...
            data_2.AirTemperature4C + T_0, data_2.AirPressurehPa*100);

        % corrects anomaly in time stamp
    %     figure
    %     plot(data_2.time)
    %     title('Error in time stamp')
        ind_error =  find(data_2.time<data_2.time(1));
        ind_ok =  find(data_2.time>=data_2.time(1));
        time_diff = data_2.time(2123)- data_2.time(2122) - data_2.time(2122)+ data_2.time(2121) -1.5;
        data_2.time(ind_error)=data_2.time(ind_error)-time_diff;
        [~,ind_uni,~] = unique(data_2.time);
        data_2 = data_2(ind_uni,:);
        temp = datevec(data_2.time);
        data_2.Year = temp(:,1);
        data_2.HourOfTheDay = temp(:,4);
        data_2.MonthOfTheYear = temp(:,2);
        data_2.DayOfTheMonth = temp(:,3);
        data_2.DayOfTheYear = datenum(data_2.Year,data_2.MonthOfTheYear,data_2.DayOfTheMonth) - datenum(data_2.Year,1,1);
        data_2.JulianTime = data_2.DayOfTheYear -1 + data_2.HourOfTheDay./24;

        % scales back data
        data_2.ShortwaveRadiationDownWm2=data_2.ShortwaveRadiationDownWm2*200;
        data_2.ShortwaveRadiationUpWm2 =data_2.ShortwaveRadiationUpWm2*200;
        ind_pos = data_2.NetRadiationWm2>0;
        ind_neg = data_2.NetRadiationWm2<0;
        data_2.NetRadiationWm2(ind_pos) = data_2.NetRadiationWm2(ind_pos).*50./5.35;
        data_2.NetRadiationWm2(ind_neg) = data_2.NetRadiationWm2(ind_neg).*50./4.246;
    % Loading second annexe data file (nothing used in this one)
    % This file did not contain any new data

    % filename = 'Input\CP1_extra_2.csv';
    % delimiter = ';';
    % startRow = 2;
    % formatSpec = '%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
    % fileID = fopen(filename,'r');
    % dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    % fclose(fileID);
    % 
    % data_3 = table(dataArray{4:end-14}, 'VariableNames', ...
    % {'Year', 'Day_of_Year',...
    % 'Hour', 'ShortwaveRadiationDownWm2',...
    %     'ShortwaveRadiationUpWm2','NetRadiationWm2',...
    %     'IceTemperature1C',' IceTemperature2C', 'IceTemperature3C',...
    %     'IceTemperature4C','IceTemperature5C',...
    %     'IceTemperature6C','IceTemperature7C','IceTemperature8C',...
    %     'IceTemperature9C', 'IceTemperature10C', ...
    %     'AirTemperature1C','AirTemperature2C', 'AirTemperature3C', 'AirTemperature4C',...
    %     'RelativeHumidity1Perc','RelativeHumidity2Perc',...
    %     'WindSpeed1ms','WindSpeed2ms','WindDirection1deg','WindDirection2deg',...
    %     'AirPressurehPa', 'ZenithAngle1deg','ZenithAngle2deg',...
    %     });
    % data_3.JulianTime = data_3.Day_of_Year + data_3.Hour./24;
    % clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;
    % 
    %     data_3.time = datenum(data_3.Year,0,data_3.JulianTime);
    %     time_2 = datetime(datestr(data_3.time));
    %     data_3.MonthOfTheYear = time_2.Month;
    %     data_3.DayOfTheMonth = time_2.Day;
    %     data_3.HourOfTheDay = time_2.Hour;
    %     data_3.DayOfTheYear = data_3.JulianTime;
    % 
    %     data_3 = standardizeMissing(data_3,{999,-999});
    %     data_3.RelativeHumidity1Perc = RHwater2ice(data_3.RelativeHumidity1Perc ,...
    %         data_3.AirTemperature3C + T_0, data_3.AirPressurehPa*100);
    %     data_3.RelativeHumidity2Perc = RHwater2ice(data_3.RelativeHumidity2Perc ,...
    %         data_3.AirTemperature4C + T_0, data_3.AirPressurehPa*100);    
    %     
    %     f = figure('Visible',vis);
    %     ha = tight_subplot(6,1,0.01, [.07 .03], 0.05);
    %     count = 1;
    %     for i = 4:27
    %         if count <= 6
    %             axes(ha(count))
    %         else
    %             datetick('x','yyyy','keeplimits','keepticks')
    %             legend('extra','old')
    %             print(f,sprintf('fig_2_%i',i),'-dpdf')
    %             f = figure;
    %             ha = tight_subplot(6,1,0.01, [.07 .03], 0.05);
    %             count = 1;
    %             axes(ha(count))
    %         end
    % 
    %         hold on
    %         scatter(data_3.time,table2array(data_3(:,i)))
    %         plot(data.time,data.(data_3.Properties.VariableNames{i}))
    %         axis tight
    %         set(gca,'XMinorTick','on')
    %         if count == 6
    %             set(gca,'XTickLabel',[])
    %         end
    %         if count/2 ==floor(count/2)
    %             set(gca,'YAxisLocation','right')
    %         end
    %         ylabel(data_3.Properties.VariableNames{i})
    %         set_monthly_tick(time_2);
    %         xlim([data_3.time(1) data_3.time(end)])
    %         count = count +1;
    %     end
    %     datetick('x','yyyy','keeplimits','keepticks')
    %     legend('extra','old')
    %             print(f,sprintf('fig_2_%i',i),'-dpdf')
end
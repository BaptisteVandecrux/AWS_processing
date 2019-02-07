
function [data] = SetErrorDatatoNAN(data, station,vis)
% read error_data_log from station and set data between time1 and time2 to NAN

     [~,sheet_list] =xlsfinfo('.\Input\ErrorData_AllStations.xlsx');
     if ~ismember(station,sheet_list)
         disp('No error data file found for this station')
         return
     end
     
    [~, ~, raw] = xlsread('.\Input\ErrorData_AllStations.xlsx',station);
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
    cellVectors = raw(:,[1,2,3]);

    variable_name = cellVectors(:,1);
    date1 = cellVectors(:,2);
    date2 = cellVectors(:,3);

    clearvars raw cellVectors;
    
    %plotting before removal
    var_name_uni = unique(variable_name);
    f = figure('Visible',vis);
    ha = tight_subplot(length(var_name_uni),1,0.02, [0.05 0.02],[0.07 0.25]);
    for i = 1:length(var_name_uni)
        if ~ismember(var_name_uni{i},data.Properties.VariableNames)
            continue
        end
            set(f,'CurrentAxes',ha(i)) 

        if ~isempty(strfind(var_name_uni{i},'Relat'))
            T = nanmean([data.AirTemperature1C, data.AirTemperature3C],2);
            temp = RHice2water(data.(var_name_uni{i}),T+273.15,data.AirPressurehPa);
            plot(data.time,temp,'Color',RGB('red'))
        else
            plot(data.time,data.(var_name_uni{i}),'Color',RGB('red'))
        end
        hold on
        if i == 1
            h_tit = title(station);
            h_tit.Units = 'normalized';
            h_tit.Position(2) = h_tit.Position(2)-0.5;
        end
        set_monthly_tick(data.time)
    end
    
    % for length of csv file: set variables given in the first column (weather_name)
    % in the time interval [date1, date2] to NaN
    for i = 1:length(variable_name)
        if ~ismember(variable_name{i},data.Properties.VariableNames)
            continue
        end
        try 
            ind1 = dsearchn(data.time,datenum(date1{i},'dd-mm-yyyy HH:MM:SS'));
            ind2 = dsearchn(data.time,datenum(date2{i},'dd-mm-yyyy HH:MM:SS'));
        catch me
            ind1 = dsearchn(data.time,datenum(date1{i},'dd-mmm-yyyy'));
            ind2 = dsearchn(data.time,datenum(date2{i},'dd-mmm-yyyy'));
        end
        %update Baptiste
         data.(variable_name{i})(ind1:ind2) = NaN;
    end
    
    %plotting after removal
    for i = 1:length(var_name_uni)
        if ~ismember(var_name_uni{i},data.Properties.VariableNames)
            continue
        end
        set(f,'CurrentAxes',ha(i)) 
        if ~isempty(strfind(var_name_uni{i},'Relat'))
            T = nanmean([data.AirTemperature1C, data.AirTemperature3C],2);
            temp = RHice2water(data.(var_name_uni{i}),T+273.15,data.AirPressurehPa);
            plot(data.time,temp,'Color',RGB('dark blue'))
        else
            plot(data.time,data.(var_name_uni{i}),'Color',RGB('dark blue'))
        end
        datetick('x','yyyy-mm')
        xlabel('')
        if i~=length(var_name_uni)
            set(gca,'XTickLabel','');
        end
        ylabel('')
        h_leg = legend('Erroneous data',sprintf('%s',var_name_uni{i}),'Location','NorthWest');
        h_leg.Position(1) = h_leg.Position(1) +  0.69;

        axis tight
        set_monthly_tick(data.time)
        xlim(data.time([1 end]))
        if i <length(var_name_uni)
            set(gca,'XTickLabel','')
        end
    end
    set(gca,'XTickLabelRotation',0)
    try 
        print(f,sprintf('./Output/%s/ErroneousData',station),'-dpng')
    catch me
        print(f,sprintf('./Output/ErroneousData_%s',station),'-dpng')
    end
          
end
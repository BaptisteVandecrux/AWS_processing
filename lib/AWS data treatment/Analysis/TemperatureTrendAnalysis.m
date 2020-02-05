function [summary_table] = TemperatureTrendAnalysis(station_list, data_in, vis)
avg_temp = {};
m = [];
var_name = {};
station2 = station_list;
for i =1:length(station_list)
    station2{i} = strrep(station_list{i},'-','');
    station2{i} = strrep(station2{i},' ','');
end
f=figure;
ha=tight_subplot(3,3,[0.05 0.01],[0.1 0.05],0.05);
for ii = 1:length(station_list)
        station = station2{ii};

        OutputFolder = sprintf('./Output/data_overview/');
        data = data_in{ii};

        %% Temperature

        temp = datevec(data.time);
        ind_JJA = ismember(temp(:,2),[6 7 8]);
        data_JJA = data(ind_JJA, ...
            [find(strcmp(data.Properties.VariableNames,'time')) ...  
            find(strcmp(data.Properties.VariableNames,'AirTemperature2C'))]);

        ind_DJF = ismember(temp(:,2),[12 1 2]);
        data_DJF = data(ind_DJF, ...
            [find(strcmp(data.Properties.VariableNames,'time')) ...  
            find(strcmp(data.Properties.VariableNames,'AirTemperature2C'))]);

        ind_SON = ismember(temp(:,2),[9 10 11]);
        data_SON = data(ind_SON, ...
            [find(strcmp(data.Properties.VariableNames,'time')) ...     
            find(strcmp(data.Properties.VariableNames,'AirTemperature2C'))]);

        ind_MAM = ismember(temp(:,2),[3 4 5]);
        data_MAM = data(ind_MAM,...
            [find(strcmp(data.Properties.VariableNames,'time')) ...
            find(strcmp(data.Properties.VariableNames,'AirTemperature2C'))]);

        avg_temp{5} = AvgTable(data(:, ...
        [find(strcmp(data.Properties.VariableNames,'time')) ...  
        find(strcmp(data.Properties.VariableNames,'AirTemperature2C'))]),...
        'yearly','mean',50);
        avg_temp{1} = AvgTable(data_DJF,'water-yearly','mean',50);
        avg_temp{2} = AvgTable(data_JJA,'yearly2','mean',50);
        avg_temp{3} = AvgTable(data_MAM,'yearly','mean',50);
        avg_temp{4} = AvgTable(data_SON,'yearly','mean',50);

        years = datevec(avg_temp{5}.time);
        years = years(:,1) ;    
        avg_temp{5}.time = years;
        
        for i = 1:4
            temp = datevec(avg_temp{i}.time);
            avg_temp{i}.time = temp(:,1);
        end

        % Delete first or last year, if data coverage is not sufficient
        % ANNUAL
        if data.DayOfYear(1) > 15
            avg_temp{5}.AirTemperature2C(1) = NaN;
        end
        if data.DayOfYear(end) <= 349
            avg_temp{5}.AirTemperature2C(end) = NaN;
        end
        % DJF : delete first year, if year starts in Jan/Feb or starts later
        % than Dec 2nd
        if data.DayOfYear(1) < 60 || data.DayOfYear(1)> 365-29
            avg_temp{1}.AirTemperature2C(1) = NaN;
        end
        % delete last year, if 
        if data.MonthOfYear(end) < 3 || data.MonthOfYear(end) == 12
            avg_temp{1}.AirTemperature2C(end) = NaN;
        end    
        % MMA [3 4 5]
        if data.MonthOfYear(1) > 3
            avg_temp{3}.AirTemperature2C(1) = NaN;
        end
        if data.MonthOfYear(end) < 5
            avg_temp{3}.AirTemperature2C(end) = NaN;
        end    
        % JJA [6 7 8]
        if data.MonthOfYear(1) > 6
            avg_temp{2}.AirTemperature2C(1) = NaN;
        end
%         if data.MonthOfYear(end) < 8
%             avg_temp{2}.AirTemperature2C(end) = NaN;
%         end    
        % SON [9 10 11]
        if data.MonthOfYear(1) > 9
            avg_temp{4}.AirTemperature2C(1) = NaN;
        end
        if data.MonthOfYear(end) < 11
            avg_temp{4}.AirTemperature2C(end) = NaN;
        end    

        p_thres =1;

        %% plotting 
%         f = figure('Visible',vis);
set(f,'CurrentAxes',ha(ii))

        hold on
        color = parula(5);
        scatter(years, avg_temp{5}.AirTemperature2C,80,'x','LineWidth',2,'MarkerEdgeColor',color(1,:))
        scatter(avg_temp{1}.time, avg_temp{1}.AirTemperature2C,80,'o','LineWidth',2,'MarkerEdgeColor',color(2,:))
        scatter(avg_temp{3}.time, avg_temp{3}.AirTemperature2C,80,'d','LineWidth',2,'MarkerEdgeColor',color(3,:))
        scatter(avg_temp{2}.time, avg_temp{2}.AirTemperature2C,80,'^','LineWidth',2,'MarkerEdgeColor',color(4,:))
        scatter(avg_temp{4}.time, avg_temp{4}.AirTemperature2C,80,'v','LineWidth',2,'MarkerEdgeColor',color(5,:))

        p_value = 1:5;
        slope = 1:5;
                p = {};
count=1;
        for i =[2 5]
            p{i} = fitlm(avg_temp{i});
            slope(i) = p{i}.Coefficients.Estimate(2);
            p_value(i) = max(p{i}.Coefficients.pValue);
%             if p_value(i) < p_thres
                h(count) = plot(years, p{i}.Coefficients.Estimate(1) + p{i}.Coefficients.Estimate(2).*years,'Color', color(i,:),'LineWidth',2.5);
                legtext{count} = sprintf('slope: %+0.2f ^oC dec^{-1} (P=%0.2f)',...
                     p{i}.Coefficients.Estimate(2)*10,p_value(i));
%             end
count = count+1;
        end
       
%         set(gca,'Position',get(gca,'Position')-[0 -0.14 0 0.25])
        legendflex(h, legtext, 'ref', gca, ...
            'anchor', {'n','n'}, ...
            'buffer',[10 -10], ...
            'ncol',1, ...
            'fontsize',10,...
            'Interpreter','tex');
        axis tight
        box on
        set(gca,'XTick',years(1):years(end),'YMinorTick','on','Box','on')
        xticklab = get(gca,'XTickLabel');
        for i = 2:2:length(xticklab)
            xticklab{i} = '';
        end
        set(gca,'XTickLabel',xticklab,'XTickLabelRotation',30);
    ylim([-40 20])
    if ismember(ii,[2 3 5 6 8 9])
        set(gca,'YTickLabel','')
    end
    if ismember(ii,1:6)
        set(gca,'XTickLabel','')
    end
    if ii==4
        ylabel('Mean air temperature (^{\circ}C)','Interpreter','tex')
    else
        if ii == 8
        xlabel('Years')
        end
    end
        if strcmp(station,'CP1')
            station_2 = 'Crawford Point';
        else
            station_2 = station;
        end
        title(station_2); 
%         set(gcf, 'PaperOrientation','Portrait');
        
        m = [m, [[nanmean(avg_temp{1}.AirTemperature2C); ...
            nanmean(avg_temp{2}.AirTemperature2C);...
            nanmean(avg_temp{3}.AirTemperature2C);...
            nanmean(avg_temp{4}.AirTemperature2C);...
            nanmean(avg_temp{5}.AirTemperature2C)],...
            10.*slope', p_value']];
        var_name = {var_name{:}, [station '_m'], [station '_s'], [station '_p']};
    end
             print(f,sprintf('%s/AirTemp_all',OutputFolder),'-dtiff')

    summary_table =  array2table(m,'VariableNames',var_name,...
        'RowNames',{'DJF','MAM','JJA','SON','year'});
    
    writetable2csv(summary_table,'./Output/data_overview/T_summary.csv');
    
end
         





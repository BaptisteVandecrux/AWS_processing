
function [] = PlotWeatherBox (data,plotname, vis)
   set(0,'DefaultAxesFontSize',10)

time_2 = datetime(datestr(data.time));

f = figure('Visible',vis);
VarList = {'ShortwaveRadiationDownWm2','ShortwaveRadiationUpWm2',...
    'AirTemperatureC','RelativeHumidity','AirPressurehPa',...
    'WindSpeedms','LongwaveRadiationDownWm2','Albedo'};
YLabels = {'       SW Rad. Down (W/m^2)','SW Rad.  Up (W/m^2)',...
    'Air Temp. (^{\circ}C)','Rel. Hum. (%)','Air Pres.(hPa)',...
    'Wind Speed (m/s)','LW Rad.Down (W/m^2)','Albedo'};
num_plot = 4;

ha = tight_subplot(num_plot,2,0.03, [.07 .03], 0.07);

count = 1;
Years = unique(time_2.Year)-min(time_2.Year)+1;

for i = 1:size(data,2)
    if sum(strcmp(data.Properties.VariableNames{i},VarList))>0
        if count <= num_plot*2
            set(f,'CurrentAxes',ha(count))
        else
            set(gca,'XTickLabel',Years+min(time_2.Year) - 1)
            xlabel('Year')
            i_file = 1;
                NameFile = sprintf('%s_%i.tif',plotname,i_file)  ;
            while exist(NameFile, 'file') == 2
                i_file = i_file + 1;
                NameFile = sprintf('%s_%i.tif',plotname,i_file)  ;
            end
            print(f,NameFile,'-dtiff');
            f = figure('Visible',vis);
            ha = tight_subplot(num_plot,2,0.03, [.07 .03], 0.07);
            count = 1;
            set(f,'CurrentAxes',ha(count))
        end
        
        hold on
        
        boxplot(data.(data.Properties.VariableNames{i}),time_2.Year)
        mean_year = NaN(size(Years));
        std_year = NaN(size(Years));
        max_year = NaN(size(Years));
%         perc75_year = NaN(size(Years));
        for j = 1:length(Years)
            ind = (time_2.Year == Years(j)+min(time_2.Year)-1);
            mean_year(j) = nanmean(data.(data.Properties.VariableNames{i})(ind));
            std_year(j) = nanstd(data.(data.Properties.VariableNames{i})(ind));
            max_year(j) = max(data.(data.Properties.VariableNames{i})(ind));
            perc75_year(j) = prctile(data.(data.Properties.VariableNames{i})(ind),75);
        end
        
        tbl=table(Years,mean_year,'VariableNames',{'years',sprintf('%s_mean',data.Properties.VariableNames{i})});    
        p_mean = fitlm(tbl);
        tbl=table(Years,max_year,'VariableNames',{'years',sprintf('%s_max',data.Properties.VariableNames{i})});    
        p_max = fitlm(tbl);
        tbl=table(Years,perc75_year','VariableNames',{'years',sprintf('%s_75',data.Properties.VariableNames{i})});    
        p_75 = fitlm(tbl);
        
        p_value_1 = max(p_mean.Coefficients.pValue);
        if p_value_1 < 0.1
            plot(Years, p_mean.Coefficients.Estimate(1) + p_mean.Coefficients.Estimate(2).*Years)
%             legend(sprintf('Trend in mean value. Slope: %0.3f',p_mean.Coefficients.Estimate(2)))
        end
        
        p_value_2 = max(p_max.Coefficients.pValue);
        if p_value_2 < 0.1
            plot(Years, p_max.Coefficients.Estimate(1) + p_max.Coefficients.Estimate(2).*Years,'--')
%             legend(sprintf('Trend in max value. Slope: %0.3f',p_max.Coefficients.Estimate(2)))
        end

        p_value_3 = max(p_75.Coefficients.pValue);
        if p_value_3 < 0.1
            plot(Years, p_75.Coefficients.Estimate(1) + p_75.Coefficients.Estimate(2).*Years,'--')
%             legend(sprintf('Trend in 75 percentil value. Slope: %0.3f',p_75.Coefficients.Estimate(2)))
        end
        
        if ((p_value_1 < 0.1) && (p_value_2 < 0.1)) && (p_value_3 < 0.1)
%             legend(sprintf('Trend in mean value. Slope: %0.3f',p_mean.Coefficients.Estimate(2)),...
%             	sprintf('Trend in max value. Slope: %0.3f',p_max.Coefficients.Estimate(2)),...
%             	sprintf('Trend in 75 percentil value. Slope: %0.3f',p_max.Coefficients.Estimate(2)))
        end
%         axis tight
        set(gca,'XMinorTick','on','XTickLabel',[])

        if count/2 ==floor(count/2)
            set(gca,'YAxisLocation','right')
        end
%         YTicks = get(gca,'YTickLabel');
%         set(gca,'YTickLabel','');
%         ratio = get(gca,'PlotBoxAspectRatio');
%         set(gca,'YTickLabel',YTicks);
        ind_var = find(strcmp(data.Properties.VariableNames{i}, VarList));
        ylabel(YLabels{ind_var},'Interpreter','tex')
%         ratio2 = get(gca,'PlotBoxAspectRatio');

%         set(gca,'PlotBoxAspectRatio',ratio2)

        if ismember(count , 7:8)
            for kk =1:length(Years)
                if kk/2==floor(kk/2)
                    temp{kk} = '';
                else
                    temp{kk} = num2str(Years(kk)+min(time_2.Year) - 1);
                end
            end
            set(gca,'XTickLabel',temp);
            xlabel('Year')
        end
        count = count +1;
    end
end
    i_file = 1;
                NameFile = sprintf('%s_%i.tif',plotname,i_file)  ;
    while exist(NameFile, 'file') == 2
        i_file = i_file + 1;
                NameFile = sprintf('%s_%i.tif',plotname,i_file)  ;
    end
    h = gcf; set(h, 'PaperOrientation','Portrait');
    print(f,NameFile,'-dtiff'); 
    end
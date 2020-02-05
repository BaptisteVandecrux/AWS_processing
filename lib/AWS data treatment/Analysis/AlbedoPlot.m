function AlbedoPlot(station_list,data_in, vis)
    % Albedo
    set(0,'DefaultAxesFontSize',15)

    years_all = datenum(1998:2018,1,1);
        if length(data_in) > 5
            f = figure('Visible',vis);
            ha = tight_subplot(round(length(data_in)/2),2,[0.03 0.03],[0.1 0.06],0.06);
        else
            f = figure('Visible',vis);
            ha = tight_subplot(5,1,0.03,[0.1 0.06],0.06);
        end
        
        for ii = 1:length(data_in)
            station = station_list{ii};
            data = data_in{ii};

            temp = datevec(data.time);
            ind_JJA = ismember(temp(:,2),[6 7 8]);
            data_JJA = data(ind_JJA,...
                [1 2 3 ...
                find(strcmp(data.Properties.VariableNames,'time')) ...
                find(strcmp(data.Properties.VariableNames,'Albedo'))]);
            if data_JJA.MonthOfYear(1) > 6
                data_JJA(data_JJA.Year == data_JJA.Year(1),:) = [];
            end
        %     if data_JJA.MonthOfYear(end) < 8
        %         ind = find(data_JJA.Year == data_JJA.Year(end));        
        %         data_JJA(end,:) = [];
        %     end
            data_JJA = data_JJA(:,[4 5]);

            avg_alb_JJA = AvgTable(data_JJA,'yearly2','nanmean');
            avg_alb_daily = AvgTable(data_JJA,'daily','nanmean');
            avg_alb_daily.Albedo(avg_alb_daily .Albedo==0) = NaN;
            first_ind = find(ismember(years_all,avg_alb_JJA.time),1,'first');
            for jj = first_ind-1:-1:1
                avg_alb_JJA = ...
                    [array2table([years_all(jj) NaN],...
                    'VariableName',{'time','Albedo'});...
                    avg_alb_JJA];
            end
            last_ind = find(ismember(years_all,avg_alb_JJA.time),1,'last');
            for jj = last_ind+1:length(years_all)
                avg_alb_JJA = ...
                    [avg_alb_JJA;
                    array2table([years_all(jj) NaN],...
                    'VariableName',{'time','Albedo'})];
            end

            temp = datevec(avg_alb_JJA.time);
            years = temp(:,1);

    %         p_JJA = fitlm(avg_alb_JJA);
            p_thres = 0.1;
            p = fitlm(avg_alb_JJA.time,avg_alb_JJA.Albedo);
            fprintf('%s\t%0.03f\t%0.02f\t%0.02f\t%0.02f\n',station_list{ii},...
                p.Coefficients.Estimate(2)*365*10,...
                max(p.Coefficients.pValue),...
                avg_alb_JJA.Albedo(avg_alb_JJA.time==datenum(2012,1,1)),...
                nanmean(avg_alb_JJA.Albedo));
            
            p_value = max(p.Coefficients.pValue);

            set(f,'CurrentAxes',ha(ii))
            plot(avg_alb_daily.time,avg_alb_daily.Albedo)
            hold on
            time_plot = repelem(avg_alb_JJA.time+30.5*5,3);
            time_plot(2:3:end)=time_plot(1:3:end)+30*3;
            time_plot(3:3:end)=time_plot(1:3:end)+30*3+1;
            y = repelem(avg_alb_JJA.Albedo,3);
            y(3:3:end)=NaN;

            plot(time_plot, y,'r','LineWidth',3)
            legtext_alb = {'Daily average','JJA average'};

            if p_value < p_thres
                plot(avg_alb_daily.time, p.Coefficients.Estimate(1) + p.Coefficients.Estimate(2).*avg_alb_daily.time,'--k')
                legtext_alb{3} = 'significant slope in JJA average';
            end
            if ii == 1
                legendflex(legtext_alb, 'ref', gca, ...
                    'anchor', {'n','n'}, ...
                    'buffer',[300 30], ...
                    'nrow',1, ...
                    'fontsize',13,...
                    'box','off');
            end
            set_monthly_tick(avg_alb_JJA.time);
            if ~ismember(ii, [length(data_in) length(data_in)-1])
                set(gca,'XTickLabel',' ')
            else
                set(gca,'XTickLabelRotation',0);
                xlabel('Time')
            end
            if floor(ii/2) == ii/2
                set(gca,'YAxisLocation','right');
            end

            if or(ii == round(length(data_in)/2),ii == round(length(data_in)/2)+1)
                h_ylabel = ylabel('Albedo (unitless)');
            end
            axis tight
            if strcmp(station_list{ii},'CP1')
                station_2 = 'Crawford Point';
            else
                station_2 = station_list{ii};
            end
            if ii/2 == round(ii/2)
                set(gca,'YAxisLocation','right')
            end
            h_title = title(sprintf('%s) %s', char(ii+96), station_2));
            h_title.Units = 'Normalized';
            h_title.Position = [0.5 0.08 0];
            h_title.FontSize = 12;
            ylim([0.7 0.9])
            xlim([years_all(1) years_all(end)])
        %     xlim(datenum([1994 2018],1,1))
        end
        while ii+1<=length(ha)
            set(ha(ii+1),'Visible','off')
            ii = ii+1;
        end
            
           set(gcf, 'PaperOrientation','landscape');
        print(f,sprintf('./Output/data_overview/Albedo_all'),'-dtiff')
    %     print(f,sprintf('./Output/Albedo_all'),'-dpdf','-r0')
end
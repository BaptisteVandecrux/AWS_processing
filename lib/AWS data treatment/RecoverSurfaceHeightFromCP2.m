function [data] = RecoverSurfaceHeightFromCP2(data,data_CP2,OutputFolder,vis)
    % first the height record from CP2 needs to be corrected for
    % maintenance
    [data_CP2] = AdjustHeight(data_CP2,'CP2',OutputFolder,vis);
      
    % then the CP2 is located in a depression that with slightly different
    % accumulation rate than CP1, so we need to correct the CP2 height
    % record before it is used at CP1
    ind_common = ismember(data.time, data_CP2.time);
    data_new = data(ind_common,:);
    ind_common = ismember(data_CP2.time, data.time);
    data_CP2 = data_CP2(ind_common,:);
    
    ind_start = find (data.time == data_CP2.time(1));
    ind_end = find (data.time == data_CP2.time(end));
    if isempty(ind_end)
        ind_end = length(data_CP2.time);
    end
    
    %     temp = datetime(datestr(data_aux.time));
    %     data_aux.SnowHeight1m(ismember(temp.Month,4:8)) = NaN;
    %     data_aux.SnowHeight2m(ismember(temp.Month,4:8)) = NaN;
    %     figure
    %     subplot(2,1,1)
    %     plot(data_new.time,data_new.SnowHeight1m)
    %     hold on
    %     plot(data_aux.time,-data_aux.WindSensorHeight1m)
    %     subplot(2,1,2)
    %     plot(data_new.time,data_new.SnowHeight2m)
    %     hold on
    %     plot(data_aux.time,-data_aux.WindSensorHeight2m)

    time = data_new.time(18856:end);       
    y1 = data_new.SnowHeight1m(18856:end)-data_new.SnowHeight1m(18856);
    y2 = data_CP2.SnowHeight1m(18856:end)-data_CP2.SnowHeight1m(18856);
    myfit1 = fit(time(~isnan(y1)),y1(~isnan(y1)),'poly1');
    myfit2 = fit(time(~isnan(y2)),y2(~isnan(y2)),'poly1');

    acc_rate_CP1 = myfit1.p1;
    acc_rate_CP2 = myfit2.p1;

    y3 = y2 - myfit2(time) + myfit1(time);

            f = figure('Visible',vis);
            ha = tight_subplot(4,1,0.07, [0.1 0.05], 0.1); 
            set(f,'CurrentAxes',ha(1))
                plot(time,y1,'r')
                hold on
                plot(time,myfit1(time),'r')
                plot(time,y2,'b')
                plot(time,myfit2(time),'b')
                plot (time,y3,'k')
                axis tight
                set_monthly_tick(time); 
                box on
                legendflex({'obs. at CP1','linear fit at CP1',...
                    'obs. at CP2','linear fit at CP2','obs. from CP2 adj. for CP1'},...
                    'ref', gcf, ...
                       'anchor', {'n','n'}, ...
                       'buffer',[0 6], ...
                       'nrow',1, ...
                       'box','off',...
                       'fontsize',12);
                datetick('x','mmm-yy','keeplimits','keepticks')    
                set(gca,'XTickLabelRotation',0)      
%                 ylabel('Snow height\newline (m)','Interpreter','tex')

            set(f,'CurrentAxes',ha(2))
                plot(data_CP2.time,data_CP2.SnowHeight1m)
                hold on
                plot(data_CP2.time,...
                    data_CP2.SnowHeight1m ...
                    + (acc_rate_CP1- acc_rate_CP2)/24*[0:length(data_CP2.time)-1]')                  
                axis tight
                set_monthly_tick(data.time); 
                box on
                h_leg = legend('CP2 before adj.','CP2 after adj.',...
                    'Location','NorthWest');
                h_leg.FontSize = 12;
                datetick('x','yyyy','keeplimits','keepticks')            
                ylabel('Snow height (m)\newline  ','Interpreter','tex')
                set(gca,'XTickLabelRotation',0)      

    data_CP2.SnowHeight1m = data_CP2.SnowHeight1m ...
                    + (acc_rate_CP1- acc_rate_CP2)/24*[0:length(data_CP2.time)-1]';
    data_CP2.SnowHeight2m = data_CP2.SnowHeight2m ...
                    + (acc_rate_CP1- acc_rate_CP2)/24*[0:length(data_CP2.time)-1]';

            set(f,'CurrentAxes',ha(3))
  
    ind_adj = find(~isnan(data_new.SnowHeight1m + data_CP2.SnowHeight1m),1,'first');
    data_CP2.SnowHeight1m = data_CP2.SnowHeight1m - data_CP2.SnowHeight1m(ind_adj) + data_new.SnowHeight1m(ind_adj);
  
    ind_adj = find(~isnan(data_new.SnowHeight2m + data_CP2.SnowHeight2m),1,'first');
    data_CP2.SnowHeight2m = data_CP2.SnowHeight2m - data_CP2.SnowHeight2m(ind_adj) + data_new.SnowHeight1m(ind_adj);

      ind_nan = isnan(data_new.SnowHeight1m);
    data_aux_new = data_CP2;
    data_aux_new.SnowHeight1m(~ind_nan) = NaN;
    
                plot(data_new.time, data_new.SnowHeight1m)
                hold on
                plot(data_CP2.time(ind_nan),  data_CP2.SnowHeight1m(ind_nan) )         
                set_monthly_tick(data.time); 
                legend('CP1', 'CP2') %,'raw surface height')
                h_leg = legend('CP1', 'CP2',...
                    'Location','NorthWest');
                h_leg.FontSize = 12;
                datetick('x','yyyy','keeplimits','keepticks')            
                xlim([max(data_CP2.time(1),data.time(1)) min(data_CP2.time(end),data.time(end))]);
                box on
                ylim([-1 3])
                set(gca,'XTickLabelRotation',0)      

    data_new.SnowHeight1m(ind_nan) = data_aux_new.SnowHeight1m(ind_nan);
    data.SnowHeight1m(ind_start:ind_end) = data_new.SnowHeight1m;

                %snow height 2
            set(f,'CurrentAxes',ha(4))
    ind_nan = isnan(data_new.SnowHeight2m);
    data_aux_new = data_CP2;
    data_aux_new.SnowHeight2m(~ind_nan) = NaN;

                plot(data_new.time, data_new.SnowHeight2m)
                hold on
                plot(data_aux_new.time, data_aux_new.SnowHeight2m)         
                set_monthly_tick(data.time); 
                legend('CP1', 'CP2') %,'raw surface height')
                set(gca,'XTickLabel',[])
                xlim([max(data_CP2.time(1),data.time(1)) min(data_CP2.time(end),data.time(end))]);
                box on
                ylim([-1 3])
                set(gca,'XTickLabelRotation',0)      
                h_leg = legend('CP1', 'CP2',...
                    'Location','NorthWest');
                h_leg.FontSize = 12;
                datetick('x','yyyy','keeplimits','keepticks')            
                xlabel('Date')
                print(f, sprintf('%s/RecoverHeightFromCP2',OutputFolder), '-dpng')

    data_new.SnowHeight2m(ind_nan) = data_aux_new.SnowHeight2m(ind_nan);
    data.SnowHeight2m(ind_start:ind_end,:) = data_new.SnowHeight2m;
end

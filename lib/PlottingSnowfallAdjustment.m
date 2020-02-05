function [] = PlottingSnowfallAdjustment(Surface_Height, pit_data, ...
    bias_uncor, RMSE_uncor, bias_cor, RMSE_cor,...
    corr_fact,time_mod,  c)
    
    pit_data(isnan(pit_data.SWE_cor),:) = [];

    col = linspecer(size(pit_data,1),'qualitative');
    f = figure('Visible',c.vis);%,'Position',[-2000 100 1800 700]);
    ha = tight_subplot(1,3,0.02,0.05,0.07);
leg_text={};
    set(f,'CurrentAxes',ha(1))
        hold on
        h = [];
        for i=1:size(pit_data,1)
            h(i) = scatter(pit_data.SWE_uncor(i), pit_data.SWE_pit(i), ...
                90,'filled','MarkerFaceColor',col(i,:));
            temp =pit_data.Date(i,:);
            leg_text{i} = temp((length(temp)-3):length(temp));
        end
        axis tight square
        ymax =get(gca,'YLim');
        plot([0 ymax(2)],[0 ymax(2)],'k')
        box on
        set(gca,'XMinorTick','on','YMinorTick','on');
        if ~isempty(leg_text)
            legendflex(h,leg_text,'anchor',{'n','n'},'box','off','buffer',[650 0],'nrow',3)
        end
        hx = xlabel('SWE from station (mm weq)');
        hx.Position = hx.Position + [320 0 0];

        ylabel('SWE from snow pit (mm weq)')
        title(sprintf('before correction \nME: %0.2f  RMSE: %0.2f', bias_uncor, RMSE_uncor))
        
    set(f,'CurrentAxes',ha(2))
        hold on
        for i=1:size(pit_data,1)
            scatter(pit_data.SWE_cor(i),pit_data.SWE_pit(i),90,'filled','MarkerFaceColor',col(i,:))
        end
        plot([0 ymax(2)],[0 ymax(2)],'k')
        axis tight square
        box on
        set(gca,'XMinorTick','on','YMinorTick','on','YTickLabel','');
        title(sprintf('after correction (factor: %0.2f) \nME: %0.2f  RMSE: %0.2f',...
            corr_fact, bias_cor, RMSE_cor))
    
    set(f,'CurrentAxes',ha(3))
        hold on
        plot(time_mod,Surface_Height,'LineWidth',2)
        for i=1:size(pit_data,1)
            if ~isnan(pit_data.SWE_cor(i))
                scatter([time_mod(pit_data.ind_start(i)) time_mod(pit_data.ind_end(i))],...
                    [Surface_Height(pit_data.ind_start(i)) Surface_Height(pit_data.ind_end(i))],90,'filled','MarkerFaceColor',col(i,:))
            end
        end
        
        h_title = title(c.station);
        set(h_title,'Units','Normalized')
        h_title.Position = [-0.6 1.3 0];
        box on
        datetick('x','mm-yyyy')
        axis tight square
        set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','right');
        xlabel('Date');
        ylabel('Surface Height (m)')
        
    if (c.verbose==0)
        close(f);
    else
         print(f, sprintf('%s/precipitation',c.OutputFolder), '-dtiff')
    end
end
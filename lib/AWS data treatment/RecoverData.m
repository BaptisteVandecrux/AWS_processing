function [data,R2_PW_cor, RMSE_PW_cor, ME_PW_cor] = RecoverData(Name, data, VarName1,...
    data2, VarName2, vis, PlotGapFill, OutputFolder)
% This function actually adjusts data_aux after adjustement as follows:
%      data_aux_scaled = (data_aux - mean(data_aux)) / var(data_aux) * var(data) + mean(data)
% and then use data_aux_scaled to fill the gaps in data.
% The filled data is sent to output.

% Defining the codes given to data taken from secondary stations
switch Name
    case 'CP2'
        ind_sec_station =  1;
    case 'SC'
        ind_sec_station =  2;
    case 'KANU'
        ind_sec_station =  3;
    case {'HIRHAM','MAR','RACMO','CanESM_hist','CanESM_rcp26','CanESM_rcp45','CanESM_rcp85'}
        ind_sec_station =  4;  
    case 'last_year'
    ind_sec_station =  6; 
    case 'KANUbabis'
    ind_sec_station =  7;  
    case 'KOB'
    ind_sec_station =  8;  
    case 'NOAA'
    ind_sec_station =  9;  
    case 'Miller'
    ind_sec_station =  10;  

    % 5 is left for modis
end

    ind_common = and(data.time<=data2.time(end)+0.0001,...
        data.time>=data2.time(1)-0.0001);
    data1 = data(ind_common,:);
    
    ind_common = and(data2.time<=data.time(end)+0.0001,data2.time>=data.time(1)-0.0001);
    data3 = data2(ind_common,:);  
    if size(data1,1) == size(data3,1)
        data3.time = data1.time;
    else
        error(sprintf('Missing time steps in %%s',Name))
    end

       
if sum(~isnan(data.(VarName1))) == 0
    % if there's only nan then we use data2 as it is
       data_out = data1;
        ind_common = find(ismember(data.time, data3.time));
        origin_field_name = sprintf('%s_Origin',VarName1);
        if ismember(origin_field_name,data.Properties.VariableNames)
            ind_changed = and(isnan(data_out.(VarName1)),~isnan(data3.(VarName2)));
            data.(origin_field_name)(ind_common(ind_changed)) = ind_sec_station;
        end

        data_out.(VarName1)(isnan(data_out.(VarName1))) = ...
            data3.(VarName2)(isnan(data_out.(VarName1)));
        data.(VarName1)(ind_common) = data_out.(VarName1);
        
    R2_PW_cor = NaN;
    RMSE_PW_cor = NaN;
    ME_PW_cor = NaN;
else

    if sum(strcmp(data3.Properties.VariableNames,VarName2))==0
        disp(VarName2)
        disp(Name)        
        error('Wrong variable name for gap filling')
    end
    
    x = data1.(VarName1);
    y = data3.(VarName2);

    if ~contains(Name,'CanESM')
        % double check regarding thhe synchronization of the two time series
        x_scaled = (x - nanmean(x)) / nanstd(x);
        x_scaled(isnan(x)) = 0;
        y_scaled = (y - nanmean(y)) / nanstd(y);
        y_scaled(isnan(y)) = 0;
        [acor, lag] = xcorr(x_scaled,y_scaled,18);
        if find(lag(acor==max(acor))) ~= 0
            disp('========== lag detected ===========')
            shift = lag(acor==max(acor));
            disp(shift)

            if shift >0
                data3.(VarName2)(shift+1:end) = data3.(VarName2)(1:end-shift);
            else
                data3.(VarName2)(1:end+shift) = data3.(VarName2)(-shift+1:end);
            end
        end

        x = data1.(VarName1);
        y = data3.(VarName2);
    end

    %% setting up neural network

    % the inputs are y, variable at the secondary station, t, the date 
    % (to incorporate changing relationships over time) and doy the day of year
    % (to include the seasonal change of relationship between main and
    % secondary stations).

    % t = data1.time;
    % temp = datetime(datestr(t));
    % doy = t - datenum(temp.Year,1,1);
    % % inputs = [y t doy]';
    % inputs = [y ]';
    %  
    % % the target is the available data at the main station
    % targets = x';
    %  
    % % Create a Fitting Network
    % hiddenLayerSize = 5;
    % net = fitnet(hiddenLayerSize);
    % 
    % % Set up Division of Data for Training, Validation, Testing
    % net.divideParam.trainRatio = 70/100;
    % net.divideParam.valRatio = 15/100;
    % net.divideParam.testRatio = 15/100;
    %  
    % % Train the Network
    % [net,tr] = train(net,inputs,targets);
    %  
    % % Test the Network
    % outputs = net(inputs);
    % % errors = gsubtract(outputs,targets);
    % performance = perform(net,targets,outputs);
    % 
    % % Plots
    % % Uncomment these lines to enable various plots.
    % % figure, plotperform(tr)
    % % figure, plottrainstate(tr)
    % f = figure;
    % plotfit(net,targets,outputs)
    % print(f,sprintf('%s/%s_1',OutputFolder,VarName1),'-dtiff')
    % % figure, plotregression(targets,outputs)
    % % figure, ploterrhist(errors)
    % 
    % if strcmp(VarName1,'ShortwaveRadiationDownWm2')
    %     outputs(outputs<0) = 0;
    % elseif ~isempty(strfind(VarName1,'RelativeHumidity'))
    %         outputs(outputs>100) = 0;
    % end
    %% Scaling using linear function

    if strcmp ( PlotGapFill,'yes')
    time = datetime(datestr(data3.time));
        ind_1 = time == time; %ismember(time.Month,6:8);

        lm_1=fitlm(data3.(VarName2)(ind_1), data1.(VarName1)(ind_1));
    %     lm_2=fitlm(data2.(VarName2)(ind_2), data1.(VarName1)(ind_2));
        data4 = data3;
        data4.(VarName2)(isnan(data1.(VarName1))) = NaN;
        data_scaled = data3.(VarName2);

        data_scaled(ind_1) = data3.(VarName2)(ind_1)*lm_1.Coefficients.Estimate(2) + lm_1.Coefficients.Estimate(1);
    %     data_scaled(ind_2) = data2.(VarName2)(ind_2)*lm_2.Coefficients.Estimate(2) + lm_2.Coefficients.Estimate(1);

        if strcmp(VarName1,'WindDirection1deg')|| strcmp(VarName1,'WindDirection2deg')
            data_scaled = (data3.(VarName2) - nanmean(data3.(VarName2)))...
                + nanmean(data1.(VarName1));
            data_scaled(data_scaled<0) = 360 + data_scaled(data_scaled<0);
            data_scaled(data_scaled>360) = data_scaled(data_scaled>360) - 360;
            fprintf('wind direction: not taking variance into account\n');
        end

    %     figure
    %     hold on
    %     h1  =scatter(data2.(VarName2),data1.(VarName1),...
    %         'MarkerEdgeColor','b');
    %     h2=scatter(data_scaled,data1.(VarName1),'MarkerEdgeColor','r');
    %     Plotlm(data2.(VarName2),data1.(VarName1),...
    %         'Color',RGB('light blue'),'Annotation','off');
    %     Plotlm(data_scaled,data1.(VarName1),...
    %         'Color',RGB('light red'),'Annotation','off');
    %     h3= plot([min(data1.(VarName1)) max(data1.(VarName1))],...
    %         [min(data1.(VarName1)) max(data1.(VarName1))],...
    %         '--k','LineWidth',2);
    %     legend('before','after scaling','linear fit','linear fit','1:1 line',...
    %         'Location','SouthEast')
    %     axis tight square
    %     box on
end
    %% SLM
    % divi = [0 0.3 0.6 0.7 0.8 0.9 0.95 1];
    % knots = min(y) +  divi* (max(y)-min(y));
    if contains(VarName1,'Humidity')

        slm = slmengine(y,x,'plot','off',...
            'increasing','on',...
            'minslope',0.5,...
            'maxslope',10,...
            'rightvalue',100); %,'knots',knots);
        
    elseif contains(VarName1,'Snowfall')

        slm = slmengine(y,x,'plot','on',...
            'increasing','on',...
            'leftvalue',0); %,'knots',knots);


    elseif  contains(VarName1,'WindSpeed')
        slm = slmengine(y,x,'plot','off',...
        'increasing','on',...
        'minslope',0.9,...
        'leftvalue',0,...
        'rightvalue',max([y; x])); %,'knots',knots);      
    elseif contains(VarName1,'Shortwave')
        slm = slmengine(y,x,'plot','off',...
        'increasing','on',...
        'leftvalue',0,...
        'rightvalue',max([y; x])); %,'knots',knots);
    else
        slm = slmengine(y,x,'plot','off',...
        'increasing','on',...
            'knots',10,...
            'interiorknots','free',...
            'minslope',0.5,...
        'maxslope',10); %,'knots',knots);
    end
    hold on
    x_pred = linspace(min(y), max(y));
    y_pred = slmeval(x_pred,slm);
    
    targets = x';
    outputs=NaN(size(y));
    outputs(~isnan(y)) = slmeval(y(~isnan(y)),slm)';

    [lm, ~] = Plotlm(outputs,targets,...
        'Annotation','off',...
        'Color','r',...
        'LineWidth',2);
    R2_PW_cor = lm.Rsquared.Ordinary;
    RMSE_PW_cor = sqrt(nanmean((targets-outputs').^2));
    ME_PW_cor = nanmean(targets-outputs');

        %% Plotting and comparing
    ind = ~isnan(targets);
       set(0,'DefaultAxesFontSize',18)
if strcmp ( PlotGapFill,'yes')
    f=figure('Visible',vis);
    ha = tight_subplot(1,3,0.02, [0.3 0.3],0.07);
    set(f,'CurrentAxes',ha(1))
        hold on
        scatter(y,targets,'.b')
        [lm, ~] = Plotlm(y,targets,...
            'Annotation','off',...
            'Color','r',...
            'LineWidth',2);
        plot(x_pred,y_pred,'--c','LineWidth',3)

        title(sprintf('R^2 = %0.2f, RMSE = %0.2f,\n ME = %0.2f',...
            lm.Rsquared.Ordinary,....
            sqrt(nanmean((targets'-y).^2)),...
            nanmean(targets'-y)),'interpreter','tex');
        axis tight square
        for i = 1:length(slm.knots)
            plot([1 1].*slm.knots(i),get(gca,'YLim'),'Color',RGB('gray'))
        end

        plot([min(targets) max(targets)], [min(targets) max(targets)], ':k','LineWidth',2)
        box on
        legendflex({'data','linear fit','piecewise spline fit','1:1 line'},...
                            'ref', gcf, ...
                           'anchor', {'n','n'}, ...
                           'buffer',[0 2.5], ...
                           'ncol',2, ...
                           'fontsize',18,...
                       'title',strcat('{\it',...
                       sprintf('Reconstruction of %s}',VarName1)),...
                       'interpreter','tex');
        ylabel('Main station')
        xlabel(sprintf('Raw data from %s',Name))

    set(f,'CurrentAxes',ha(2))
    hold on
    scatter(data_scaled,targets,'.b')
    [lm, ~] = Plotlm(data_scaled,targets,...
        'Annotation','off',...
        'Color','r',...
        'LineWidth',2);
    plot([min(targets) max(targets)], [min(targets) max(targets)],...
        ':k','LineWidth',2)
    box on

    title(sprintf('R^2 = %0.2f, RMSE = %0.2f,\n ME = %0.2f',...
        lm.Rsquared.Ordinary,....
        sqrt(nanmean((targets'-data_scaled).^2)),...
        nanmean(targets'-data_scaled)),'interpreter','tex');
    axis tight square
    % ylabel('Main station')
    xlabel(sprintf('Data from %s\n corrected using linear fit',Name))
    set(gca,'YTickLabel','')
    
    set(f,'CurrentAxes',ha(3))
    hold on
    scatter(outputs,targets,'.b')

    plot([min(targets) max(targets)], [min(targets) max(targets)], ':k','LineWidth',2)
    title(sprintf('R^2 = %0.2f, RMSE = %0.2f,\n ME = %0.2f',...
        R2_PW_cor,....
        RMSE_PW_cor,...
        ME_PW_cor),'interpreter','tex');
    axis tight square
    box on
    % ylabel('Main station')
    xlabel(sprintf('Data from %s\n corrected using \npiecewise spline fit',Name))

    set(gca,'YTickLabel','')
    print(f,sprintf('%s/%s_2',OutputFolder,VarName1),'-dtiff')
        if strcmp(vis,'off')
            close(f);
        end
end

    %%  Filling the gaps 
        ind_common = find(and(data.time<=data2.time(end)+0.0001,data.time>=data2.time(1)-0.0001));
        data_out = data1;
        origin_field_name = sprintf('%s_Origin',VarName1);
        if ismember(origin_field_name,data.Properties.VariableNames)
            ind_changed = and(isnan(data_out.(VarName1)),~isnan(outputs));
            data.(origin_field_name)(ind_common(ind_changed)) = ind_sec_station;
        end
        
        data_out.(VarName1)(isnan(data_out.(VarName1))) = ...
            outputs(isnan(data_out.(VarName1)));
    
        data.(VarName1)(ind_common) = data_out.(VarName1);

        %     plot(data1.time,data_out)
    if strcmp ( PlotGapFill,'yes')
        f = figure('Visible',vis);
        ha = tight_subplot(2,1,0.05,[0.2 0.14],[0.1 0.05]);
                set(f,'CurrentAxes',ha(1))
        plot(data3.time,data_scaled)
        hold on
        plot(data1.time,data1.(VarName1))
        axis tight
        ylab_obj = ylabel(VarName1);
        ylab_obj.Units = 'Normalized';
        ylab_obj.Position(2) = ylab_obj.Position(2)-0.6;
        set(gca,'XMinorTick','on','YMinorTick','on','XTickLabel','')
        title('Using data corrected with linear function')

                set(f,'CurrentAxes',ha(2))
        plot(data3.time,y)
        plot(data3.time,outputs)
        hold on
        plot(data1.time,data1.(VarName1))

        set(gca,'XMinorTick','on','YMinorTick','on')
        legendflex({'Corrected secondary data','Main station data'}, ...
                        'ref', gcf, ...
                       'anchor', {'n','n'}, ...
                       'buffer',[0 0], ...
                       'ncol',2);
        title('Using data scaled with piecewise spline fit')
        datetick('x','dd-mm-yy')
        axis tight
        xlabel('Time')
        print(f,sprintf('%s/%s_3',OutputFolder,VarName1),'-dtiff')
        if strcmp(vis,'off')
            close(f);
        end
end
end
end


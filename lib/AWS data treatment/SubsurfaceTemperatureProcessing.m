function data = SubsurfaceTemperatureProcessing(data,station, is_GCnet,OutputFolder,vis)
% This function reads the maintenance information of a station and shift the
% depth of subsurface temperature observation by the appropriate distance
% whenever new temperature strings were installed during maintenance.
% It also performs some smoothing.
%
% Baptiste Vandecrux
% b.vandecrux@gmail.com
% 2018
% ========================================================================
maintenance = ImportMaintenanceFile(station);
% initializing some variables

    data.DepthThermistor1m = ones(size(data.IceTemperature1C));
    data.DepthThermistor2m = ones(size(data.IceTemperature1C));
    data.DepthThermistor3m = ones(size(data.IceTemperature1C));
    data.DepthThermistor4m = ones(size(data.IceTemperature1C));
    data.DepthThermistor5m = ones(size(data.IceTemperature1C));
    data.DepthThermistor6m = ones(size(data.IceTemperature1C));
    data.DepthThermistor7m = ones(size(data.IceTemperature1C));
    data.DepthThermistor8m = ones(size(data.IceTemperature1C));
    if is_GCnet
        num_therm = 10;
        data.DepthThermistor9m = ones(size(data.IceTemperature1C));
        data.DepthThermistor10m = ones(size(data.IceTemperature1C));
    else
        num_therm = 8;
    end
       
    count = 0;
    maintenance_date = 0;
    % for each maintenance entry
    for i = 1:size(maintenance,1)
        
        % if thermistor string has been installed
        if sum(~isnan(table2array(maintenance(i,(end-9):end)))) > 1
            %there is at least one specified depth
            count = count+1;
            if count == 1
                maintenance_date(count) = min(min(data.time), datenum(maintenance.date(i)));
            else
                maintenance_date(count) = datenum(maintenance.date(i));
            end
            %             fprintf('Maintenance on the thermistor string on the %s.\n',...
            %                 datestr(maintenance_date(count)));
            %             disp('depth last thermistor')
            %             disp(max(table2array(maintenance(i,(end-9):end))))
            %depth of the last thermistor updated for all time steps after
            %maintenance
            [~, ind_temp] = min(abs(data.time - maintenance_date(count)));
            while isnan(data.SurfaceHeightm(ind_temp))
                ind_temp = ind_temp+1;
            end
            %         [depth_sorted, ind_sorted] = sort(maintenance_string(i,:));
            
            for j = 1:num_therm
                varname = sprintf('DepthThermistor%im',j);
                data.(varname)(data.time >= maintenance_date(count)) = ...
                    ones(sum(data.time >= maintenance_date(count)),1) ...
                    * (table2array(maintenance(i,j+14)) - data.SurfaceHeightm(ind_temp));
                %                 fprintf('%s is %f\n', varname, table2array(maintenance(i,ii+14)));
            end
        end
    end
    
    % when surface rises depth increases
    ind_nan = isnan(data.SurfaceHeightm);
    Surface_Height_interp = data.SurfaceHeightm;
    Surface_Height_interp(ind_nan) = interp1(data.time(~ind_nan), ...
        data.SurfaceHeightm(~ind_nan),...
        data.time(ind_nan));
%     % For some statiosn, the depth thermistor is measure with difference
%     % from surface and for some to the updated ice surface
%     % check 'Therm_depth.png' to see, if the station has to be excluded
%     % from surface adjustment
    if sum(~strcmp(station,{'NASA-E','NASA-U','SouthDome','TUNU-N'}))>0
        for i = 1:num_therm
            varname = sprintf('DepthThermistor%im',i);
            data.(varname) = data.(varname) + Surface_Height_interp;
       end
    end
    
    % Sets to zero depth any sensor from the moment it surfaces until the
    % next maintenance
    for i = 1:length(maintenance_date)
        if data.time(end) > maintenance_date(i) && data.time(1) < maintenance_date(i)
            if i < length(maintenance_date)
                ind_period = find(and((data.time >= maintenance_date(i)),...
                    (data.time < maintenance_date(i+1))));
            else
                ind_period = find(data.time >= maintenance_date(i));
            end
            %first time thermistor surfaces
            for j = 1:num_therm
                varname = sprintf('DepthThermistor%im',j);
                %             data.(varname)(data.time >= maintenance_date(count)) = ...
                %                 ones(sum(data.time >= maintenance_date(count)),1) ...
                %                 * (maintenance_string(i,ind_sorted(ii)) - data.SurfaceHeightm(ind_temp));
                
                first_surf = find(data.(varname)(ind_period) <= 0, 1, 'first');
                
                data.(varname)(ind_period(first_surf):ind_period(end)) = 0;
            end
        end
    end
    if is_GCnet
        depth_T_ice_obs = [data.DepthThermistor1m, data.DepthThermistor2m, data.DepthThermistor3m,...
            data.DepthThermistor4m, data.DepthThermistor5m, data.DepthThermistor6m,...
            data.DepthThermistor7m, data.DepthThermistor8m, data.DepthThermistor9m,...
            data.DepthThermistor10m]';
        
        % Surfaced thermistor discarded
        depth_T_ice_obs(depth_T_ice_obs <= 0) = NaN;
        T_ice_obs = [data.IceTemperature1C, data.IceTemperature2C, data.IceTemperature3C,...
            data.IceTemperature4C, data.IceTemperature5C, data.IceTemperature6C,...
            data.IceTemperature7C, data.IceTemperature8C, data.IceTemperature9C, ...
            data.IceTemperature10C]';
    else
        depth_T_ice_obs = [data.DepthThermistor1m, data.DepthThermistor2m, data.DepthThermistor3m,...
            data.DepthThermistor4m, data.DepthThermistor5m, data.DepthThermistor6m,...
            data.DepthThermistor7m, data.DepthThermistor8m]';
        
        % Surfaced thermistor discarded
        depth_T_ice_obs(depth_T_ice_obs <= 0) = NaN;
        T_ice_obs = [data.IceTemperature1C, data.IceTemperature2C, data.IceTemperature3C,...
            data.IceTemperature4C, data.IceTemperature5C, data.IceTemperature6C,...
            data.IceTemperature7C, data.IceTemperature8C]';
    end
    
    % Thermistor data processing
    % smoothing of the individual thermistor recordsto remove the noise
    %
    % to allow plotting (slows down the code), uncomment appropriate lines
    
    T_ice_obs_org = T_ice_obs;
    text_leg = {};
    
    f = figure('Visible',vis);
        hold on  
    
    for i=1:num_therm
        plot(data.time, T_ice_obs_org(i,:))
        text_leg = {text_leg{:} sprintf('thermistor %i',i)};
    end
    legend(text_leg)
    axis tight
    ylim([min(-5,min(T_ice_obs(i,:))) max(T_ice_obs(i,:))]);
    set_monthly_tick(data.time)
    print(f, sprintf('%s/Therm_%i_pre_proc',OutputFolder,i), '-dpng')

    f = figure('Visible',vis);
    for i=1:num_therm
        % deleating erroneous temperature after installation
        T_ice_obs(i, 1:24*2) = NaN;
        % smoothing
%         T_ice_obs(i, :) = hampel(T_ice_obs(i, :),24*4,0.1);
        
        %removing data ponts that are taken when the sensor was at the
        %surface
        T_ice_obs(i,depth_T_ice_obs(i,:)==0)=NaN;
        
        %removing subfreezing temperatures
        T_ice_obs(i,T_ice_obs(i,:)>0) = 0;
        
        hold on
        plot(data.time, T_ice_obs(i,:))
        text_leg = {text_leg{:} sprintf('thermistor %i',i)};
    ylim([min(-5,min(T_ice_obs(i,:))) max(T_ice_obs(i,:))]);

%         pause
    end
    legend(text_leg,'Location','EastOutside')
    axis tight
    ylim([min(-5,min(T_ice_obs(i,:))) max(T_ice_obs(i,:))]);
    set_monthly_tick(data.time)
    print(f, sprintf('%s/Therm_%i_post_proc',OutputFolder,i), '-dpng')

    
    % save modifications
    data.IceTemperature1C = T_ice_obs(1,:)';
    data.IceTemperature2C = T_ice_obs(2,:)';
    data.IceTemperature3C = T_ice_obs(3,:)';
    data.IceTemperature4C = T_ice_obs(4,:)';
    data.IceTemperature5C = T_ice_obs(5,:)';
    data.IceTemperature6C = T_ice_obs(6,:)';
    data.IceTemperature7C = T_ice_obs(7,:)';
    data.IceTemperature8C = T_ice_obs(8,:)';
    if is_GCnet
        data.IceTemperature9C = T_ice_obs(9,:)';
        data.IceTemperature10C = T_ice_obs(10,:)';
    end
    
    
    % Plot thermistor depth evolution
    f = figure('Visible',vis);
    ha = tight_subplot(2,1,.01, [.1 .01], .1);
    
    set(f,'CurrentAxes',ha(1))
    hold on
    leg=cell(num_therm,1);
    for i=1:num_therm
        plot(data.time, -depth_T_ice_obs(i,:))
        leg{i} = sprintf('thermistor %i',i);
    end
    axis tight
    xlimit=get(gca,'XLim');
    h = line(xlimit,[0 0]);
    box on
    h.Color = 'r';
    h.LineWidth=2;
    legend({leg{:},'Surface'})
    ylabel('Depth (m)')
    box on
    datetick('x','yyyy', 'keeplimits', 'keepticks')
    
    set(f,'CurrentAxes',ha(2))
    plot(data.time, data.SurfaceHeightm,'r','LineWidth',2)
    hold on
    for i=1:num_therm
        plot(data.time, ...
            -depth_T_ice_obs(i,:) + data.SurfaceHeightm')
    end
    xlabel('Date')
    ylabel('Height (m)')
    axis tight
    box on
    set(gca,'XLim',xlimit)
    datetick('x','yyyy', 'keeplimits', 'keepticks')
    print(f, sprintf('%s/Therm_depth',OutputFolder), '-dpng')
    
    % ================= Plot observed subsurface temperature =============
    time_mat = repmat(data.time',num_therm,1);
    
    % when describing the subsurface, it is important to know if the depth
    % origin is taken at the surface at any time (even though the surface is
    % moving up and down) or if it is taken a specified height independant
    % of time
    
    % first we plot with origin at the surface
            f = figure('Visible',vis);
            PlotTemp(time_mat(:,1:72:end), depth_T_ice_obs(:,1:72:end), T_ice_obs(:,1:72:end),...
                'PlotTherm', 'yes',...
                'PlotIsoTherm', 'yes',...
                        'Range',-25:1:0);
            print(f, sprintf('%s/T_ice_obs_1',OutputFolder), '-dpng')
    
    % with origin at initial surface level
	rel_depth_T_ice_obs = depth_T_ice_obs - repmat(data.SurfaceHeightm',num_therm,1);
	
	        f = figure('Visible',vis);
	        PlotTemp([time_mat(1,1:72:end); time_mat(:,1:72:end)], ...
                [rel_depth_T_ice_obs(1,1:72:end); rel_depth_T_ice_obs(:,1:72:end)], ...
                [T_ice_obs(1,1:72:end); T_ice_obs(:,1:72:end)],...
	            'PlotTherm', 'yes',...
	            'PlotIsoTherm', 'no',...
	            'Range',-25:1:0);
	    hold on
	    plot(data.time, -data.SurfaceHeightm,'r','LineWidth',2)
	    ylim([-20 10])
	    if strcmp(station,'DYE-2')
	        xlim([data.time(1) datenum('01-Aug-2009')])
	    end
	    print(f, sprintf('%s/T_ice_obs_2',OutputFolder), '-dpng')
    end
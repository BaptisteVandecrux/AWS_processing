function [depth_therm_modscale, T_ice_obs] = CalculateThermistorDepth(time_mod,...
    depth_absolute, H_surf,compaction,depth_obs, T_ice_obs, H_surf_obs, station_name)
% This function calculates the thermistor depth based on a given surface
% height record (and therefore the burial rate), a maintenance report 
% and a compaction grid which indicates the compaction occuring between the
% buried sensores. Eventually removes the observed subsurface temperature
% that are less than 0.5 m below the surface.
%   
% Inputs:
% - time_mode: vector containing modelled time stamps
% - depth_absolute: matrix containing, for each model layer and at each
% time step, the absolute depth of the layer. The depth scale is anchored 
% at the bottom of the model, at a depth below which no firn-related
% compaction should occur. The zero of this scale is located at the initial
% surface level at the beginning of the simulation. Depth increase
% downward.
% - H_surf: Modelled surface height
% - depth_obs: Previous (rougher) estimation of sensors' depth (should be
% removed at some point).
% - H_surf_obs: Surface height observed by the Sonic Rangers.
% - station_name: Used to locate the maintenance file.
% - T_ice_obs: Observed subsurface temperature
%     
% Ouputs:
% - depth_therm_modscale: matrix containing the depth of the thermistors on
% the model's absolute depth scale (see depth_absolute description)
%
% 16-10-2018
% B. Vandecrux
% b.vandecrux@gmail.com
% ========================================================================
    
step = 72;

    maintenance = ImportMaintenanceFile(station_name);
    varnames = maintenance.Properties.VariableNames;
    depth_therm_modscale = NaN(size(depth_obs,1),length(time_mod));
    if strcmp(station_name,'Summit')
        jhv=0;
    end
% figure
% hold on
% plot(time_mod, H_surf)
    for j = 1:size(maintenance,1)
        date_start = maintenance.date(j);
        if date_start > time_mod(end) || isnan(maintenance.NewDepth4m(j))
            continue
        end
                
        % finding next maintenance of the thermistor string
        ind_next = min(length(maintenance.NewDepth4m), j+1);
        while ind_next <length(maintenance.NewDepth4m) && isnan(maintenance.NewDepth4m(ind_next))
            ind_next = ind_next + 1;
        end
        date_end = min(maintenance.date(ind_next),time_mod(end));
        
        % if the last maintenance entry does not contain thermistor
        % installation then we continue until the end of the file
        if isnan(maintenance.NewDepth4m(ind_next))
            date_end = time_mod(end);
        end
        
        if date_end < time_mod(1)-30
            %if the following maintenance is also long before the study
            %period, then we ignore the entry and continue
            continue
        end
        [~, i_time_start] = min(abs(time_mod - date_start));
        [~, i_time_end] = min(abs(time_mod - date_end));
        
        
        % case when modelled starts some time after the installation of the
        % thermistor
        if date_start < time_mod(1)-30           
            % then we use the thermistor depth corrected for observed
            % surface height change but cannot correct the compaction until
            % the modelled compaction is available
            for kk = 1:size(depth_obs,1)
                depth_therm_modscale(kk,1:i_time_end-1) = ...
                   depth_obs(kk,1:i_time_end-1) - H_surf_obs(1:i_time_end-1)';

               % removing T_ice too close to the surface until the next
               % maintenance
                ind_out = find(depth_therm_modscale(kk, i_time_start:i_time_end)...
                        < 0.5-H_surf(i_time_start:i_time_end)', 1,'first');
                T_ice_obs(kk, (i_time_start + ind_out - 1):i_time_end) = NaN;
            end
            continue
        end
        
        % assigning the depth of the thermistors on the model's absolute
        % depth scale
        for kk = 1:size(depth_obs,1)
            depth_therm_modscale(kk,i_time_start) = ...
                maintenance.(varnames{14+kk})(j) - H_surf(i_time_start);
        end
        
        % for each time step following the installation
        for i = (i_time_start+step):step:(i_time_end-1)
            % we use the depths with origin at the bottom of the model
            % domain
            depth_mod_col = depth_absolute(:,i);
            % we first assume that the sensor is still buried at the
            % same absolute depth. Since we work with absolute depth
            % the material accumulating or sublimating at the surface
            % do not interfer
            depth_therm_modscale(:,i) = depth_therm_modscale(:,i-step);

            % however the material between the sensor and the bottom of
            % the model was still subject to compaction within that
            % time step which should decrease the absolute depth of the
            % sensor
            temp = [depth_mod_col; depth_therm_modscale(:,i)];
            [new_depth,ind_depth] = sort(temp);
            
            % here "ConvertToGivenDepthScale" works with depth interval
            % starting at 0 positive downward, so we feed that function
            % with the model depth and desired depth relative to the
            % surface
            compaction_2 = ConvertToGivenDepthScale(max(0, depth_mod_col - H_surf(i)),...
                compaction(:,i), max(0, new_depth- H_surf(i)), 'extensive')*step;

            % now we update our first guess by adding the sum of all
            % compaction that occured bellow the sensor
            for kk = 1:size(depth_obs,1)
                ind_therm = find(ind_depth == 11+kk);
                depth_therm_modscale(kk, i) = ...
                    depth_therm_modscale(kk, i) + sum(compaction_2((ind_therm+1):end));
            end
        end
    % sorting the depth (ice temperature were already sorted)
    for i = 1:length(time_mod)
        [depth_therm_modscale(:,i), ind]= sort(depth_therm_modscale(:,i),'ascend');
%         T_ice_obs(:,i) = T_ice_obs(ind,i);
    end
        


        for kk = 1:size(depth_obs,1)
            % interpolate over all initial time stamps
            ind_nan = find(isnan(depth_therm_modscale(kk, i_time_start:i_time_end)));
            ind_nonan = find(~isnan(depth_therm_modscale(kk, i_time_start:i_time_end)));
            depth_therm_modscale(kk, i_time_start + ind_nan -1) = ...
                interp1(ind_nonan,depth_therm_modscale(kk, i_time_start + ind_nonan -1),...
                ind_nan,'linear','extrap' );

% plot(time_mod(i_time_start:i_time_end), -depth_therm_modscale(kk, i_time_start:i_time_end),'.')
            % removing the temperatures hat are too close or above the surface
            ind_out = find(depth_therm_modscale(kk, i_time_start:i_time_end)...
                    < 0.5-H_surf(i_time_start:i_time_end)', 1,'first');
% plot(time_mod((i_time_start + ind_out - 1):i_time_end), -depth_therm_modscale(kk, (i_time_start + ind_out - 1):i_time_end),'x')

            T_ice_obs(kk, (i_time_start + ind_out - 1):i_time_end) = NaN;
%                  figure
% hold on
% plot(H_surf(i_time_start:i_time_end))
% plot(-depth_therm_modscale(kk, i_time_start:i_time_end))  
%         sdhg = 0;
        

        end
        
        
        
    end



    
end
    
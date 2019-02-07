function [T_ice_obs, depth_thermistor, data_out] = LoadThermFA13(time_mod, H_surf)
    [~, ~, raw] = xlsread('C:\Users\bava\ownCloud_new\Data\Miège\FA13_thermarray_L1B.xls','FA13_thermarray','A3:BL8818');
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};

    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells

    data = reshape([raw{:}],size(raw));

    data_out = table;

    data_out.Year = data(:,1);
    data_out.Month = data(:,2);
    data_out.Day = data(:,3);
    data_out.hh = data(:,4);
    data_out.ta_1 = data(:,5);
    data_out.ta_2 = data(:,6);
    data_out.ta_3 = data(:,7);
    data_out.ta_4 = data(:,8);
    data_out.ta_5 = data(:,9);
    data_out.ta_6 = data(:,10);
    data_out.ta_7 = data(:,11);
    data_out.ta_8 = data(:,12);
    data_out.ta_9 = data(:,13);
    data_out.ta_10 = data(:,14);
    data_out.ta_11 = data(:,15);
    data_out.ta_12 = data(:,16);
    data_out.ta_13 = data(:,17);
    data_out.ta_14 = data(:,18);
    data_out.ta_15 = data(:,19);
    data_out.ta_16 = data(:,20);
    data_out.ta_17 = data(:,21);
    data_out.ta_18 = data(:,22);
    data_out.ta_19 = data(:,23);
    data_out.ta_20 = data(:,24);
    data_out.ta_21 = data(:,25);
    data_out.ta_22 = data(:,26);
    data_out.ta_23 = data(:,27);
    data_out.ta_24 = data(:,28);
    data_out.ta_25 = data(:,29);
    data_out.ta_26 = data(:,30);
    data_out.ta_27 = data(:,31);
    data_out.ta_28 = data(:,32);
    data_out.ta_29 = data(:,33);
    data_out.ta_30 = data(:,34);
    data_out.ta_31 = data(:,35);
    data_out.ta_32 = data(:,36);
    data_out.ta_33 = data(:,37);
    data_out.ta_34 = data(:,38);
    data_out.ta_35 = data(:,39);
    data_out.ta_36 = data(:,40);
    data_out.ta_37 = data(:,41);
    data_out.ta_38 = data(:,42);
    data_out.ta_39 = data(:,43);
    data_out.ta_40 = data(:,44);
    data_out.ta_41 = data(:,45);
    data_out.ta_42 = data(:,46);
    data_out.ta_43 = data(:,47);
    data_out.ta_44 = data(:,48);
    data_out.ta_45 = data(:,49);
    data_out.ta_46 = data(:,50);
    data_out.ta_47 = data(:,51);
    data_out.ta_48 = data(:,52);
    data_out.ta_49 = data(:,53);
    data_out.ta_50 = data(:,54);
    data_out.ta_51 = data(:,55);
    data_out.ta_52 = data(:,56);
    data_out.ta_53 = data(:,57);
    data_out.ta_54 = data(:,58);
    data_out.ta_55 = data(:,59);
    data_out.ta_56 = data(:,60);
    data_out.ta_57 = data(:,61);
    data_out.ta_58 = data(:,62);
    data_out.ta_59 = data(:,63);
    data_out.ta_60 = data(:,64);

    clearvars data raw R;

    data_out = standardizeMissing(data_out,-9999);
    data_out.time =  datenum(data_out.Year,data_out.Month,data_out.Day,data_out.hh,0,0);
    data_out =ResampleTable(data_out);
    ind=and(data_out.time>=time_mod(1),data_out.time<=time_mod(end));
    data_out=data_out(ind,:);
    T_ice_obs = table2array(data_out(:,6:end))';

    [~, ~, raw] = xlsread('C:\Users\bava\ownCloud_new\Data\Miège\FA13_thermarray_L1B.xls','FA13_thermarray','A2:BL2');
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells
    depth_therm = reshape([raw{:}],size(raw));
    clearvars raw R;
    depth_therm(1:4)=[];
    depth_thermistor = repmat(depth_therm',1,size(T_ice_obs,2));

    for i=1:size(depth_thermistor,1)
            ind_nan = find(isnan(T_ice_obs(i,:) ));
            ind_no_nan = find(~isnan(T_ice_obs(i,:) ));
            T_ice_obs(i,ind_nan) = interp1gap(ind_no_nan,T_ice_obs(i,ind_no_nan),ind_nan,24);
            depth_thermistor(i,:) = depth_thermistor(i,:) + H_surf';
    end
    
    T_ice_obs(depth_thermistor<=0.1) = NaN;
%     T_obs(T_obs>0.01) = NaN;
    T_ice_obs = T_ice_obs;
    
    T_ice_obs(1:4,:) = [];
    depth_thermistor(1:4,:) = [];
        
%     data_therm(:,6:end) = T_obs;

    T_ice_obs = T_ice_obs';
    depth_thermistor = depth_thermistor';
    
    for j = 1:size(T_ice_obs,2)
        data_out(:,5+j) = array2table(T_ice_obs(:,j));
        data_out.Properties.VariableNames{5+j} = ...
            sprintf('IceTemperature%iC',j);
    end
    for j = 1:size(T_ice_obs,2)
        data_out(:,61+j) = array2table(depth_thermistor(:,j));
        data_out.Properties.VariableNames{61+j} = ...
            sprintf('DepthThermistor%im',j);
    end    
    
        %     time_therm = data_therm.time;
end


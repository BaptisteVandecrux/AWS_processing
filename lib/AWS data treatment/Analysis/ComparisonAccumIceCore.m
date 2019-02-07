function ComparisonAccumIceCore(station_list,data_in, vis)
for ii = 1:length(station_list)
    c.station = station_list{ii};

    %% loading HIRHAM data
    if strcmp(c.station,'CP1')
        filename = strcat('C:\Users\bava\OwnCloud_new\Data\AWS\Input\HIRHAM\pr\HIRHAM_GL2_','CrawfordPt.','_1990_2014_pr.txt');
    else
        filename = strcat('C:\Users\bava\OwnCloud_new\Data\AWS\Input\HIRHAM\pr\HIRHAM_GL2_',c.station,'_1990_2014_pr.txt');
    end
    delimiter = ',';
    formatSpec = '%f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fileID);
    HH = table(dataArray{1:end-1}, 'VariableNames', {'pr','time'});
    clearvars filename delimiter formatSpec fileID dataArray ans;
    HH.pr = HH.pr /1000;
    % HH_hourly = ResampleTable(HH);
    % HH_hourly.pr = HH_hourly.pr/3;
    HH_year = AvgTable(HH,'yearly','sum');

%% loading data from one file
disp('Plotting accumulation and comparison with cores')
    [~, ~, raw] = xlsread('C:\Users\bava\OwnCloud_new\Code\FirnModel_bv_v1.3\Input\Extra\Accumulation.xlsx','Overview','A2:C11');
    raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
    cellVectors = raw(:,[2,3]);
    raw = raw(:,1);
    data = reshape([raw{:}],size(raw));
    Accumulation = table;
    Accumulation.sheet = data(:,1);
    Accumulation.station = cellVectors(:,1);
    Accumulation.description = cellVectors(:,2);
    clearvars data raw cellVectors;
    
    ind = find(strcmp(c.station,Accumulation.station));
    
    if ~isempty(ind)
        accum = {};
        count = 1;
        for i = 1:length(ind)
            name_core{i} = Accumulation.description{ind(i)};
            
            data = xlsread('C:\Users\bava\OwnCloud_new\Code\FirnModel_bv_v1.3\Input\Extra\Accumulation.xlsx',...
                sprintf('Sheet%i',ind(i)));
            accum{count} = table;
            accum{count}.year = data(:,1);
            accum{count}.SMB = data(:,2);
            clearvars data raw;
            count = count +1;
        end
        
        % change comp_box13 to 1 if you want it to appear in the comparison
        comp_box13 = 0;
        if comp_box13
            % loading Box 2013 accumulation rates
            %             namefile = 'C:\Users\bava\ownCloud\Phd_owncloud\Data\Box 2013\Box_Greenland_Accumulation_annual_1840-1999_ver20140214.nc';
            namefile = '..\Box 2013\Box_Greenland_Accumulation_annual_1840-1999_ver20140214.nc';
            finfo = ncinfo(namefile);
            names={finfo.Variables.Name};
            for i= 1:size(finfo.Variables,2)
                eval(sprintf('%s = ncread(''%s'',''%s'');', char(names{i}), namefile,char(names{i})));
            end
            fprintf('\nData extracted from nc files.\n');
            
            dist = sqrt((lat-c.lat).^2 + (lon-c.lon).^2);
            
            [dist_sorted, ind] = sort((dist(:)));
            accum_site = zeros(160,1);
            for i = 1:4
                [i , j]  = ind2sub(size(dist),ind(i));
                accum_site = accum_site + squeeze(acc(i,j,:));
            end
            accum_site = accum_site/4000;
        end
        
        % change comp_MAR to 1 if you want it to appear in the comparison
        comp_MAR = 0;
        if comp_MAR
            if strcmp(c.station,'CP1')
                filename = '..\RCM\MAR\MARv3.5.2_20CRv2c_CP.txt';
            else
                filename = '..\RCM\MAR\MARv3.5.2_20CRv2c_Dye-2.txt';
            end
            
            delimiter = ' ';
            formatSpec = '%f%f%[^\n\r]';
            fileID = fopen(filename,'r');
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
            fclose(fileID);
            MAR = table(dataArray{1:end-1}, 'VariableNames', {'year','accum'});
            clearvars filename delimiter formatSpec fileID dataArray ans;
            
            if strcmp(c.station,'CP1')
                MAR(1:77,:) = [];
            elseif strcmp(c.station,'DYE-2')
                MAR(1:75,:) = [];
            end
        end
                
        years_accum = [];
        accum_all = [];
        for i = 1:length(accum)
            years_accum = [years_accum accum{i}.year'];
            accum_all = [accum_all accum{i}.SMB'];
        end
        
        years_uni = unique(years_accum);
        accum_std = [];
        accum_mean = [];
        num_cores = [];
        for i = 1:length(years_uni)
            ind = years_accum==years_uni(i);
            accum_std = [accum_std std(accum_all(ind))];
            accum_mean = [accum_mean nanmean(accum_all(ind))];
            num_cores = [num_cores sum(ind)];
        end
        x = [years_uni; accum_mean; accum_std; num_cores];
        
        accum_mean = table;
        num_max_cores = max(num_cores);
        
        accum_mean.year = x(1,num_cores>=1)'; %==num_max_cores);
        accum_mean.accum = x(2,num_cores>=1)'; %==num_max_cores);
        accum_mean.std = x(3,num_cores>=1)'; %==num_max_cores);
        
        accum_mean(find(accum_mean.year<1984),:) = [];
        
        disp('average')
        disp(nanmean(accum_mean.accum))
        
        % Plotting
        
        %maximum of standard deviation 0.31 and on average 0.11
        % yu = accum{i}.SMB+0.1;
        % yl = accum{i}.SMB-0.1;
        yu = accum_mean.accum + accum_mean.std;
        yl = accum_mean.accum - accum_mean.std;
        
        if strcmp(c.station,'DYE-2')
            yu = accum_mean.accum + 0.11;
            yl = accum_mean.accum - 0.11;
        end
        
        % Plotting
        f = figure('Visible',vis,'units','normalized','outerposition',[0 0 0.8 1]);
        hold on
        
        for i = 1:length(accum)
            plot(accum{i}.year,accum{i}.SMB,...
                'LineWidth',2);
        end
        DV = datevec(HH_year.time);
        plot(DV(:,1),HH_year.pr,'k','LineWidth',2);
        
        axis tight
        set(gca,'layer','top')
        box on
        set(gca,'XMinorTick','on','YMinorTick','on')
        xlabel('Year')
        ylabel('Surface Mass Balance (m w.eq.)')
        xlim([1970 2014])
        title(c.station)
        legend('Ice core','HIRHAM','Location','EastOutside')
        print(f,sprintf('./Output/data_overview/%s_HH_accum',c.station),'-dtiff')
      
    else
        disp('No core available for historical accumulation')
    end
end
end
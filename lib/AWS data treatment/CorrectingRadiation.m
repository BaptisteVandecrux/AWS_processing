function [data] = CorrectingRadiation(data,station,vis)
namefile = 'C:\Users\bava\ownCloud\Phd_owncloud\Data\q\GCnet\Wenshan correction\dye.2008-2016.05-09.nc';
%     finfo = ncinfo(namefile);
%     names={finfo.Variables.Name};
    var_list = {'fsds_rigb','fsus_rigb'};
    for i= 1:length(var_list)
        eval(sprintf('%s = ncread(''%s'',''%s'');', var_list{i}, namefile,var_list{i}));
    end
   SWdown_cor = [];
   SWup_cor = [];
   time_cor = [];
   
    for i_year = 1: 6 %size(fsds_rigb,4)
        
        for i_month = 1: size(fsds_rigb,3)
            last_day_of_month = eomday(2008+i_year-1,5+i_month-1);
            for i_day = 1: size(fsds_rigb,2)
                if i_day> last_day_of_month
                    continue
                end
                time_rad = ...
                    datetime(2008+i_year-1,5+i_month-1,i_day,0:23,0,0);
                time_cor = [time_cor, time_rad];
                SWdown_cor = [SWdown_cor; squeeze(fsds_rigb(:,i_day,i_month,i_year))];
                SWup_cor = [SWup_cor; squeeze(fsus_rigb(:,i_day,i_month,i_year))];
            end
        end
    end
    
    time_rad = datenum(time_cor)' +1/24;
%     temp = time_cor';
    data_cor = table;
    data_cor.time = [time_rad(1):1/24:time_rad(end)]';

    data_cor.ShortwaveRadiationDownWm2 = NaN(size(data_cor.time));
    data_cor.ShortwaveRadiationUpWm2 = NaN(size(data_cor.time));
    
    for i =1:length(time_rad)
        [~, ind] = min(abs(data_cor.time-time_rad(i)));
        data_cor.ShortwaveRadiationDownWm2(ind) = SWdown_cor(i);
        data_cor.ShortwaveRadiationUpWm2(ind) = SWup_cor(i);
    end    
    data.Albedo = data.ShortwaveRadiationUpWm2./data.ShortwaveRadiationDownWm2;
    data.Albedo(data.Albedo>1)=NaN;
    data.Albedo(data.Albedo<0)=NaN;
        
    data_cor.Albedo = data_cor.ShortwaveRadiationUpWm2./data_cor.ShortwaveRadiationDownWm2;
    data_cor.Albedo(data_cor.Albedo>1)=NaN;
    data_cor.Albedo(data_cor.Albedo<0)=NaN;
    
var_list = {'ShortwaveRadiationDownWm2','ShortwaveRadiationUpWm2','Albedo'};
ind_common = ismember(data.time,...
    data_cor.time(~isnan(data_cor.ShortwaveRadiationDownWm2)));

for i = 1:length(var_list)
    varname = var_list{i};
    
        f = figure('Visible',vis);
        ha=tight_subplot(1,2,0.07,0.07,0.07);
        set(f,'CurrentAxes',ha(1))
        CompareData('GCnet', 'Corrected', data, varname,...
            data_cor, varname);

        set(f,'CurrentAxes',ha(2))
        hold on
        plot(data.time,data.(varname))
        plot(data_cor.time,data_cor.(varname))
        axis tight
        xlabel('Time')
        ylabel(varname)
        legend('GCnet','Corrected')
        set(gca,'XMinorTick','on','YMinorTick','on')
        box on
        datetick('x','mm-yyyy')
            xlim([min(data_cor.time) max(data_cor.time)])
            print(f,sprintf('./Output/Comparison Wenshan/comp_corrected_%s',varname),'-dpng')
            
%         ind_common_2 = ismember(data_cor.time,data_AWS.time(ind_common));
%         data_AWS.(varname)(ind_common)= ...
%             data_cor.(varname)(ind_common_2);
end

end
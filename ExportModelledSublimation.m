% clear all
% close all

folder = 'U:\Storage Baptiste\Code\FirnModel_bv_v1.3\Output\THF study HD\Normal percol';
station = {'CP1', 'DYE-2', 'NASA-SE', 'Summit',...
     'NASA-E','NASA-U','SouthDome','TUNU-N','Saddle'};
 
%  folder = ['C:\Users\bava\OwnCloud_new\Code\FirnModel_bv_v1.3\' ...
%     'Output\RetMIP\Runs\KAN-U_0_SiCL_pr0.001_Ck1.00_darcy_wh0.10'];
% station = {'KAN_U'};

file_list = dir(folder);
file_list = {file_list.name};
for i = 1:length(station)
    IndexC = strfind(file_list,station{i});
    ind = find(not(cellfun('isempty',IndexC)));
    filename = [folder '\' file_list{ind} '\surf-bin-1.nc'];

    try time = ncread(filename,'Time');
    catch me 
        time = ncread(filename,'time');
        time = time + datenum(1900,1,1);
        dateVector = datevec(time);

        dateVector(:,2:end) = 0;
        dateYearBegin = datenum(dateVector);
        %Calculate the day of the year
        doyRow = time - dateYearBegin;

        %Set the date as the end of the year
        dateVector(:,1) = dateVector(:,1) + 1;
        dateYearEnd = datenum(dateVector);
        fracRow = (doyRow - 1) ./ (dateYearEnd - dateYearBegin);

        time = dateVector(:,1)- 1 + fracRow;
    end
    sublimation = ncread(filename,'sublimation');

    filename_out = sprintf(['C:/Users/bava/OwnCloud_new/Data/AWS/Input/' ...
        'Sublimation estimates/%s_sublimation.txt'],station{i});
    dlmwrite(filename_out,[time, sublimation],'Delimiter',';','precision',10)
end

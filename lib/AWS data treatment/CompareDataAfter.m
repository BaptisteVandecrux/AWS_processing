function [] = CompareDataAfter(station, Name, data, VarName1, data2, VarName2)
% This function compares the two datasets data and data_aux after adjustement
% of data_aux. On the time period where both datasets are available:
%      data_aux_scaled = (data_aux - mean(data_aux)) / var(data_aux) * var(data) + mean(data)
% data_aux_scaled then has the same mean and the same variance as data.
% Then data_aux_scaled and data are plotted against each other. This is just a
% plotting function. No modification is made.
if sum(strcmp(data2.Properties.VariableNames,VarName2))>0
    ind_common = ismember(data.time, data2.time);
    data1 = data(ind_common,:);
    ind_common = ismember(data2.time, data.time);
    data2 = data2(ind_common,:);
x = data1.(VarName1);
y = data2.(VarName2);

x_scaled = (x - nanmean(x)) / nanstd(x);
x_scaled(isnan(x)) = 0;
y_scaled = (y - nanmean(y)) / nanstd(y);
y_scaled(isnan(y)) = 0;

[acor, lag] = xcorr(x_scaled,y_scaled);

if find(lag(acor==max(acor))) ~= 0
    shift = lag(acor==max(acor));
    if shift >0
        data2.(VarName2)(shift+1:end) = data2.(VarName2)(1:end-shift);
    else
        data2.(VarName2)(1:end+shift) = data2.(VarName2)(-shift+1:end);
    end
end

time = data1.time;
    data_save = data2;
    mean1 = nanmean(data1.(VarName1));
    data3 = data2;
    data3.(VarName2)(isnan(data1.(VarName1))) = NaN;
%     var1 = nanvar(data1.(VarName1));
%     var2 = nanvar(data3.(VarName2));
    mean2 =  nanmean(data3.(VarName2));
%     data_scaled = (data2.(VarName2) - mean2)./var2.*var1 + mean1;

    time = datetime(datestr(data2.time));
    ind_1 = time==time; %ismember(time.Month,6:8);
    ind_2 = ~ind_1;
    lm_1=fitlm(data2.(VarName2)(ind_1), data1.(VarName1)(ind_1));
%     lm_2=fitlm(data2.(VarName2)(ind_2), data1.(VarName1)(ind_2));
    data3 = data2;
    data3.(VarName2)(isnan(data1.(VarName1))) = NaN;
    data_scaled = data2.(VarName2);
    data_scaled(ind_1) = data2.(VarName2)(ind_1)*lm_1.Coefficients.Estimate(2) + lm_1.Coefficients.Estimate(1);
%     data_scaled(ind_2) = data2.(VarName2)(ind_2)*lm_2.Coefficients.Estimate(2) + lm_2.Coefficients.Estimate(1);
        
    if strcmp(VarName1,'WindDirection1deg')||...
            strcmp(VarName1,'WindDirection2deg')
        data_scaled = (data2.(VarName2) - nanmean(data3.(VarName2)))...
            + nanmean(data1.(VarName1));
        data_scaled(data_scaled<0) = 360 + data_scaled(data_scaled<0);
        data_scaled(data_scaled>360) = data_scaled(data_scaled>360) - 360;
        fprintf('wind direction: not taking variance into account\n');
    end
    data2.(VarName2) = data_scaled;    
    if sum(~isnan(data2.(VarName2)))>10

    ind = and(~isnan(data1.(VarName1)),~isnan(data2.(VarName2)));
    lm_after = fitlm(data2.(VarName2)(ind), data1.(VarName1)(ind));
%     figure
%     plot(lm)
%     axis square
    plot(lm_after);
    hold on
    axis tight square
    box on
    ylimit = get(gca,'YLim');
    plot(ylimit,ylimit,'k');
    ylabel(sprintf('%s (%s)',VarName1,station))
    xlabel(Name)
    legend off
    title(sprintf('RMSE = %0.2f R^2 = %0.2f',...
        lm_after.RMSE   ,lm_after.Rsquared.Ordinary))
        end
end
end
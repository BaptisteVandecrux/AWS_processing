function [] = CompareData(station, sec_station, data, VarName1, data2, VarName2)
% This function only displays data.VarName1 vs data2.VarName2 as well as
% the best regression line between the two of them. Nothing is sent to
% output.
if sum(strcmp(data2.Properties.VariableNames,VarName2))>0
    ind_common = ismember(data.time, data2.time);
    data1 = data(ind_common,:);
    ind_common = ismember(data2.time, data.time);
    data2 = data2(ind_common,:);
    ind = and(~isnan(data1.(VarName1)),~isnan(data2.(VarName2)));
    if sum(~isnan(data2.(VarName2)(ind)))>10

        [fitted_line, gof] = fit(data1.(VarName1)(ind), data2.(VarName2)(ind),'poly1');
        plot(fitted_line,data1.(VarName1), data2.(VarName2));

        hold on
        axis tight
        box on
        ylimit = get(gca,'YLim');
        plot(ylimit,ylimit,'k');
        xlabel(sprintf('%s (%s)',VarName1, station))
        ylabel(sprintf('%s (%s)',VarName2, sec_station))
        legend off
        ME = nanmean(data1.(VarName1)-data2.(VarName2));
        RMSE = sqrt(nanmean((data1.(VarName1)-data2.(VarName2)).^2));
        title(sprintf('ME = %0.2f RMSE = %0.2f R^2 = %0.2f',ME,RMSE,gof.rsquare))
    else
        disp(VarName1)
        disp('Not enough points for regression')
    end
end
end
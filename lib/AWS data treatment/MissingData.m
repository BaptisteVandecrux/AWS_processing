function [ind_nan] = MissingData(ts)
% displays period when more than 1 month of data is missing
ind_nan = [];
fprintf('Period when more than one month of data is missing:\n\t %s\n',ts.Name)
    for i = 2:length(ts.Data)-1
        if isnan(ts.Data(i))
            if ~isnan(ts.Data(i-1))||(i-1==1)
                indstart =i;
            end
            if ~isnan(ts.Data(i+1))||(i+1==length(ts.Data))
                lengthnan = i-indstart;
                if lengthnan > 24*30
                    fprintf('Missing data from: %s to %s.\n',datestr(ts.Time(indstart)), datestr(ts.Time(i)));
                    ind_nan = [ind_nan; indstart, i];
                end
            end
        end
    end
end
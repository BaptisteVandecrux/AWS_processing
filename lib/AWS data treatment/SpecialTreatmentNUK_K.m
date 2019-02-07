function [data] = SpecialTreatmentNUK_K(data)
    data_JJA = AvgTableJJA(data,'nanmean');
    data_modified = data;
    year2015 = and(data.time>datenum(2015,1,1),...
        data.time <= datenum(2015,12,31));
    year2017 = and(data.time>datenum(2017,1,1),...
        data.time <= datenum(2017,12,31));
    k_2015 = 0.9504;
    k_2017 = 0.9768;

    data_modified.ShortwaveRadiationDownWm2(year2015) = k_2015 * data_modified.ShortwaveRadiationDownWm2(year2015);
    data_modified.ShortwaveRadiationDownWm2(year2017) = k_2017 * data_modified.ShortwaveRadiationDownWm2(year2017);
    data_modified_JJA = AvgTableJJA(data_modified,'nanmean');
    
    figure
    stairs([data_JJA.time; datenum('01-Jan-2018')],...
        [data_JJA.ShortwaveRadiationDownWm2; ...
        data_JJA.ShortwaveRadiationDownWm2(end)],'LineWidth',2)
    hold on
        stairs([data_modified_JJA.time; datenum('01-Jan-2018')],...
        [data_modified_JJA.ShortwaveRadiationDownWm2; ...
        data_modified_JJA.ShortwaveRadiationDownWm2(end)],'LineWidth',1.5)
    datetick('x','dd-mm-yyyy')
    legend('before', 'after adjustment')
    

end
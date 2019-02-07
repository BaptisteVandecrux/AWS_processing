function [H_ts] = HeightCorrection(H_ts, date_change, ...
     H_before, H_after, OutputFolder, tag)
% This function uses the measured height before and after maintenance and
% corrects the shift in surface height that is seen by the sonic rangers.
% It also prints in hthe command prompt a series of information like the
% comparison between the manual maesurement of instrument height during the
% maintenance and the reading of the sonic ranger at the same time stamp.

    filename = sprintf('%s/report_surface_height_%s.txt',OutputFolder,tag);
    fid = fopen(filename, 'a');
    fprintf( fid, 'date\t time\t Height_SR\t Height_report\t Deviation\n');
    shift_past = 0;
    for i=1:length(date_change)

        if ~isnan(H_before(i))
            H_SR_before = H_ts.Data(H_ts.Time < date_change(i));
            ind_before = find(~isnan(H_SR_before));

            if ~isempty(ind_before)
                fprintf( fid, '%s\t %s\t %0.2f\t %0.2f\t %0.2f\n',...
                    datestr(date_change(i)), 'before',...
                    round(100*H_SR_before(ind_before(end))) + 100 * shift_past, ...
                    round(H_before(i)),...
                    round(100*H_SR_before(ind_before(end))) + 100*shift_past - round(H_before(i)) );
            end
        end
        if ~isnan(H_after(i))
            H_SR_after = H_ts.Data(H_ts.Time > date_change(i));
            ind_after = find(~isnan(H_SR_after));        

            if ~isempty(ind_after)
                fprintf( fid, '%s\t %s\t %0.2f\t %0.2f\t %0.2f\n',...
                    datestr(date_change(i)), 'after',...
                    round(100*H_SR_after(ind_after(end))) + 100 * shift_past, ...
                    round(H_after(i)),...
                    round(100*H_SR_after(ind_after(end))) + 100*shift_past - round(H_after(i)) );
            end
        end

        if ~isnan(H_before(i)) &&  ~isnan(H_after(i))
            shift   = H_after(i)/100 - H_before(i)/100 ;
            H_ts.Data(H_ts.Time > date_change(i)) = H_ts.Data(H_ts.Time > date_change(i)) - shift;

            if abs(shift) >0
                fprintf('SR shifted by %i cm on %s\n', round(shift*100),datestr(date_change(i)))
            end
            shift_past = shift_past + shift;
        else
             shift   = 0;
        end
    end
    fclose( fid );
end
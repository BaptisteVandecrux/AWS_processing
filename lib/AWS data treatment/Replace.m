w = what;
mfiles = w.m; % get all the .m files

varnames = {'ELA' 'elev_AWS' 'elev_bins' 'elev_start' 'gradT' 'gradT_Tdep' ...
    'gradRH' 'gradWS' 'gradLRin' 'gradLRin_Tdep' 'gradsnowthick' 'gradTice' ...
    'H_T' 'H_WS' ...
    'snowthick_ini' 'T_ice_AWS' 'lat' 'lon'...
    'alb_ice' 'alb_snow' 'eps' 'es_0' 'es_100' 'ext_air' 'ext_air_cl' 'ext_ice' ...
    'ext_snow'  'gamma' 'kappa' 'L_sub' 'L_fus' 'L_vap' 'R_d' 'R_v' 'rho_ice' 'rho_snow' ...
    'rho_water' 'sigma' 'T_solidprecip' 'T_0' 'T_100' 'z0_ice' 'z0_snow'  ...
    'beta' 'c_pd' 'c_w' 'ch1' 'ch2' 'ch3' 'cq1' 'cq2' 'cq3' 'aa' 'bb' 'cc' 'dd'...
    'dev' 'dTsurf_ini' 'dz_ice' 'z_max' 'EB_max' 'iter_max_EB' 'iter_max_flux' ...
    'L_dif' 'prec_cutoff' 'prec_rate' 'RH_min' 'WS_lim' 'z_ice_max' 'dt_obs'...
    'smallno' 'nuw' 'whwice' 'kice' 'liqmax' 'icemax' 'zdifiz' 'do_no_darcy' ...
    'cro_1' 'cro_2' 'cro_3' 'rho_pco' 'a_rho' 'b_rho' 'c_rho' 'd_rho'...
    'dgrainNew' 'rh2oice' 'delta_time' 'cdel' 'jpgrnd' 'cmid' 'zdtime'};
for kk=1:length(varnames)
    for ii= 1:length(mfiles)
        if ~strcmp(mfiles{ii},'Replace.m')
            
            l = textread(mfiles{ii},'%s', 'delimiter', '\n');
            l = regexprep(l, varnames{kk}, sprintf('c.%s',varnames{kk}));
            % note this will overwrite the original file
            fid=fopen(mfiles{ii}, 'wt');
            for jj=1:length(l)
                fprintf (fid, '%s\n', l{jj});
            end
            fclose (fid);
        end
    end
end

w = what;
mfiles = w.m; % get all the .m files

for kk=1:length(varnames)
    for ii= 1:length(mfiles)
        if ~strcmp(mfiles{ii},'Replace.m')
            l = textread(mfiles{ii},'%s', 'delimiter', '\n');
            l = regexprep(l, 'c\.c\.', 'c\.');
            l = regexprep(l, 'rc\.cdel', 'c\.rcdel');
            % note this will overwrite the original file
            fid=fopen(mfiles{ii}, 'wt');
            for jj=1:length(l)
                fprintf (fid, '%s\n', l{jj});
            end
            fclose (fid);
        end
    end
end

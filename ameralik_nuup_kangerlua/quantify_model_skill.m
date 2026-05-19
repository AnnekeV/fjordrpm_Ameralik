%% isopycnal_skill.m
% Calculates isopycnal depths for observations and multiple simulations,
% then computes RMSE, bias, phase offset, and correlation.
close all
folder_fig = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/quantify_model_perfomance';

%% -----------------------------------------------------------------------
%  LOAD DATA
% -----------------------------------------------------------------------
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
load(fullfile(saveFolder,'Ameralik_mean_daily.mat'));

sims = {
    load('ameralik_combined_Kb1e-05_C01e+05.mat',     's').s,
    load('ameralik_combined_Kb1e-04_C01e+05.mat',     's').s,
    load('ameralik_combined_Kb1e-03_C01e+05.mat',     's').s,
};
simNames = {
    'Low mix - High shelfX',
    'High mix - High shelfX',
    'Very high mix - High ShelfX',
};

sims = {
        load('ameralik_combined_Kb1e-05_C01e+05.mat',     's').s,
    load('ameralik_combined_Kb1e-04_C01e+05.mat', 's').s, 
    load('ameralik_combined_Kb1e-04_C01e+05_no_air_sea.mat', 's').s,
    load('ameralik_combined_Kb1e-04_C01e+05_runoff.mat', 's').s,
    load('ameralik_combined_Kb1e-03_C01e+05.mat', 's').s,
    load('ameralik_combined_Kb1e-03_C01e+05_no_air_sea.mat', 's').s,
     load('ameralik_combined_Kb1e-03_C01e+05_no_runoff.mat', 's').s,
         load('ameralik_combined_Kb1e-03_C01e+04.mat', 's').s, 

   };
simNames = {
        'Low mix - High shelfX',
    'High mix - High shelfX',
     'High mix - High ShelfX - No Air-Sea Heat Flux',
      'High mix - High ShelfX - No Runoff',
    'Very high mix - High ShelfX',
        'Very high mix - High ShelfX - No Air-Sea Heat Flux',
      'Very high mix - High ShelfX - No Runoff',
      'Very high mix - Low ShelfX',


    };


%% -----------------------------------------------------------------------
%  SETTINGS
% -----------------------------------------------------------------------
target_isopycnals = [1026.6, 1026.7];
max_lag_days      = 90;


colors_ameralik;

%% -----------------------------------------------------------------------
%  STEP 1: extract isopycnal depths from OBSERVATIONS
% -----------------------------------------------------------------------
validMask = ~all(isnan(AM5.rho), 1);
obs_rho   = AM5.rho(:, validMask);
obs_z     = abs(AM5.depths(:));

raw_dates = AM5.dates(validMask);
if isdatetime(raw_dates)
    obs_dates = datenum(raw_dates(:)');
else
    obs_dates = double(raw_dates(:)');
end

nObs = numel(obs_dates);
nIso = numel(target_isopycnals);

obs_iso_depth = NaN(nIso, nObs);
for ii = 1:nIso
    obs_iso_depth(ii,:) = get_isopycnal_depth(obs_rho, obs_z, target_isopycnals(ii));
end

%% -----------------------------------------------------------------------
%  STEP 2: extract isopycnal depths from each SIMULATION at obs times
% -----------------------------------------------------------------------
nSims = numel(sims);
sim_iso_depth = NaN(nIso, nObs, nSims);

for sIdx = 1:nSims
    s = sims{sIdx};
    if isdatetime(s.t)
        mod_t = datenum(s.t(:)');
    else
        mod_t = double(s.t(:)');
    end
    mod_z   = abs(s.z(:));
    mod_rho = s.rho;

    mod_rho_at_obs = NaN(numel(mod_z), nObs);
    for k = 1:nObs
        if obs_dates(k) < mod_t(1) || obs_dates(k) > mod_t(end), continue; end
        col = interp1(mod_t, mod_rho', obs_dates(k), 'linear')';
        if sum(isfinite(col)) >= 2
            mod_rho_at_obs(:,k) = col;
        end
    end

    for ii = 1:nIso
        sim_iso_depth(ii,:,sIdx) = get_isopycnal_depth(mod_rho_at_obs, mod_z, target_isopycnals(ii));
    end
end

%% -----------------------------------------------------------------------
%  STEP 3: compute metrics  (time-weighted, Ralston et al. 2010)
%  Skill score removed.
% -----------------------------------------------------------------------
metrics = struct();
metrics.isopycnals = target_isopycnals;
metrics.simNames   = simNames;
metrics.rmse       = NaN(nIso, nSims);
metrics.bias       = NaN(nIso, nSims);
metrics.phase_days = NaN(nIso, nSims);
metrics.corr       = NaN(nIso, nSims);
metrics.pval       = NaN(nIso, nSims);

for ii = 1:nIso
    obs_d = obs_iso_depth(ii,:);

    for sIdx = 1:nSims
        mod_d = sim_iso_depth(ii,:,sIdx);

        ok = isfinite(obs_d) & isfinite(mod_d);
        if sum(ok) < 3, continue; end

        o    = obs_d(ok)';
        m    = mod_d(ok)';
        t_ok = obs_dates(ok)';

        % Time-based weights (Ralston et al. 2010)
        if numel(unique(t_ok)) < 2
            w = ones(numel(o),1) / numel(o);
        else
            dt = diff(t_ok(:));
            w  = zeros(numel(o),1);
            w(1)       = dt(1);
            w(end)     = dt(end);
            w(2:end-1) = dt(1:end-1) + dt(2:end);
            w = 0.5 * w;
            w = w / sum(w);
        end

        % Weighted mean of obs
        o_bar = sum(w .* o);

        % Weighted RMSE and bias
        metrics.rmse(ii,sIdx) = sqrt(sum(w .* (m - o).^2));
        metrics.bias(ii,sIdx) = sum(w .* (m - o));

        % Weighted correlation (Santer et al. 2000)
        cov_mo  = sum(w .* (m - sum(w.*m)) .* (o - o_bar));
        std_m_w = sqrt(sum(w .* (m - sum(w.*m)).^2));
        std_o_w = sqrt(sum(w .* (o - o_bar).^2));
        metrics.corr(ii,sIdx) = cov_mo / (std_m_w * std_o_w);

        % p-value: use standard corrcoef as approximation
        [rv, pv] = corrcoef(o, m);
        metrics.pval(ii,sIdx) = pv(1,2);

        % Phase offset on regularly resampled series
        dt_med = median(diff(t_ok));
        t_reg  = (t_ok(1) : dt_med : t_ok(end))';
        o_reg  = interp1(t_ok, o, t_reg, 'linear', NaN);
        m_reg  = interp1(t_ok, m, t_reg, 'linear', NaN);
        ok2    = isfinite(o_reg) & isfinite(m_reg);
        if sum(ok2) > 4
            metrics.phase_days(ii,sIdx) = get_phase_offset( ...
                o_reg(ok2), m_reg(ok2), t_reg(ok2), max_lag_days);
        end
    end
end

%% -----------------------------------------------------------------------
%  STEP 4: print summary table
% -----------------------------------------------------------------------
fprintf('\n=== ISOPYCNAL SKILL METRICS ===\n');
for ii = 1:nIso
    fprintf('\n--- sigma0 = %.2f ---\n', target_isopycnals(ii));
    fprintf('%-35s  %8s  %8s  %8s  %8s  %8s\n', ...
            'Simulation','RMSE(m)','Bias(m)','Phase(d)','r','p-value');
    for sIdx = 1:nSims
        fprintf('%-35s  %8.1f  %8.1f  %8.0f  %8.3f  %8.3f\n', ...
            simNames{sIdx}, ...
            metrics.rmse(ii,sIdx), ...
            metrics.bias(ii,sIdx), ...
            metrics.phase_days(ii,sIdx), ...
            metrics.corr(ii,sIdx), ...
            metrics.pval(ii,sIdx));
    end
end

%% -----------------------------------------------------------------------
%  STEP 5: PLOT 1 — isopycnal depth time series
% -----------------------------------------------------------------------
% fig1 = plotIsopycnalTimeseries(obs_dates, obs_iso_depth, ...
%                                sim_iso_depth, simNames, target_isopycnals, metrics, simColors);
% saveas(fig1, fullfile(folder_fig, 'isopycnal_timeseries.png'));

% -----------------------------------------------------------------------
 % STEP 6: PLOT 2 — metric summary (4 panels, no skill)
% -----------------------------------------------------------------------
% fig2 = plotMetricSummary(metrics, simColors);
% saveas(fig2, fullfile(folder_fig, 'metrics.png'));
%% -----------------------------------------------------------------------
%  STEP 7: PLOT 3 — Taylor diagram for rho, T, and S
% -----------------------------------------------------------------------

% Change the depth over which you compare
depth_min = 0; depth_max = 700;

t_daily = (floor(min(obs_dates)) : 1 : ceil(max(obs_dates)))';
nDays   = numel(t_daily);

% Define variables to loop over
varList = {
    struct('obsData', AM5.rho,    'simField', 'rho', 'label', '\rho',          'units', 'kg m^{-3}'), ...
    struct('obsData', AM5.T,      'simField', 'T',   'label', 'Temperature',   'units', '°C'), ...
    struct('obsData', AM5.S,      'simField', 'S',   'label', 'Salinity',      'units', 'psu'), ...
};
nVars = numel(varList);

for vIdx = 1:nVars
    vInfo    = varList{vIdx};
    obs_raw  = vInfo.obsData;   % [nz_obs x nObs]

    % Mask depth levels outside [depth_min depth_max]
    depth_mask = obs_z >= depth_min & obs_z <= depth_max;

    % --- Interpolate OBS to daily timesteps ---
    nz_obs        = size(obs_raw, 1);
    obs_daily     = NaN(nz_obs, nDays);
    for iz = 1:nz_obs
        row = obs_raw(iz,:);
        ok  = isfinite(row);
        if sum(ok) < 2, continue; end
        obs_daily(iz,:) = interp1(obs_dates(ok), row(ok), t_daily, 'linear', NaN);
    end

    obs_daily_masked = obs_daily;
    obs_daily_masked(~depth_mask, :) = NaN;

    % --- Loop over simulations ---
    taylor_var = struct();
    for sIdx = 1:nSims
        s = sims{sIdx};
        if isdatetime(s.t)
            mod_t = datenum(s.t(:)');
        else
            mod_t = double(s.t(:)');
        end
        mod_z   = abs(s.z(:));
        nz_mod  = numel(mod_z);

        % Check that field exists
        if ~isfield(s, vInfo.simField)
            warning('Sim %d missing field "%s" — skipping', sIdx, vInfo.simField);
            taylor_var(sIdx).std_obs = NaN;
            taylor_var(sIdx).std_mod = NaN;
            taylor_var(sIdx).corr    = NaN;
            taylor_var(sIdx).pvalue  = NaN;
            taylor_var(sIdx).label   = simNames{sIdx};
            continue
        end
        mod_data = s.(vInfo.simField);   % [nz_mod x nT_mod]

        mod_depth_mask = mod_z >= depth_min & mod_z <= depth_max;

        % Interpolate model to daily timesteps
        mod_daily = NaN(nz_mod, nDays);
        for iz = 1:nz_mod
            row = mod_data(iz,:);
            ok  = isfinite(row);
            if sum(ok) < 2, continue; end
            mod_daily(iz,:) = interp1(mod_t, row(ok), t_daily, 'linear', NaN);
        end
        mod_daily(~mod_depth_mask, :) = NaN;

        % Interpolate model onto obs depth grid
        mod_on_obs_z = NaN(nz_obs, nDays);
        for k = 1:nDays
            col = mod_daily(:,k);
            ok  = isfinite(col) & mod_depth_mask;
            if sum(ok) < 2, continue; end
            in_range = obs_z >= min(mod_z(ok)) & obs_z <= max(mod_z(ok)) & depth_mask;
            if sum(in_range) < 1, continue; end
            mod_on_obs_z(in_range,k) = interp1(mod_z(ok), col(ok), obs_z(in_range), 'linear', NaN);
        end

        % Flatten and compute Taylor statistics
        ov = obs_daily_masked(:);
        mv = mod_on_obs_z(:);
        ok = isfinite(ov) & isfinite(mv);

        if sum(ok) < 10
            warning('Sim %d, var %s: fewer than 10 valid pairs', sIdx, vInfo.simField);
            taylor_var(sIdx).std_obs = NaN;
            taylor_var(sIdx).std_mod = NaN;
            taylor_var(sIdx).corr    = NaN;
            taylor_var(sIdx).pvalue  = NaN;
        else
            taylor_var(sIdx).std_obs = std(ov(ok));
            taylor_var(sIdx).std_mod = std(mv(ok));
            [c, pval]                = corrcoef(ov(ok), mv(ok));
            taylor_var(sIdx).corr    = c(1,2);
            taylor_var(sIdx).pvalue  = pval(1,2);
        end
        taylor_var(sIdx).label = simNames{sIdx};
    end

    % Plot Taylor diagram for this variable
    titleStr = sprintf('%s  |  %d–%d m', vInfo.label, depth_min, depth_max);
    fig_taylor = plotTaylorDiagram(taylor_var, titleStr, simColors);

    % Update axis labels with correct units
    ax_t = findobj(fig_taylor, 'Type', 'axes');
    xlabel(ax_t, ['Standard deviation (' vInfo.units ')'], 'FontSize',9,'FontName','Helvetica');
    ylabel(ax_t, ['Standard deviation (' vInfo.units ')'], 'FontSize',9,'FontName','Helvetica');

    % saveas(fig_taylor, fullfile(folder_fig, ...
    %     sprintf('taylor_%s_%d_%dm.png', vInfo.simField, depth_min, depth_max)));
end

%% -----------------------------------------------------------------------
%  STEP 8: PLOT 4 — depth-time plots (absolute + difference)
% -----------------------------------------------------------------------

% Build sim_data arrays [nz_sim x nT_sim x nSims]
% All sims share the same z/t grid (first sim used as reference)
s_ref  = sims{1};
sim_z  = abs(s_ref.z(:));
if isdatetime(s_ref.t);  sim_dates = datenum(s_ref.t(:)');
else;                     sim_dates = double(s_ref.t(:)');
end
nz_sim = numel(sim_z);
nT_sim = numel(sim_dates);

% Loop over T, S, rho
depthVarList = {
    struct('obsData',AM5.rho, 'simField','rho', 'label','Density',     'units','kg m^{-3}', 'cmap','dense',   'dcmap','balance', 'clim',[], 'dclim',[]), ...
    struct('obsData',AM5.T,   'simField','T',   'label','Temperature', 'units','°C',         'cmap','thermal', 'dcmap','balance', 'clim',[], 'dclim',[]), ...
    struct('obsData',AM5.S,   'simField','S',   'label','Salinity',    'units','psu',         'cmap','haline',  'dcmap','curl',    'clim',[], 'dclim',[]), ...
};

for vIdx = 1:numel(depthVarList)
    vInfo = depthVarList{vIdx};

    % Stack sim data into [nz x nT x nSims]
    sim_data_3d = NaN(nz_sim, nT_sim, nSims);
    for sIdx = 1:nSims
        s = sims{sIdx};
        if isfield(s, vInfo.simField)
            sim_data_3d(:,:,sIdx) = s.(vInfo.simField);
        else
            warning('Sim %d missing field "%s"', sIdx, vInfo.simField);
        end
    end

    [figDT1, figDT2] = plotDepthTime(obs_dates, obs_z, vInfo.obsData, ...
                                      sim_dates, sim_z, sim_data_3d, ...
                                      simNames, vInfo);

    exportgraphics(figDT1, fullfile(folder_fig, sprintf('depthtime_%s_abs.png',  vInfo.simField)), 'Resolution',300);
    exportgraphics(figDT2, fullfile(folder_fig, sprintf('depthtime_%s_diff.png', vInfo.simField)), 'Resolution',300);
end

%% =======================================================================
%  LOCAL FUNCTIONS
% =======================================================================

% -----------------------------------------------------------------------
function iso_depth = get_isopycnal_depth(rho_matrix, depths_pos, sigma0)
    nt = size(rho_matrix, 2);
    iso_depth = NaN(1, nt);
    for k = 1:nt
        col   = rho_matrix(:,k);
        ok    = isfinite(col);
        if sum(ok) < 2, continue; end
        z_v   = depths_pos(ok);
        rho_v = col(ok);
        if sigma0 <= min(rho_v) || sigma0 >= max(rho_v), continue; end
        idx = find(rho_v >= sigma0, 1, 'first');
        if isempty(idx) || idx == 1, continue; end
        frac = (sigma0 - rho_v(idx-1)) / (rho_v(idx) - rho_v(idx-1));
        iso_depth(k) = z_v(idx-1) + frac*(z_v(idx) - z_v(idx-1));
    end
end

% -----------------------------------------------------------------------
function phase_days = get_phase_offset(obs_ts, mod_ts, time_vec, max_lag_days)
    o  = detrend(obs_ts(:));
    m  = detrend(mod_ts(:));
    dt = median(diff(time_vec(:)));
    max_steps = min(round(max_lag_days/dt), numel(o)-1);
    if max_steps < 1, phase_days = NaN; return; end
    [xc, lags] = xcorr(m, o, max_steps, 'coeff');
    [~, imax]  = max(xc);
    phase_days  = lags(imax) * dt;
end

% -----------------------------------------------------------------------
function rho_ref = interp_profiles_to_grid(rho_matrix, depths_pos, ref_grid)
    nref = numel(ref_grid);
    nt   = size(rho_matrix, 2);
    rho_ref = NaN(nref, nt);
    for k = 1:nt
        col = rho_matrix(:,k);
        ok  = isfinite(col);
        if sum(ok) < 3, continue; end
        z_v = depths_pos(ok);  c_v = col(ok);
        inr = ref_grid >= min(z_v) & ref_grid <= max(z_v);
        if sum(inr) < 1, continue; end
        rho_ref(inr,k) = interp1(z_v, c_v, ref_grid(inr), 'pchip');
    end
end

% -----------------------------------------------------------------------
function fig = plotIsopycnalTimeseries(obs_dates, obs_iso_depth, ...
                                       sim_iso_depth, simNames, isopycnals, metrics, simColors)

    nIso  = numel(isopycnals);
    nSims = numel(simNames);
    lStyles = {'-','--','-.',':'};

    fig = figure('Name','Isopycnal depth timeseries', ...
                 'Units','centimeters','Position',[2 2 18 14]);
    tl = tiledlayout(nIso, 1, 'TileSpacing','compact', 'Padding','compact');

    axList = gobjects(nIso,1);
    dt_obs = datetime(obs_dates, 'ConvertFrom','datenum');

    for ii = 1:nIso
        ax = nexttile(tl);
        hold(ax,'on');
        axList(ii) = ax;

        % ---- Observations -----------------------------------------------
        plot(ax, dt_obs, obs_iso_depth(ii,:), 'o-', ...
             'Color',[0.15 0.15 0.15], 'MarkerFaceColor',[0.15 0.15 0.15], ...
             'MarkerSize',3, 'LineWidth',1.0, 'DisplayName','Observations');

        % ---- Simulations ------------------------------------------------
        for sIdx_normal = 1:nSims
            sIdx  = nSims+1-sIdx_normal;
            mod_d = squeeze(sim_iso_depth(ii,:,sIdx));
            ls    = lStyles{mod(sIdx-1, numel(lStyles))+1};
            lbl   = simNames{sIdx};
            if isKey(simColors, lbl);  c = simColors(lbl);
            else;                      c = [0.5 0.5 0.5];  warning('No color for "%s"', lbl);
            end
            plot(ax, dt_obs, mod_d, ls, 'Color',c, 'LineWidth',1.6, 'DisplayName',lbl);
        end

        % % ---- Metric annotations -----------------------------------------
        % ypos_start = 0.21;  dy = 0.05;
        % for sIdx = 1:nSims
        %     rmse_v = metrics.rmse(ii,sIdx);
        %     bias_v = metrics.bias(ii,sIdx);
        %     ph_v   = metrics.phase_days(ii,sIdx);
        %     r_v    = metrics.corr(ii,sIdx);
        %     p_v    = metrics.pval(ii,sIdx);
        %     p_str  = char(string(p_v<0.001)*"p<0.001" + string(p_v>=0.001)*sprintf("p=%.3f",p_v));
        % 
        %     ann = sprintf('RMSE=%0.0fm,  Bias=%+0.0fm,  Offset=%+0.0fd,  r=%.2f (%s)', ...
        %                    rmse_v, bias_v, ph_v, r_v, p_str);
        % 
        %     lbl = simNames{sIdx};
        %     if isKey(simColors, lbl);  c = simColors(lbl);  else;  c = [0.5 0.5 0.5];  end
        %     text(ax, 0.02, ypos_start - sIdx*dy, ann, 'Units','normalized', ...
        %          'FontSize',7, 'FontName','Helvetica', 'Color',c, ...
        %          'VerticalAlignment','top', 'Interpreter','none');
        % end

        % ---- Axes style -------------------------------------------------
        set(ax, 'YDir','reverse', 'FontName','Helvetica', 'FontSize',9, ...
            'TickDir','out', 'TickLength',[0.012 0.012], 'LineWidth',0.8, ...
            'Box','off', 'XGrid','off', 'YGrid','on', 'GridAlpha',0.18, ...
            'GridColor',[0.4 0.4 0.4], 'GridLineStyle',':');

        panelLabels = {'(a)','(b)','(c)','(d)'};
        text(ax, 0.015, 0.97, panelLabels{ii}, 'Units','normalized', ...
             'FontSize',10, 'FontWeight','bold', 'FontName','Helvetica', 'VerticalAlignment','top');

        text(ax, 0.995, 0.97, sprintf('\\rho = %.1f kg m^{-3}', isopycnals(ii)), ...
             'Units','normalized', 'HorizontalAlignment','right', 'VerticalAlignment','top', ...
             'FontSize',9, 'FontName','Helvetica', 'Color',[0.3 0.3 0.3]);

        ylabel(ax, 'Depth (m)', 'FontSize',9, 'FontName','Helvetica');
        xlim(ax, [datetime(2018,1,1) datetime(2020,1,1)]);

        if ii < nIso;  ax.XTickLabel = [];
        else;          ax.XAxis.TickLabelFormat = 'MMM yyyy';
        end
    end

    set(axList(1), 'YLim',[-50  450]);
    set(axList(2), 'YLim',[200  700]);
    linkaxes(axList,'x');

    lg = legend(axList(1), 'Location','north', 'Orientation','vertical', ...
                'FontSize',7.5, 'FontName','Helvetica', 'Box','off', 'NumColumns',1);
    lg.ItemTokenSize = [18 9];
end

% -----------------------------------------------------------------------
function fig = plotMetricSummary(metrics, simColors)

    nIso  = numel(metrics.isopycnals);
    nSims = numel(metrics.simNames);

    rho_labels = arrayfun(@(x) sprintf('%.1f',x), metrics.isopycnals, 'UniformOutput',false);

    mNames   = {'RMSE (m)', 'Bias (m)', 'Correlation coefficient'};
    mData    = {metrics.rmse, metrics.bias, metrics.corr};
    refLines = {[], 0, 0, 0};
    mNotes   = {'', '+ve = model too deep',  ''};

    fig = figure('Name','Metric summary', 'Units','centimeters','Position',[1 1 18 5]);
    tl  = tiledlayout(1, 3, 'TileSpacing','compact', 'Padding','compact');

    panelLabels = {'(c)','(d)','(e)','(f)'};

    for m = 1:3
        ax = nexttile(tl);
        hold(ax,'on');

        data      = mData{m};
        data_plot = data;  nan_mask = isnan(data);  data_plot(nan_mask) = 0;

        b = bar(ax, data_plot, 'grouped', 'EdgeColor','none');
        for sIdx = 1:nSims
            lbl = metrics.simNames{sIdx};
            if isKey(simColors, lbl);  c = simColors(lbl);  else;  c = [0.5 0.5 0.5];  end
            b(sIdx).FaceColor   = c;
            b(sIdx).FaceAlpha   = 0.88;
            b(sIdx).DisplayName = lbl;
            if all(nan_mask(:,sIdx));  b(sIdx).FaceAlpha = 0;  end
        end

        % Significance stars on correlation panel
        if m == 3 && isfield(metrics,'pval')
            groupW = 0.8;  barW = groupW/nSims;
            for sIdx = 1:nSims
                for ii = 1:nIso
                    if isnan(metrics.corr(ii,sIdx)), continue; end
                    xc = ii - groupW/2 + barW*(sIdx-0.5);
                    yc = metrics.corr(ii,sIdx);
                    p  = metrics.pval(ii,sIdx);
                    if p<0.001; star='***'; elseif p<0.01; star='**'; elseif p<0.05; star='*'; else; star='ns'; end
                    text(ax, xc, yc+sign(yc)*0.04, star, 'HorizontalAlignment','center', ...
                         'FontSize',7, 'FontName','Helvetica', 'Color',[0.2 0.2 0.2]);
                end
            end
        end

        if ~isempty(refLines{m});  yline(ax, refLines{m}, 'k--', 'LineWidth',1.0, 'HandleVisibility','off');  end

        if ~isempty(mNotes{m})
            text(ax, 0.5, 0.98, mNotes{m}, 'Units','normalized', 'HorizontalAlignment','center', ...
                 'VerticalAlignment','top', 'FontSize',7, 'FontName','Helvetica', ...
                 'Color',[0.45 0.45 0.45], 'Interpreter','none');
        end

        set(ax, 'XTick',1:nIso, 'XTickLabel',rho_labels, 'FontSize',9, 'FontName','Helvetica', ...
            'TickDir','out', 'Box','off', 'LineWidth',0.8, 'YGrid','on', ...
            'GridAlpha',0.18, 'GridLineStyle',':');

        xlabel(ax, '\rho  (kg m^{-3})', 'FontSize',9, 'FontName','Helvetica');
        ylabel(ax, mNames{m},              'FontSize',9, 'FontName','Helvetica');

        text(ax, 0.02, 0.97, panelLabels{m}, 'Units','normalized', 'FontSize',10, ...
             'FontWeight','bold', 'FontName','Helvetica', 'VerticalAlignment','top');
    end
end
% -----------------------------------------------------------------------
function fig = plotTaylorDiagram(taylor, titleStr, simColors)
% Publication-ready Taylor diagram.
% Full RMSE circles (not arcs). Axes start at 0. No significance note text.

    nSims   = numel(taylor);
    std_obs = taylor(1).std_obs;

    all_stds = [taylor.std_mod];
    max_std  = max(1.5*std_obs, max(all_stds(isfinite(all_stds)))*1.1);

    % Full circle parametrisation (0 to 2pi, clipped to first quadrant in plot)
    theta_full = linspace(0, 2*pi, 500);
    theta_arc  = linspace(0, pi/2,  400);

    clr = [0.00 0.45 0.70;
           0.84 0.37 0.00;
           0.00 0.62 0.45;
           0.94 0.89 0.26;
           0.50 0.50 0.50];
    if nSims > size(clr,1)
        clr = [clr; lines(nSims - size(clr,1))];
    end
    markers = {'o','s','^','d','v','p','h'};

    fig = figure('Name',sprintf('Taylor – %s', titleStr), ...
                 'Units','centimeters','Position',[3 3 14 13]);
    ax = axes('Parent',fig);
    hold(ax,'on');

    % ---- RMSE contours: full circles centred on obs point ---------------
    % Draw the full circle, then rely on axis clipping to hide x<0, y<0
    rmse_levels = std_obs * [0.25 0.50 0.75 1.00 1.25];
    for rc = rmse_levels
        xc_full = std_obs + rc*cos(theta_full);
        yc_full =           rc*sin(theta_full);
        plot(ax, xc_full, yc_full, '-', ...
             'Color',[0.75 0.75 0.75],'LineWidth',0.7,'HandleVisibility','off');
        % Label at rightmost visible point (y~0, x>0)
        text(ax, std_obs + rc, -max_std*0.04, sprintf('%.2g',rc), ...
             'FontSize',7,'Color',[0.6 0.6 0.6],'HorizontalAlignment','center', ...
             'FontName','Helvetica');
    end
    text(ax, std_obs + max(rmse_levels)*0.5, -max_std*0.09, 'RMSE', ...
         'FontSize',7,'Color',[0.6 0.6 0.6],'FontName','Helvetica', ...
         'HorizontalAlignment','center');

    % ---- Correlation radial lines ---------------------------------------
    corr_ticks = [0.5 0.6 0.7 0.8 0.9 0.95 0.99];
    for cv = corr_ticks
        ang = acos(cv);
        plot(ax, [0, max_std*cos(ang)], [0, max_std*sin(ang)], ...
             ':', 'Color',[0.55 0.55 0.55],'LineWidth',0.7,'HandleVisibility','off');
        r_lbl = max_std * 1.06;
        text(ax, r_lbl*cos(ang), r_lbl*sin(ang), sprintf('%.2f',cv), ...
             'FontSize',7,'Color',[0.35 0.35 0.35],'HorizontalAlignment','center', ...
             'FontName','Helvetica','Rotation', rad2deg(ang)-90);
    end
    text(ax, max_std*cos(pi/6)*1.15, max_std*sin(pi/6)*1.15, 'Correlation', ...
         'FontSize',8,'Color',[0.3 0.3 0.3],'HorizontalAlignment','center', ...
         'FontName','Helvetica','Rotation',-60);

    % ---- Outer arc ------------------------------------------------------
    plot(ax, max_std*cos(theta_arc), max_std*sin(theta_arc), ...
         'k-','LineWidth',0.6,'HandleVisibility','off');

    % ---- Std reference circles from origin ------------------------------
    for sc = linspace(0, max_std, 5)
        if sc == 0, continue; end
        plot(ax, sc*cos(theta_arc), sc*sin(theta_arc), ...
             '-','Color',[0.88 0.88 0.88],'LineWidth',0.5,'HandleVisibility','off');
    end

    % ---- Observation reference ------------------------------------------
    plot(ax, std_obs, 0, 'kp', ...
         'MarkerSize',13,'MarkerFaceColor','k','DisplayName','Observations');

   % ---- Model points ---------------------------------------------------
    for sIdx = 1:nSims
        std_m  = taylor(sIdx).std_mod;
        corr_m = taylor(sIdx).corr;
        if ~isfinite(std_m) || ~isfinite(corr_m), continue; end
        ang = acos(max(-1,min(1,corr_m)));
        xp  = std_m*cos(ang);
        yp  = std_m*sin(ang);
        mk  = markers{mod(sIdx-1,numel(markers))+1};

        % Look up color from map, fall back to grey if name not found
        lbl = taylor(sIdx).label;
        if isKey(simColors, lbl)
            c = simColors(lbl);
        else
            c = [0.5 0.5 0.5];
            warning('No color defined for sim "%s" — using grey', lbl);
        end

        if isfield(taylor,'pvalue') && isfinite(taylor(sIdx).pvalue) ...
                                    && taylor(sIdx).pvalue >= 0.01
            mfc = 'none';
        else
            mfc = c;
        end

        plot(ax, xp, yp, mk, 'Color',c, 'MarkerFaceColor',mfc, ...
             'MarkerSize',9, 'LineWidth',1.2, 'DisplayName',lbl);
    end

    % ---- Axes -----------------------------------------------------------
    set(ax, ...
        'FontName','Helvetica','FontSize',9, ...
        'TickDir','out','LineWidth',0.8, ...
        'Box','off','XGrid','off','YGrid','off');

    % Start axes at 0
    xlim(ax, [0  max_std*1.15]);
    ylim(ax, [0  max_std*1.15]);
    axis(ax,'equal');
    % Clip so full circles are shown but axes start at 0
    ax.XLim(1) = 0;
    ax.YLim(1) = 0;

    xlabel(ax,'Standard deviation (kg m^{-3})','FontSize',9,'FontName','Helvetica');
    ylabel(ax,'Standard deviation (kg m^{-3})','FontSize',9,'FontName','Helvetica');

    text(ax, 0.03, 0.97, titleStr, ...
         'Units','normalized','FontSize',9,'FontWeight','bold', ...
         'FontName','Helvetica','VerticalAlignment','top');

    lg = legend(ax,'Location','northeast','FontSize',7.5,'FontName','Helvetica','Box','on');
    lg.ItemTokenSize = [12 9];
end
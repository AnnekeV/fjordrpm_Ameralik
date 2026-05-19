%% =========================================================
%  MAIN SCRIPT
%  Loads data, computes FW timeseries, statistics, and plots
% Fig 9 in Manuscript on sensitivity
% 19 May 2025
%% =========================================================

% --- Load Observational data -----------------------------------------------------------
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
% load(fullfile(saveFolder,'Ameralik_mean_daily.mat'));

% --- Simulations ---------------------------------------------------------
sims = {
    load('ameralik_combined_Kb1e-05_C01e+05.mat',          's').s,
    load('ameralik_combined_Kb1e-04_C01e+05.mat',          's').s,
    load('ameralik_combined_Kb1e-04_C01e+05_no_air_sea.mat','s').s,
    load('ameralik_combined_Kb1e-04_C01e+05_runoff.mat',   's').s,
    load('ameralik_combined_Kb1e-03_C01e+05.mat',          's').s,
    load('ameralik_combined_Kb1e-03_C01e+05_no_air_sea.mat','s').s,
    load('ameralik_combined_Kb1e-03_C01e+05_no_runoff.mat','s').s,
    load('ameralik_combined_Kb1e-04_C01e+04.mat',          's').s,
    load('ameralik_combined_Kb1e-03_C01e+04.mat',          's').s,
};

simNames = {
    'Low mix - High Shelf Exchange',
    'High mix - High Shelf Exchange',
    'High mix - High Shelf Exchange - No Air-Sea Heat Flux',
    'High mix - High Shelf Exchange - No Runoff',
    'Very high mix - High Shelf Exchange',
    'Very high mix - High Shelf Exchange - No Air-Sea Heat Flux',
    'Very high mix - High Shelf Exchange - No Runoff',
    'High mix - Low Shelf Exchange',
    'Very high mix - Low Shelf Exchange',
};

% --- Settings ------------------------------------------------------------
depth_ranges = [
      0   5;
      5  50;
     50 200;
    200 500;
];
Sref          = 33.4;
folder_fig    = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/';
saveFolder_ts = fullfile(folder_fig, 'comparison_obs_model_timeseries');
saveFolder_skill_metric = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/quantify_model_perfomance';

% --- Step 1: compute all FW timeseries: interpolate daily -----------------------------------
fw = computeFWtimeseries(AM5, sims, simNames, Sref, depth_ranges);
metrics = computeFWmetrics(fw);

% --- Step 2: plot timeseries as bar plots --------------------------------
close all;
fig = plotFWtimeseries(fw, metrics, depth_ranges);

% --- Step 3: metrics figures (tiled, grouped bars) -----------------------
figM    = plotFWmetricsTiled(metrics);
 % Save figure as PDF
savePath = fullfile(saveFolder_skill_metric, 'FW_skill_metrics.pdf');
% exportgraphics(figM, savePath, 'ContentType', 'vector');
% print(figM, savePath, '-dpdf', '-vector', '-r0');
% fprintf('Figure saved to: %s\n', savePath);
% exportgraphics(figM, savePath, 'ContentType', 'image');
% fprintf('Figure saved to: %s\n', savePath);

% --- Step 4: heatmap with correlation and other things ----------------------------------------
% figH = plotFWmetricsHeatmap(metrics, saveFolder_ts);


%% =========================================================
%  FUNCTION: computeFWtimeseries
%% =========================================================
function fw = computeFWtimeseries(Am, sims, simNames, Sref, depth_ranges)

    nDepths = size(depth_ranges, 1);
    nSims   = numel(sims);

    fw.depthLabels = arrayfun(@(k) sprintf('%d–%d m', depth_ranges(k,1), depth_ranges(k,2)), ...
                              (1:nDepths)', 'UniformOutput', false);
    fw.depth_ranges = depth_ranges;

    % --- Observations ---
    if ~isempty(Am)
        Am.dz    = diff([0; Am.depths]);
        valid    = ~all(isnan(Am.S), 1);
        Am.dates = Am.dates(valid);
        Am.S     = Am.S(:, valid);

        FW_obs = nan(nDepths, numel(Am.dates));
        for k = 1:nDepths
            FW_obs(k,:) = fw_content(Am.S, -Am.depths, Am.dz, Sref, ...
                                     depth_ranges(k,1), depth_ranges(k,2));
        end
        fw.obs.dates = Am.dates;
        fw.obs.FW    = FW_obs;
    else
        fw.obs = [];
    end

    % --- Simulations ---
    for sIdx = 1:nSims
        s      = sims{sIdx};
        s.date = datetime(s.t, 'ConvertFrom', 'datenum');

        FW_sim = nan(nDepths, numel(s.date));
        for k = 1:nDepths
            FW_sim(k,:) = fw_content(s.S, s.z, s.H, Sref, ...
                                     depth_ranges(k,1), depth_ranges(k,2));
        end
        fw.sims(sIdx).name  = simNames{sIdx};
        fw.sims(sIdx).dates = s.date;
        fw.sims(sIdx).FW    = FW_sim;
    end
end

function fig = plotFWtimeseries(fw, metrics, depth_ranges)

    nDepths = size(depth_ranges, 1);

    % ---- Colours (same as metrics) --------------------------------------
    colors = colors_ameralik();
    simColors = colors.simColors;

    % ---- Line styles by mixing level ------------------------------------
    ls = struct();
    ls.VHIGH = colors.ls.VHIGH;
    ls.HIGH  = colors.ls.HIGH;
    ls.LOW   = colors.ls.LOW;
    ls.OBS   = colors.ls.OBS;

    function sty = getLS(simName)
        if contains(simName, 'Very high', 'IgnoreCase', true)
            sty = ls.VHIGH;
        elseif contains(simName, 'High mix', 'IgnoreCase', true)
            sty = ls.HIGH;
        elseif contains(simName, 'Low mix', 'IgnoreCase', true)
            sty = ls.LOW;
        else
            sty = '-';
        end
    end

    function c = simC(name)
        if isKey(simColors, name)
            c = simColors(name);
        else
            c = [0.5 0.5 0.5];
        end
    end

    % ---- Group definitions (same as metrics) ----------------------------
    SIM_VH_HS   = 'Very high mix - High Shelf Exchange';
    SIM_VH_LS   = 'Very high mix - Low Shelf Exchange';
    SIM_H_HS    = 'High mix - High Shelf Exchange';
    SIM_H_LS    = 'High mix - Low Shelf Exchange';
    SIM_L_HS    = 'Low mix - High Shelf Exchange';
    SIM_VH_NOAS = 'Very high mix - High Shelf Exchange - No Air-Sea Heat Flux';
    SIM_VH_NORU = 'Very high mix - High Shelf Exchange - No Runoff';

    groups = {
        'Mixing (High Shelf Exchange)', ...
            {SIM_VH_HS, SIM_H_HS, SIM_L_HS};
        'Shelf Exchange', ...
            {SIM_VH_HS, SIM_VH_LS, SIM_H_HS, SIM_H_LS};
        'Sensitivity (VH mixing)', ...
            {SIM_VH_HS, SIM_VH_NOAS, SIM_VH_NORU};
    };
    nGroups = size(groups, 1);

    % ---- Short display labels -------------------------------------------
    shortName = containers.Map(...
        {SIM_VH_HS, SIM_VH_LS, SIM_H_HS, SIM_H_LS, SIM_L_HS, SIM_VH_NOAS, SIM_VH_NORU}, ...
        {'VH–HS', 'VH–LS', 'H–HS', 'H–LS', 'L–HS', 'VH–HS (no A-S)', 'VH–HS (no Rn)'});

    % ---- Helper: find sim index -----------------------------------------
    function idx = findSim(name)
        idx = find(strcmp(metrics.simNames, name), 1);
        if isempty(idx)
            idx = find(contains(metrics.simNames, name, 'IgnoreCase', true), 1);
        end
    end

    % ---- One figure tab per group ---------------------------------------
    fig = gobjects(nGroups, 1);

    for g = 1:nGroups
        grpTitle = groups{g, 1};
        grpSims  = groups{g, 2};
        nSims    = numel(grpSims);

        fig(g) = figure('Name', grpTitle, ...
                        'Units', 'centimeters', ...
                        'Position', [2+g*2, 2, 18, 4 + nDepths*3.5]);
        tl = tiledlayout(nDepths, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
        title(tl, grpTitle, 'FontSize', 11, 'FontWeight', 'bold');

        for k = 1:nDepths
            ax = nexttile(tl);
            hold(ax, 'on');

            % Observations
            if ~isempty(fw.obs)
                plot(ax, fw.obs.dates, fw.obs.FW(k,:), ...
                     ls.OBS, 'Color', [0.1 0.1 0.1], 'LineWidth', 1.8, ...
                     'DisplayName', 'Observations');
            end

            % Simulations in this group
            for s = 1:nSims
                sName = grpSims{s};
                sIdx  = findSim(sName);
                if isempty(sIdx); continue; end

                col = simC(sName);
                sty = getLS(sName);

                % Sensitivity group: differentiate no-A-S and no-Rn by thickness
                lw = 1.2;
                if contains(sName, 'No Air', 'IgnoreCase', true); lw = 1.6; end
                if contains(sName, 'No Runoff', 'IgnoreCase', true); lw = 1.6; end

                lbl = sName;
                if isKey(shortName, sName); lbl = shortName(sName); end

                plot(ax, fw.sims(sIdx).dates, fw.sims(sIdx).FW(k,:), ...
                     sty,...% 'Color', col, ...
                     'LineWidth', lw, ...
                     'DisplayName', lbl);
            end

            % Panel label + depth
            letter = char('a' + (g-1)*nDepths + k - 1);
            text(ax, -0.08, 1.05, sprintf('(%s)', letter), ...
                 'Units', 'normalized', 'FontSize', 9, ...
                 'FontWeight', 'bold', 'Clipping', 'off');

            ylabel(ax, sprintf('FW content (m)\n%s', fw.depthLabels{k}), 'FontSize', 8);

            set(ax, 'TickDir', 'out', 'Box', 'off', ...
                    'YGrid', 'on', 'GridAlpha', 0.18, 'GridLineStyle', ':');
            % Set x-limits and monthly ticks for all axes
            startDate = datetime(2018,1,1);
            endDate   = datetime(2019,12,31);
            ax.XLim = [startDate endDate];                     % x-limits
            ax.XTick = startDate:calmonths(1):endDate;        % monthly ticks
            % Set x-limits and monthly ticks for all axes
            startDate = datetime(2018,1,1);
            endDate   = datetime(2019,12,31);
            ax.XLim = [startDate endDate];                     % x-limits
            ax.XTick = startDate:calmonths(1):endDate;        % monthly ticks

            if k < nDepths
                ax.XTickLabel = [];
            else
                ax.XAxis.TickLabelFormat = 'MMM yyyy';
                ax.XTickLabelRotation = 15;
       
            end
        end

        % Legend below last tile
        lastAx = nexttile(tl, nDepths);
        legend(lastAx, 'Box', 'off', 'FontSize', 7.5, ...
               'Location', 'southoutside', 'NumColumns', 2);

    end
end



%% =========================================================
%  FUNCTION: plotFWmetricsTiled
%  Rows    = depth ranges
%  Columns = Correlation | RMSE | Bias
%
%  Group 1 (Mixing, High Shelf): VH-HS | H-HS | L-HS
%    → sim colors from colors_ameralik, solid fill
%
%  Group 2 (Shelf Exchange):     VH-HS | VH-LS | H-HS | H-LS
%    → HS bars: sim color (solid)
%    → LS bars: lighter shade of same sim color + diagonal hatch (/)
%
%  Group 3 (Sensitivity, VH mix): normal | no-air-sea | no-runoff
%    → distinct base color (teal), darker/lighter shades for variants
%    → no-air-sea: cross hatch (x), no-runoff: back-diagonal (\)
%
%  Y-limits shared per column (metric).
%  Significance stars on Correlation panel.
%% =========================================================
function fig = plotFWmetricsTiled(metrics)

    nDepths  = numel(metrics.depthLabels);
    nMetrics = 3;

    % ---- Sim colour map -------------------------------------------------
    colors    = colors_ameralik();
    simColors = colors.simColors;

    function c = simC(name)
        if isKey(simColors, name)
            c = simColors(name);
        else
            c = [0.5 0.5 0.5];
        end
    end

    % ---- Helper: lighten a colour toward white by factor f (0=same,1=white)
    function c2 = lighten(c, f)
        c2 = c + f*(1 - c);
    end

    % ---- Sim name strings -----------------------------------------------
    SIM_VH_HS     = 'Very high mix - High Shelf Exchange';
    SIM_VH_LS     = 'Very high mix - Low Shelf Exchange';
    SIM_H_HS      = 'High mix - High Shelf Exchange';
    SIM_H_LS      = 'High mix - Low Shelf Exchange';   % may not exist
    SIM_L_HS      = 'Low mix - High Shelf Exchange';
    SIM_VH_NOAS   = 'Very high mix - High Shelf Exchange - No Air-Sea Heat Flux';
    SIM_VH_NORU   = 'Very high mix - High Shelf Exchange - No Runoff';

    % Sensitivity base colour: slate-teal, distinct from sim palette
    cSens  = simC(SIM_VH_HS);   % normal
    cSensA = lighten(cSens, 0.45); % no air-sea (lighter)
    cSensR = cSens * 0.65;         % no runoff  (darker)

    % ---- Bar spec: {label, simName, faceColor, hatchStyle, lightenFrac}
    %   hatchStyle: '' = solid | '/' = fwd diagonal | 'x' = cross | '\' = back diag
    %   lightenFrac: extra lightening for LS bars (applied on top of faceColor)
    grp1 = {
        'vHighMix–HighX', SIM_VH_HS,   simC(SIM_VH_HS), '',  0;
        'HighMix–HighX',  SIM_H_HS,    simC(SIM_H_HS),  '',  0;
        'LowMix–HighX',  SIM_L_HS,    simC(SIM_L_HS),  '',  0;
    };
    grp2 = {
        'vHighMix–HighX', SIM_VH_HS,  simC(SIM_VH_HS),                    '',   0;
        'vHighMix–LowX', SIM_VH_LS,  lighten(simC(SIM_VH_HS), 0.42),     '/',  0;
        'HighMix–HighX',  SIM_H_HS,   simC(SIM_H_HS),                     '',   0;
        'HighMix–LowX',  SIM_H_LS,   lighten(simC(SIM_H_HS),  0.42),     '/',  0;
    };
    grp3 = {
        'vH–HX', SIM_VH_HS,   cSens,  '',   0;
        'vH–HX-No A-S', SIM_VH_NOAS, cSensA, '',  0; %x
        'vH–HX-No Run', SIM_VH_NORU, cSensR, '',  0; %"\"
    };

    groups      = {grp1, grp2, grp3};
    groupLabels = {'Mixing (HS)', 'Shelf Exchange', 'Sensitivity (VH)'};

    % ---- Helper: find sim index -----------------------------------------
    function idx = findSim(name)
        idx = find(strcmp(metrics.simNames, name), 1);
        if isempty(idx)
            idx = find(contains(metrics.simNames, name, 'IgnoreCase', true), 1);
        end
    end

    % ---- Hatch drawing helper -------------------------------------------
    % Draws diagonal lines clipped to a bar rectangle on axes ax.
    % xc = bar x centre, v = bar height, bw = bar half-width
    % style: '/' | '\' | 'x'
    function drawHatch(ax, xc, v, bw, style, col)
        if isnan(v) || v == 0; return; end
        ylo = min(0, v);  yhi = max(0, v);
        xl  = xc - bw;    xr  = xc + bw;
        W   = xr - xl;          % bar width
        H   = yhi - ylo;        % bar height
        if H < 1e-9 || W < 1e-9; return; end

        hatchCol = col * 0.55;
        spacing  = min(W, H) / 5;   % spacing relative to smaller dimension
        if spacing < 1e-9; return; end

        % Diagonals run at 45°, so offset them along the perpendicular.
        % Cover the full rectangle by sweeping from -(W+H) to +(W+H)
        offsets = (-ceil((W+H)/spacing) : ceil((W+H)/spacing)) * spacing;

        % forward diagonals (/) : y = ylo + (x - xl) + o
        if strcmp(style, '/') || strcmp(style, 'x')
            for o = offsets
                xs = [xl, xr];
                ys = [ylo + o, ylo + o + W];   % slope +1 in data units
                [xs, ys] = clipLineToRect(xs, ys, xl, xr, ylo, yhi);
                if ~isempty(xs)
                    plot(ax, xs, ys, '-', 'Color', hatchCol, ...
                         'LineWidth', 0.8, 'HandleVisibility','off', 'Clipping','on');
                end
            end
        end

        % back diagonals (\) : y = yhi - (x - xl) + o
        if strcmp(style, '\') || strcmp(style, 'x')
            for o = offsets
                xs = [xl, xr];
                ys = [yhi + o, yhi + o - W];   % slope -1 in data units
                [xs, ys] = clipLineToRect(xs, ys, xl, xr, ylo, yhi);
                if ~isempty(xs)
                    plot(ax, xs, ys, '-', 'Color', hatchCol, ...
                         'LineWidth', 0.8, 'HandleVisibility','off', 'Clipping','on');
                end
            end
        end
    end

    % ---- Line-rectangle clipping (Cohen-Sutherland lite) ----------------
    function [xo, yo] = clipLineToRect(xi, yi, xl, xr, ylo, yhi)
        xo = []; yo = [];
        x1=xi(1); y1=yi(1); x2=xi(2); y2=yi(2);
        dx=x2-x1; dy=y2-y1;
        p=[-dx dx -dy dy]; q=[x1-xl xr-x1 y1-ylo yhi-y1];
        u1=0; u2=1;
        for i=1:4
            if p(i)==0
                if q(i)<0; return; end
            elseif p(i)<0
                u1=max(u1, q(i)/p(i));
            else
                u2=min(u2, q(i)/p(i));
            end
        end
        if u1>u2; return; end
        xo=[x1+u1*dx, x1+u2*dx];
        yo=[y1+u1*dy, y1+u2*dy];
    end

    % ---- Metric meta-data -----------------------------------------------
    metricKeys   = {'corr', 'rmse', 'bias'};
    metricTitles = {'Correlation (r)', 'RMSE (m)', 'Bias (m)'};
    refLines     = {NaN, NaN, 0};
    panelLetters = 'abcdefghijkl';
    barW         = 0.92;   % bar width fraction

    % ---- First pass: collect all bar x-positions and values per tile ----
    % We need this to compute per-column y-limits before drawing.

    % Build bar specs once (same for every depth/metric)
    % Use cell arrays to avoid MATLAB dissimilar-struct errors, convert at end
    bSimName   = {};
    bSimIdx    = {};
    bLabel     = {};
    bFaceColor = {};
    bHatch     = {};
    bXPos      = [];
    bGroup     = [];
    groupTickX = zeros(1,3);
    xCursor    = 1;
    for g = 1:3
        grp      = groups{g};
        barStart = xCursor;
        for b = 1:size(grp, 1)
            bSimName{end+1}   = grp{b,2};        %#ok<AGROW>
            bSimIdx{end+1}    = findSim(grp{b,2}); %#ok<AGROW>
            bLabel{end+1}     = grp{b,1};         %#ok<AGROW>
            bFaceColor{end+1} = grp{b,3};         %#ok<AGROW>
            bHatch{end+1}     = grp{b,4};         %#ok<AGROW>
            bXPos(end+1)      = xCursor;           %#ok<AGROW>
            bGroup(end+1)     = g;                 %#ok<AGROW>
            xCursor = xCursor + 1;
        end
        barEnd        = xCursor - 1;
        groupTickX(g) = (barStart + barEnd) / 2;
        xCursor       = xCursor + 1.5;
    end
    nBarsTotal = numel(bXPos);
    % Pack into struct array now that all fields are known
    barSpecs = struct('simName', bSimName, 'simIdx', bSimIdx, ...
                      'label', bLabel, 'faceColor', bFaceColor, ...
                      'hatch', bHatch, 'xPos', num2cell(bXPos), ...
                      'group', num2cell(bGroup));

    % Compute per-column y-limits across all depths
    colYlim = zeros(nMetrics, 2);
    for m = 1:nMetrics
        allVals = [];
        for k = 1:nDepths
            for b = 1:nBarsTotal
                sIdx = barSpecs(b).simIdx;
                if isempty(sIdx); continue; end
                v = metrics.(metricKeys{m})(k, sIdx);
                if ~isnan(v); allVals(end+1) = v; end %#ok<AGROW>
            end
        end
        if isempty(allVals)
            colYlim(m,:) = [0 1];
        else
            pad = (max(allVals) - min(allVals)) * 0.15;
            pad = max(pad, 0.05);
            colYlim(m,1) = min(allVals) - pad;
            colYlim(m,2) = max(allVals) + pad;
            % For correlation, never exceed [-1 1]
            if m == 1
                colYlim(m,1) = max(colYlim(m,1), -1);
                colYlim(m,2) = min(colYlim(m,2),  1);
            end
            % bias/rmse: include 0
            if m == 2 || m == 3
                colYlim(m,1) = min(colYlim(m,1), 0);
                colYlim(m,2) = max(colYlim(m,2), 0);
            end
        end
    end

    % ---- Figure ---------------------------------------------------------
    fig = figure('Name','FW Metrics – tiled', ...
                 'Units','centimeters', ...
                 'Position',[1 1 8 + nMetrics*4.8, 3 + nDepths*3.0]);
    tl  = tiledlayout(nDepths, nMetrics, ...
                      'TileSpacing','compact', 'Padding','compact');

    allAxes    = gobjects(nDepths, nMetrics);
    panelCount = 0;

    for k = 1:nDepths
        for m = 1:nMetrics
            ax = nexttile(tl);
            allAxes(k,m) = ax;
            hold(ax, 'on');
            panelCount = panelCount + 1;

            ylims = colYlim(m,:);
            ySpan = ylims(2) - ylims(1);

            for b = 1:nBarsTotal
                sIdx = barSpecs(b).simIdx;
                if isempty(sIdx); continue; end
                v   = metrics.(metricKeys{m})(k, sIdx);
                if isnan(v); continue; end

                fc   = barSpecs(b).faceColor;
                ht   = barSpecs(b).hatch;
                xc   = barSpecs(b).xPos;
                bw   = barW / 2;

                % Solid bar (possibly semi-transparent for hatched bars)
                fa = 0.88;
                if ~isempty(ht); fa = 0.55; end

                bar(ax, xc, v, barW, ...
                    'FaceColor', fc, 'FaceAlpha', fa, ...
                    'EdgeColor', fc*0.6, 'LineWidth', 0.6);

                % Hatch overlay
                if ~isempty(ht)
                    drawHatch(ax, xc, v, bw, ht, fc);
                end

            end

            % Reference line
            if ~isnan(refLines{m})
                yline(ax, refLines{m}, 'k--', 'LineWidth', 0.9, 'HandleVisibility','off');
            end

            % Y-limits (shared per column)
            ylim(ax, ylims);

            % X-axis ticks: one per bar (abbreviated labels only on bottom row)
            if k == nDepths
                set(ax, 'XTick', bXPos, 'XTickLabel', {barSpecs.label}, ...
                        'XTickLabelRotation', 90, 'FontSize', 7, ...
                        'TickDir', 'out', 'Box', 'off', ...
                        'YGrid', 'on', 'GridAlpha', 0.18, 'GridLineStyle', ':');
            else
                set(ax, 'XTick', bXPos, 'XTickLabel', {}, ...
                        'TickDir', 'out', 'Box', 'off', ...
                        'YGrid', 'on', 'GridAlpha', 0.18, 'GridLineStyle', ':');
            end
            ax.XAxis.TickLength = [0 0];
            xlim(ax, [0.2, barSpecs(end).xPos + 0.8]);


            % Panel letter
            letter = panelLetters(panelCount);
            text(ax, -0.08, 1, sprintf('(%s)', letter), ...
                 'Units','normalized', 'VerticalAlignment','top', ...
                 'FontSize', 9, 'FontWeight','bold', 'Clipping','off', 'HorizontalAlignment','right')


            % Depth label on RIGHT side of rightmost column
            if m == nMetrics
                yyaxis(ax, 'right');
                ax.YAxis(2).Color = ax.YAxis(1).Color; % match left axis color
                ax.YAxis(2).Limits = ax.YAxis(1).Limits; % match left axis limits
                ax.YAxis(2).TickValues = ax.YAxis(1).TickValues; % match ticks
                ax.YAxis(2).TickLabels = {};               % hide right tick labels
                ax.YAxis(2).LineWidth = 0.000001;             % effectively invisible spine
                yl = ylabel(ax, metrics.depthLabels{k}, 'FontSize', 10, 'FontWeight','bold');
                yl.Rotation = -90;                         % flip to face rightward
                yyaxis(ax, 'left');
            end

            % Metric title on top row only
            if k == 1
                title(ax, metricTitles{m}, 'FontSize', 10, 'FontWeight','bold');
            end

            % Y-label on all tiles
            ylabel(ax, metricTitles{m}, 'FontSize', 8);
        end
    end

    % ---- Legend (east of tiled layout) ----------------------------------
    % Built directly from barSpecs so colours/hatches exactly match the bars.
    % Full sim names are used. A blank row separates groups.

    groupPrefix = {'', '', ''};

    % Full display names per bar — same order as barSpecs
    allGrps  = {grp1, grp2, grp3};
    fullNames = {};
    for g = 1:3
        grp = allGrps{g};
        for b = 1:size(grp,1)
            fullNames{end+1} = grp{b,2}; %#ok<AGROW>
        end
    end

    % Invisible axes to host legend proxy objects
    axLeg = axes(fig, 'Visible','off', 'Position',[0 0 0.001 0.001]);
    hold(axLeg, 'on');

    legH    = gobjects(0);
    legL    = {};
    prevGrp = 0;

    for b = 1:nBarsTotal
        fc  = barSpecs(b).faceColor;
        ht  = barSpecs(b).hatch;
        g   = barSpecs(b).group;
        fa  = 0.88;
        if ~isempty(ht); fa = 0.55; end

        % Blank separator row at each group boundary
        if g ~= prevGrp && prevGrp ~= 0
            legH(end+1) = plot(axLeg, NaN, NaN, 'w.', 'MarkerSize', 0.1); %#ok<AGROW>
            legL{end+1} = ' '; %#ok<AGROW>
        end
        prevGrp = g;

        % Proxy patch with IDENTICAL FaceColor, FaceAlpha, EdgeColor as bar
        h = patch(axLeg, NaN, NaN, fc, ...
                  'FaceAlpha', fa, ...
                  'EdgeColor', fc * 0.6, 'LineWidth', 0.6);
        legH(end+1) = h; %#ok<AGROW>

        % Full sim name with group prefix; hatch suffix for hatched bars
        lbl = [groupPrefix{g}, fullNames{b}];
        if strcmp(ht, '/')
            lbl = [lbl, '  [/]']; %#ok<AGROW>
        elseif strcmp(ht, 'x')
            lbl = [lbl, '  [x]']; %#ok<AGROW>
        elseif strcmp(ht, '\')
            lbl = [lbl, '  [\]']; %#ok<AGROW>
        end
        legL{end+1} = lbl; %#ok<AGROW>
    end
    row = 1;   % top row
    col = nMetrics;   % last column
    nCols = nMetrics; % number of columns in tiledlayout
    
    tileNum = (row-1)*nCols + col;
    axLeg = nexttile(tl, tileNum);

    % lg = legend(axLeg, legH, legL, 'Box','off', 'FontSize',7.5, ...
    %             'Location','none');
    % lg.Layout.Tile = 'east';
end


%% =========================================================
%  FUNCTION: computeFWstatistics
%% =========================================================
function T = computeFWstatistics(fw)

    nDepths = numel(fw.depthLabels);
    nSims   = numel(fw.sims);

    DepthRange  = {};
    SimName     = {};
    MeanFW      = [];
    StdFW       = [];
    CorrWithObs = [];

    for k = 1:nDepths
        if ~isempty(fw.obs)
            obs_fw   = fw.obs.FW(k,:);
            DepthRange{end+1,1}  = fw.depthLabels{k};  %#ok<AGROW>
            SimName{end+1,1}     = 'Observations';
            MeanFW(end+1,1)      = mean(obs_fw, 'omitnan');
            StdFW(end+1,1)       = std(obs_fw,  'omitnan');
            CorrWithObs(end+1,1) = 1;
        end

        for sIdx = 1:nSims
            sim_fw = fw.sims(sIdx).FW(k,:);

            DepthRange{end+1,1} = fw.depthLabels{k};   %#ok<AGROW>
            SimName{end+1,1}    = fw.sims(sIdx).name;
            MeanFW(end+1,1)     = mean(sim_fw, 'omitnan');
            StdFW(end+1,1)      = std(sim_fw,  'omitnan');

            if ~isempty(fw.obs)
                corr_val = correlateOnSharedDates( ...
                    fw.obs.dates,        fw.obs.FW(k,:)', ...
                    fw.sims(sIdx).dates, sim_fw');
            else
                corr_val = NaN;
            end
            CorrWithObs(end+1,1) = corr_val;
        end
    end

    T = table(DepthRange, SimName, MeanFW, StdFW, CorrWithObs, ...
              'VariableNames', {'DepthRange','Simulation','Mean_m','Std_m','Corr_vs_Obs'});
end


%% =========================================================
%  HELPER: correlateOnSharedDates
%% =========================================================
function r = correlateOnSharedDates(obsDates, obsFW, simDates, simFW)
    tObs = datenum(obsDates);
    tSim = datenum(simDates);

    tMin   = max(min(tObs), min(tSim));
    tMax   = min(max(tObs), max(tSim));
    tDaily = (ceil(tMin) : floor(tMax))';

    if numel(tDaily) < 3
        r = NaN; return;
    end

    obsDaily = interp1(tObs, obsFW, tDaily, 'linear', NaN);
    simDaily = interp1(tSim, simFW, tDaily, 'linear', NaN);

    valid = ~isnan(obsDaily) & ~isnan(simDaily);
    if sum(valid) < 3
        r = NaN; return;
    end

    C = corrcoef(obsDaily(valid), simDaily(valid));
    r = C(1,2);
end


%% =========================================================
%  FUNCTION: computeFWmetrics
%  Now also returns p-values for correlation significance
%% =========================================================
function metrics = computeFWmetrics(fw)

    nDepths = numel(fw.depthLabels);
    nSims   = numel(fw.sims);

    rmse   = nan(nDepths, nSims);
    bias   = nan(nDepths, nSims);
    corr_r = nan(nDepths, nSims);
    pval   = nan(nDepths, nSims);
    nDays  = nan(nDepths, nSims);

    for k = 1:nDepths
        if isempty(fw.obs); continue; end
        tObs  = datenum(fw.obs.dates);
        obsFW = fw.obs.FW(k,:)';

        for sIdx = 1:nSims
            tSim  = datenum(fw.sims(sIdx).dates);
            simFW = fw.sims(sIdx).FW(k,:)';

            tMin   = max(min(tObs), min(tSim));
            tMax   = min(max(tObs), max(tSim));
            tDaily = (ceil(tMin) : floor(tMax))';
            if numel(tDaily) < 3; continue; end

            obsDaily = interp1(tObs, obsFW, tDaily, 'linear', NaN);
            simDaily = interp1(tSim, simFW, tDaily, 'linear', NaN);

            valid = ~isnan(obsDaily) & ~isnan(simDaily);
            if sum(valid) < 3; continue; end

            n              = sum(valid);
            nDays(k, sIdx) = n;

            diff_v          = simDaily(valid) - obsDaily(valid);
            rmse(k, sIdx)   = sqrt(mean(diff_v.^2));
            bias(k, sIdx)   = mean(diff_v);
            C               = corrcoef(obsDaily(valid), simDaily(valid));
            r               = C(1,2);
            corr_r(k, sIdx) = r;

            % Two-tailed p-value via betainc (no Statistics Toolbox needed)
            if ~isnan(r) && n > 2
                t_stat = r * sqrt((n-2) / max(1 - r^2, 1e-12));
                p_val  = betainc((n-2) / ((n-2) + t_stat^2), (n-2)/2, 0.5);
                pval(k, sIdx) = p_val;
            end
        end
    end

    metrics.depthLabels = fw.depthLabels;
    metrics.simNames    = {fw.sims.name};
    metrics.rmse        = rmse;
    metrics.bias        = bias;
    metrics.corr        = corr_r;
    metrics.pval        = pval;
    metrics.nDays       = nDays;
end


%% =========================================================
%  FUNCTION: plotFWmetricsHeatmap  (unchanged from original)
%% =========================================================
function figH = plotFWmetricsHeatmap(metrics, saveFolder)

    nDepths = numel(metrics.depthLabels);
    nSims   = numel(metrics.simNames);

    % --- Significance test on correlation --------------------------------
    corrSig = false(nDepths, nSims);
    for k = 1:nDepths
        for s = 1:nSims
            r = metrics.corr(k, s);
            n = metrics.nDays(k, s);
            if ~isnan(r) && ~isnan(n) && n > 2
                t_stat = r * sqrt((n-2) / max(1 - r^2, 1e-12));
                p_val  = betainc((n-2) / ((n-2) + t_stat^2), (n-2)/2, 0.5);
                corrSig(k, s) = p_val < 0.05;
            end
        end
    end

    metricOrder = {'rmse', 'bias', 'corr'};
    metricNames = {'RMSE (m)', 'Bias (m)', 'r'};
    nMetrics    = numel(metricOrder);
    nCols       = nDepths * nMetrics;

    data      = nan(nSims, nCols);
    colLabels = cell(1, nCols);
    isSigCell = false(nSims, nCols);

    for k = 1:nDepths
        for m = 1:nMetrics
            col            = (k-1)*nMetrics + m;
            colLabels{col} = sprintf('%s\n%s', metrics.depthLabels{k}, metricNames{m});
            data(:, col)   = metrics.(metricOrder{m})(k, :)';
            if strcmp(metricOrder{m}, 'corr')
                isSigCell(:, col) = corrSig(k, :)';
            end
        end
    end

    dataNorm = nan(size(data));
    for col = 1:nCols
        mIdx = mod(col-1, nMetrics) + 1;
        if strcmp(metricOrder{mIdx}, 'bias') || strcmp(metricOrder{mIdx}, 'corr')
            v = abs(data(:, col));
        else
            v = data(:, col);
        end
        vmin = min(v, [], 'omitnan');
        vmax = max(v, [], 'omitnan');
        if vmax == vmin
            dataNorm(:, col) = 0.5;
        else
            dataNorm(:, col) = (v - vmin) ./ (vmax - vmin);
        end
        if ~strcmp(metricOrder{mIdx}, 'corr')
            dataNorm(:, col) = 1 - dataNorm(:, col);
        end
    end

    nC   = 256;
    cmap = [ linspace(0.85, 1,   nC/2)', linspace(0.1,  1,   nC/2)', linspace(0.1,  1,   nC/2)' ; ...
             linspace(1,   0.1,  nC/2)', linspace(1,   0.85, nC/2)', linspace(1,   0.1,  nC/2)' ];

    figH = figure('Units','centimeters', ...
                  'Position',[1 1 4 + nCols*1.6, 2 + nSims*0.7]);
    ax   = axes(figH);
    imagesc(ax, dataNorm);
    colormap(ax, cmap);
    clim(ax, [0 1]);

    set(ax, 'YTick', 1:nSims, 'YTickLabel', metrics.simNames, ...
            'XTick', 1:nCols, 'XTickLabel', repmat(metricNames, 1, nDepths), ...
            'XTickLabelRotation', 0, 'FontSize', 8, ...
            'TickDir', 'none', 'Box', 'on');
    ax.XAxis.TickLength = [0 0];
    ax.YAxis.TickLength = [0 0];

    for row = 1:nSims
        for col = 1:nCols
            v = data(row, col);
            if isnan(v); continue; end
            star = '';
            if isSigCell(row, col); star = '*'; end
            mIdx = mod(col-1, nMetrics) + 1;
            if strcmp(metricOrder{mIdx}, 'corr')
                txt = sprintf('%.2f%s', v, star);
            else
                txt = sprintf('%.3f%s', v, star);
            end
            text(ax, col, row, txt, ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', 7.5, 'Color', 'k');
        end
    end

    for k = 1:nDepths-1
        xline(ax, k*nMetrics + 0.5, 'k-', 'LineWidth', 1.2, 'HandleVisibility','off');
    end

    for k = 1:nDepths
        xc = (k-1)*nMetrics + (nMetrics+1)/2;
        text(ax, xc, 0.1, metrics.depthLabels{k}, ...
            'Units','data', 'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', 'FontSize', 8.5, ...
            'FontWeight','bold', 'Clipping','off');
    end

    title(ax, 'Model performance metrics   (* = r significant at p < 0.05)', ...
          'FontSize', 9);
    fprintf('* p < 0.05 (two-tailed t-test on Pearson r, df = n - 2)\n');

    if nargin > 1 && ~isempty(saveFolder)
        savePath = fullfile(saveFolder, 'FW_metrics_heatmap.pdf');
        % exportgraphics(figH, savePath, 'ContentType','vector');
        % fprintf('Heatmap saved to: %s\n', savePath);
    end
end


%% =========================================================
%  LOCAL HELPER: fw_content
%% =========================================================
function FW = fw_content(S, z, H0, Sref, min_depth, max_depth)
    layers = find(abs(z) > min_depth & abs(z) < max_depth);
    FW = sum(((Sref - S(layers,:)) ./ Sref) .* H0(layers), 1);
end
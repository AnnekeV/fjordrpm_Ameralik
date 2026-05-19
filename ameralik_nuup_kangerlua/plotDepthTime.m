% -----------------------------------------------------------------------
% plotDepthTime.m
% [fig1, fig2] = plotDepthTime(obs_dates, obs_z, obs_data,
%                               sim_dates, sim_z, sim_data,
%                               simNames, varInfo)
%
% obs_dates  [1 x nT_obs]        datenum
% obs_z      [nz_obs x 1]        positive-down depths (m)
% obs_data   [nz_obs x nT_obs]
% sim_dates  [1 x nT_sim]        datenum
% sim_z      [nz_sim x 1]        positive-down depths (m)
% sim_data   [nz_sim x nT_sim x nSims]
% simNames   {1 x nSims}
% varInfo    struct: .label .units .cmap .clim .dcmap .dclim
%
% fig1 — absolute panels (obs + sims, shared colorbar)
% fig2 — obs top-left (absolute) + difference panels (shared diverging colorbar)
% -----------------------------------------------------------------------
function [fig1, fig2] = plotDepthTime(obs_dates, obs_z, obs_data, ...
                                      sim_dates, sim_z, sim_data, ...
                                      simNames, varInfo)

    nSims   = numel(simNames);
    nPanels = nSims + 1;
    nCols   = min(nPanels, 3);
    nRows   = ceil(nPanels / nCols);

    % Style
    fsAx = 8;  fsPL = 9;  axCol = [0.15 0.15 0.15];
    axStyle = {'FontSize',fsAx,'FontName','Helvetica','TickDir','out', ...
               'TickLength',[0.015 0.025],'Box','off', ...
               'XColor',axCol,'YColor',axCol,'LineWidth',0.8};
    panelLetters = 'abcdefghijklmnopqrstuvwxyz';

    t_start = datetime(2018,1,1);
    t_end   = datetime(2020,1,1);
    tick_dt = t_start : calmonths(3) : t_end;

    % ── Grid obs (no extrapolation: NaN outside obs_z range per profile) ──
    obs_dt = datetime(obs_dates,'ConvertFrom','datenum');
    [obs_grid, tg, zg] = makeGrid(obs_data, obs_dt, obs_z, t_start, t_end);

    % ── Grid sims onto same (zg, tg) ─────────────────────────────────────
    sim_grid = NaN(numel(zg), numel(tg), nSims);
    for sIdx = 1:nSims
        sd = sim_dates;
        if ~isdatetime(sd);  sd = datetime(sd,'ConvertFrom','datenum');  end
        sim_grid(:,:,sIdx) = makeGrid(squeeze(sim_data(:,:,sIdx)), sd, sim_z, t_start, t_end, zg, tg);
    end

    % ── Color limits ─────────────────────────────────────────────────────
    if isempty(varInfo.clim)
        v = [obs_grid(:); sim_grid(:)];  v = v(isfinite(v));
        varInfo.clim = quantile(v,[0.01 0.99]);
    end
    if isempty(varInfo.dclim)
        d = sim_grid - obs_grid;  d = d(isfinite(d));
        dlim = max(abs(quantile(d,[0.01 0.99])));
        varInfo.dclim = [-dlim dlim];
    end

    % ════════════════════════════════════════════════════════════════════
    %  Figure 1 — absolute
    % ════════════════════════════════════════════════════════════════════
    fig1  = makeFig(nRows, nCols);
    axAll = gobjects(nPanels,1);

    axAll(1) = makePanel(fig1, nRows, nCols, 1);
    plotPcolor(axAll(1), tg, zg, obs_grid, varInfo.clim, varInfo.cmap, axStyle);
    labelPanel(axAll(1), 'Observations', panelLetters(1), fsAx, fsPL, axCol);

    for sIdx = 1:nSims
        p = sIdx+1;
        axAll(p) = makePanel(fig1, nRows, nCols, p);
        plotPcolor(axAll(p), tg, zg, sim_grid(:,:,sIdx), varInfo.clim, varInfo.cmap, axStyle);
        labelPanel(axAll(p), simNames{sIdx}, panelLetters(p), fsAx, fsPL, axCol);
    end

    applySharedAxes(axAll, tick_dt, nRows, nCols, nPanels, fsAx, axCol);
    setYLabels(axAll, nCols, nPanels, fsAx);
    addSharedColorbar(fig1, axAll, varInfo.clim, varInfo.cmap, ...
        [varInfo.label ' (' varInfo.units ')'], fsAx, axCol);

    % ════════════════════════════════════════════════════════════════════
    %  Figure 2 — obs + differences
    % ════════════════════════════════════════════════════════════════════
    fig2   = makeFig(nRows, nCols);
    axDiff = gobjects(nPanels,1);

    axDiff(1) = makePanel(fig2, nRows, nCols, 1);
    plotPcolor(axDiff(1), tg, zg, obs_grid, varInfo.clim, varInfo.cmap, axStyle);
    labelPanel(axDiff(1), 'Observations', panelLetters(1), fsAx, fsPL, axCol);
    addInsetColorbar(axDiff(1), varInfo.clim, varInfo.cmap, varInfo.units, fsAx, axCol);

    for sIdx = 1:nSims
        p = sIdx+1;
        axDiff(p) = makePanel(fig2, nRows, nCols, p);
        plotPcolor(axDiff(p), tg, zg, sim_grid(:,:,sIdx)-obs_grid, varInfo.dclim, varInfo.dcmap, axStyle);
        labelPanel(axDiff(p), [simNames{sIdx} ' - Obs'], panelLetters(p), fsAx, fsPL, axCol);
    end

    applySharedAxes(axDiff, tick_dt, nRows, nCols, nPanels, fsAx, axCol);
    setYLabels(axDiff, nCols, nPanels, fsAx);
    addSharedColorbar(fig2, axDiff(2:end), varInfo.dclim, varInfo.dcmap, ...
        ['\Delta' varInfo.label ' (' varInfo.units ')'], fsAx, axCol);
end

% ═══════════════════════════════════════════════════════════════════════
%  Helpers
% ═══════════════════════════════════════════════════════════════════════

function [grid_out, tg, zg] = makeGrid(data, dt_in, z_in, t_start, t_end, zg, tg)
% Interpolate [nz x nT] onto regular (zg, tg). No extrapolation beyond
% the observed depth range at each time step.
    dt_num = datenum(dt_in);
    if nargin < 6 || isempty(zg)
        zg = (min(z_in) : 5 : max(z_in))';
    end
    if nargin < 7 || isempty(tg)
        tg = datetime(datenum(t_start):1:datenum(t_end),'ConvertFrom','datenum')';
    end
    tg_num = datenum(tg);
    nz = numel(zg);  nt = numel(tg);

    % First interpolate in time at each obs depth level
    tmp = NaN(numel(z_in), nt);
    for iz = 1:numel(z_in)
        row = data(iz,:);  ok = isfinite(row) & isfinite(dt_num);
        if sum(ok) < 2;  continue;  end
        tmp(iz,:) = interp1(dt_num(ok), row(ok), tg_num, 'linear', NaN);
    end

    % Then interpolate in depth — strictly within obs_z range, no extrapolation
    grid_out = NaN(nz, nt);
    for it = 1:nt
        col = tmp(:,it);  ok = isfinite(col);
        if sum(ok) < 2;  continue;  end
        z_ok  = z_in(ok);
        in_range = zg >= min(z_ok) & zg <= max(z_ok);   % no extrapolation
        if sum(in_range) < 1;  continue;  end
        grid_out(in_range,it) = interp1(z_ok, col(ok), zg(in_range), 'linear', NaN);
    end
end

% -----------------------------------------------------------------------
function fig = makeFig(nRows, nCols)
    panelW=7; panelH=4.5; mL=1.4; mR=2.0; mB=1.6; mT=0.8; gapX=0.8; gapY=0.7;
    figW = mL + nCols*panelW + (nCols-1)*gapX + mR;
    figH = mB + nRows*panelH + (nRows-1)*gapY + mT;
    fig  = figure('Units','centimeters','Position',[2 2 figW figH]);
end

% -----------------------------------------------------------------------
function ax = makePanel(fig, nRows, nCols, pIdx)
    panelW=7; panelH=4.5; mL=1.4; mR=2.0; mB=1.6; mT=0.8; gapX=0.8; gapY=0.7;
    figW = mL + nCols*panelW + (nCols-1)*gapX + mR;
    figH = mB + nRows*panelH + (nRows-1)*gapY + mT;
    row  = ceil(pIdx/nCols);  col = mod(pIdx-1,nCols)+1;
    x0 = (mL + (col-1)*(panelW+gapX)) / figW;
    y0 = (mB + (nRows-row)*(panelH+gapY)) / figH;
    ax = axes('Parent',fig,'Position',[x0 y0 panelW/figW panelH/figH]);
end

% -----------------------------------------------------------------------
function plotPcolor(ax, tg, zg, data, clim, cmap, axStyle)
% Depth positive-down: zg already positive, YDir normal = shallow at top.
    tg_num = datenum(tg);
    imagesc(ax, tg_num, zg, data);
    set(ax, 'YDir','reverse', axStyle{:});   % normal = small z at top = shallow
    set(ax, 'CLim', clim);
    try;  colormap(ax, cmocean(cmap));  catch;  colormap(ax, cmap);  end
    ylim(ax, [min(zg) max(zg)]);
    xlim(ax, [tg_num(1) tg_num(end)]);
end


% -----------------------------------------------------------------------
function labelPanel(ax, titleStr, letter, fsAx, fsPL, axCol)
    if numel(titleStr) > 35;  titleStr = [titleStr(1:33) '…'];  end
    title(ax, titleStr, 'FontSize',fsAx, 'FontWeight','normal', ...
          'FontName','Helvetica', 'Color',axCol);
    text(ax, 0.01, 0.97, ['(' letter ')'], 'Units','normalized', ...
         'FontSize',fsPL, 'FontWeight','bold', 'FontName','Helvetica', ...
         'VerticalAlignment','top', 'Color',axCol);
end

% -----------------------------------------------------------------------
function setYLabels(axAll, nCols, nPanels, fsAx)
% ylabel only on left-column panels; remove y-tick labels elsewhere.
    for pIdx = 1:nPanels
        ax  = axAll(pIdx);
        col = mod(pIdx-1, nCols)+1;
        if col == 1
            ylabel(ax, 'Depth (m)', 'FontSize',fsAx, 'FontName','Helvetica');
        else
            set(ax, 'YTickLabel',[]);
        end
    end
end

% -----------------------------------------------------------------------
function applySharedAxes(axAll, tick_dt, nRows, nCols, nPanels, fsAx, axCol)
% x-tick labels only on bottom-row panels; link all axes.
    tick_num = datenum(tick_dt);
    for pIdx = 1:nPanels
        ax  = axAll(pIdx);
        row = ceil(pIdx/nCols);
        set(ax, 'XTick', tick_num);
        if row == nRows || pIdx+nCols > nPanels
            datetick(ax, 'x', 'mmm yy', 'keeplimits', 'keepticks');
            ax.XTickLabelRotation = 45;
            ax.FontSize = fsAx;
        else
            set(ax, 'XTickLabel',[]);
        end
    end
    linkaxes(axAll,'xy');
end

% -----------------------------------------------------------------------
function addSharedColorbar(fig, axArr, clim, cmap, labelStr, fsAx, axCol)
    pos = cell2mat(get(axArr,'Position'));
    if size(pos,1)==1;  pos = pos';  end   % single panel edge case
    x_right  = max(pos(:,1)+pos(:,3));
    y_bottom = min(pos(:,2));
    y_top    = max(pos(:,2)+pos(:,4));

    cb = colorbar(axArr(end));
    cb.Units    = 'normalized';
    cb.Position = [x_right+0.012, y_bottom, 0.016, y_top-y_bottom];
    cb.Label.String = labelStr;  cb.Label.FontSize = fsAx;  cb.Label.FontName = 'Helvetica';
    cb.FontSize = fsAx;  cb.FontName = 'Helvetica';
    cb.TickDirection = 'out';  cb.Box = 'off';  cb.Color = axCol;
    set(axArr(end), 'CLim', clim);
    try;  colormap(axArr(end), cmocean(cmap));  catch;  colormap(axArr(end), cmap);  end
end

% -----------------------------------------------------------------------
function addInsetColorbar(ax, clim, cmap, units, fsAx, axCol)
% Small colorbar inside obs panel (bottom-right), for fig2 only.
    pos = ax.Position;
    cb  = colorbar(ax,'Location','eastoutside');
    cb.Units    = 'normalized';
    cb.Position = [pos(1)+pos(3)+0.005, pos(2), 0.012, pos(4)*0.4];
    cb.Ticks    = linspace(clim(1),clim(2),3);
    cb.TickLabels = arrayfun(@(x)sprintf('%.1f',x), cb.Ticks,'UniformOutput',false);
    cb.Label.String = units;  cb.FontSize = fsAx-1;  cb.FontName = 'Helvetica';
    cb.TickDirection = 'out';  cb.Box = 'off';  cb.Color = axCol;
    try;  colormap(ax, cmocean(cmap));  catch;  colormap(ax, cmap);  end
end
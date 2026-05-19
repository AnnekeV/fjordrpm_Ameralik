function fig = plotFWcontentByDepthRange(Am, sims, Sref, depth_ranges, titleStr, simNames, tileShape)
% Plot FW content per depth range in configurable subplot tile layout
% Example tileShape:
%   [4 1] -> single column (default)
%   [2 2] -> 2 columns, 2 rows (for 4 panels)
%
% - Only bottom row has x-labels
% - Legend placed in last subplot
% - Fjord simulations dashed color lines
% - Observations solid black

    colors = colors_ameralik();  % returns the combined map
    simColors = colors.simColors;
    lsHIGH = colors.ls.HIGH; 
    lsVHIGH = colors.ls.VHIGH;
    lsOBS = colors.ls.OBS;

    if nargin < 6 || isempty(simNames)
        simNames = arrayfun(@(k) sprintf('Sim%d', k), 1:numel(sims), 'UniformOutput', false);
    end

    nDepths = size(depth_ranges,1);

    % Default tile layout = one column
    if nargin < 7 || isempty(tileShape)
        tileShape = [nDepths 1];
    end

    if prod(tileShape) < nDepths
        warning('tileShape has fewer tiles than depth ranges. Expanding rows.');
        tileShape = [nDepths 1];
    end

    nSims = numel(sims);

    % % Use colorblind-friendly palette or default lines
    % if exist('brewermap','file')
    %     colors = brewermap(nSims,'Set1');
    % else
    %     colors = lines(nSims);
    % end

    fig = figure('Name', titleStr, 'Units','normalized','Position',[0.1 0.1 0.75 0.8]);
    tlo = tiledlayout(tileShape(1), tileShape(2), 'TileSpacing','compact','Padding','compact');

    % Nested FW content calculation
    function FW = fw_content(S, z, H0, Sref, min_depth, max_depth)
        layers = find(abs(z) > min_depth & abs(z) < max_depth);
        FW = sum(((Sref - S(layers,:)) ./ Sref) .* H0(layers), 1);
    end

    % Observations preprocessing
    if ~isempty(Am)
        Am.dz = diff([0; Am.depths]);
        valid = ~all(isnan(Am.S),1);
        Am.dates = Am.dates(valid);
        Am.S = Am.S(:,valid);
    end

    for k = 1:nDepths
        ax = nexttile; 
        hold on;
        % Create depth range label
        drLabel = sprintf('%d–%d m', depth_ranges(k,1), depth_ranges(k,2));
        
        % Add a), b), c), ... depending on k
        letter = char('a' + k - 1);  % 'a' for k=1, 'b' for k=2, etc.
        drLabel = sprintf('%s) %s', letter, drLabel);
        % Plot fjord content from each simulation
        for sIdx = 1:nSims

            if contains(simNames{sIdx}, "Very high")
                lineStyle = lsVHIGH;   % Set line style for "Very high" simulations
            elseif contains(simNames{sIdx}, "High")
                lineStyle = lsHIGH;
            else
                lineStyle = '-.';      % dash-dot line
            end

            s = sims{sIdx};
            s.date = datetime(s.t,'ConvertFrom','datenum');
            FW_fjord = fw_content(s.S, s.z, s.H, Sref, depth_ranges(k,1), depth_ranges(k,2));
            plot(s.date, FW_fjord, lineStyle,  'LineWidth',1.5, 'DisplayName', simNames{sIdx}, 'Color', simColors(simNames{sIdx}));  %'Color', colors(sIdx,:),
        end

        % Observations
        if ~isempty(Am)
            FW_obs = fw_content(Am.S, -Am.depths, Am.dz, Sref, depth_ranges(k,1), depth_ranges(k,2));
            plot(Am.dates, FW_obs, '-k', 'LineWidth',1.3, 'DisplayName','Observations');
        end
            % FW_shelf = fw_content(s.Ss, s.z, s.H, Sref, depth_ranges(k,1), depth_ranges(k,2));
            % plot(s.date, FW_shelf, ':k', 'LineWidth',1.5, ...
            %      'DisplayName','Shelf');

        xlim([datetime(2018,1,1), datetime(2020,1,1)]); ylim([ 0 4]);
        % title(sprintf('%s', drLabel));
        text(ax, 0.01, 0.99, drLabel, 'Units','normalized', ...
     'HorizontalAlignment','left', 'VerticalAlignment','top', ...
     'FontWeight','bold');
        grid off; box off;
        % if k == 1
        ylabel(ax, 'FW content (m)');
        % end
    end

    % After plotting, collect axes (in correct order)
    ax = findall(fig, 'Type', 'axes');
    ax = flip(ax);  % reorder so first tile = first axis
    
    nCols = tileShape(2);
    nAx = numel(ax);
    
    % Only bottom row x-label
    bottomAxes = ax(nAx-nCols+1 : nAx);
    for jj = 1:nAx
        if ismember(ax(jj), bottomAxes)
            xlabel(ax(jj), '');
        else
            ax(jj).XTickLabel = [];
        end
    end
    
    legend(ax(end), 'Location', 'NorthEast', 'box', 'off')  
    % legend(ax(end), 'Box','off','Position',[0.75 0.7 0.15 0.15]);  % x, y, width, height
end



sims = {
    % load('ameralik_combined_Kb1e-05_C01e+04.mat', 's').s, 
    % load('ameralik_combined_Kb1e-05_C01e+05.mat', 's').s, 
    % load('ameralik_combined_Kb1e-04_C01e+04.mat', 's').s, 
    load('ameralik_combined_Kb1e-04_C01e+05.mat', 's').s, 
    % load('ameralik_combined_Kb1e-03_C01e+04.mat', 's').s, 
         % load('ameralik_combined_Kb1e-04_C01e+05_tidal.mat', 's').s, 

    load('ameralik_combined_Kb1e-03_C01e+05.mat', 's').s,
     % load('ameralik_combined_Kb1e-03_C01e+05_2019_only.mat', 's').s,
     % load('ameralik_combined_Kb1e-03_C01e+05_2019_FW_for_2018_shelf').s,
     % load('ameralik_combined_Kb1e-03_C01e+05_2018_shelf_for_2019').s,    
     % load('ameralik_combined_Kb1e-03_C01e+05_double_runoff').s,  
     % load('ameralik_combined_Kb1e-03_C01e+04_double_runoff').s,  
     %    load('ameralik_combined_Kb1e-04_C01e+04_subglacial').s,
     % load('ameralik_combined_Kb1e-03_C01e+05_subglacial').s,
     % load('ameralik_combined_Kb1e-03_C01e+04_subglacial').s,

    };
simNames = {
    % 'Low mix - Low shelfX',
    % 'Low mix - High shelfX',
    % 'High mix - Low shelfX', 
    'High mix - High shelfX',
      % 'Very high mix - Low ShelfX',
           % 'High mix tidal - High shelf' 

    'Very high mix - High ShelfX',
    % 'Very high mix - High ShelfX - 2019 only',
    % '2019 FW 2018 Shelf and rest',
    % '2018 Shelf for 2019',
    % 'Double runoff - Very high mix - High ShelfX',
     % % 'Double runoff - Very high mix - Low shelfX',
     %      'Subglacial - High mix - Low shelfX',
     % 'Subglacial - Very high mix - Low shelfX',
     % 'Subglacial - Very high mix - High shelfX',

    };

% Save the structure to a MAT-file
saveFolder = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim';
load(fullfile(saveFolder,'Ameralik_AM5.mat'));
load(fullfile(saveFolder,'Ameralik_mean_daily.mat'));


depth_ranges = [
    % 0 5;
                % 0 5;
                0 50;
                % 50 200;
                50 200;
                200 500;
                ];

Sref = 33.4;

close all;

folder_fig = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/';
saveFolder_ts = fullfile(folder_fig, 'comparison_obs_model_timeseries');
fig = plotFWcontentByDepthRange( ...
    AM5, sims, Sref, depth_ranges, ...
    'FW Content Comparison', simNames, [3 1]);
base =  fullfile(saveFolder_ts, 'FW_Content_simulations_parameters');
savenameS =  sprintf('%s_AM5_3_panels.pdf', base);   
saveFigure(fig, savenameS, 5,5);

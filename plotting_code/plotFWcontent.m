function e = plotFWcontent(Am, s, a, Sref, depth_ranges)
% PLOTFWCONTENT  Plot freshwater content lines for model + observations.
%
% INPUTS:
%  Am            - observational struct with fields: S, depths, dates, dz
%   s            - model struct with fields: S, z, t
%   a            - model struct with field: H0
%   Sref         - reference salinity
%   depth_ranges - Nx2 matrix of depth intervals, e.g. [0 50; 50 200; 200 500]

    %% --------------------------
    % Nested function: FW content
    %% --------------------------
    function FW = fw_content(S, z, H0, Sref, min_depth, max_depth)
        layers = find(abs(z) > min_depth & abs(z) < max_depth);
        FW = sum(((Sref - S(layers,:)) ./ Sref) .* H0(layers), 1);
    end

    %% Color palette
    cbColors = [
        0, 0, 0;
        230,159,0;
        86,180,233;
        0,158,115;
        240,228,66;
        0,114,178;
        213, 94, 0;
        204,121,167
    ] / 255;

    %% Model time vector
    s.date = datetime(s.t, "ConvertFrom", "datenum");

    %% Figure
    figure; hold on;

    % Labels as cell arrays
    model_labels = cell(size(depth_ranges,1),1);
    obs_labels   = cell(size(depth_ranges,1),1);
    for i = 1:size(depth_ranges,1)
        model_labels{i} = sprintf('Model: %d–%d m', depth_ranges(i,1), depth_ranges(i,2));
        obs_labels{i}   = sprintf('Obs: %d–%d m', depth_ranges(i,1), depth_ranges(i,2));
    end

    %% MODEL FW CONTENT
    for k = 1:size(depth_ranges,1)
        FW = fw_content(s.S, s.z, a.H0, Sref, depth_ranges(k,1), depth_ranges(k,2));
        plot(s.date, FW, 'LineWidth', 1.6, 'Color', cbColors(k,:), 'DisplayName', model_labels{k});
    end

    %% OBSERVATIONAL FW CONTENT
    Am.dz =  diff([0;Am.depths]);
     % Remove dates where all salinity values are NaN
    valid_dates = ~all(isnan(Am.S), 1);
    Am.dates = Am.dates(valid_dates);
    Am.S = Am.S(:, valid_dates);
    for k = 1:size(depth_ranges,1)
        FW = fw_content(Am.S, -Am.depths, Am.dz, Sref, depth_ranges(k,1), depth_ranges(k,2));
        plot(Am.dates, FW, '--', 'LineWidth',1.3, 'Color', cbColors(k,:), 'DisplayName', obs_labels{k});
        e.FW(k,:) = FW;
    end

    %% Figure formatting
    xlabel('Date'); ylabel('Freshwater Content (m)');
    legend('Location','best'); grid on;

end

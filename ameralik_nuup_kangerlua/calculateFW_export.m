function plotFWexport_depth(simFiles, simNames, Sref, depthRange)
% plotFWexport_depth(simFiles, simNames, Sref, depthRange)
% Example call:
% plotFWexport_depth(simFiles, simNames, 33.6, [0 50])

    nSims = numel(simFiles);
    sims = cell(1,nSims);

    % Load simulations
    for k = 1:nSims
        sims{k} = load(simFiles{k}, 's').s;
    end

    figure; hold on;
    colors = parula(nSims);

    figure;
    tiledlayout(2,1, "TileSpacing","compact", "Padding","compact");
    
    colors = parula(nSims);
    
    for k = 1:nSims
        s = sims{k};
        s.t_date = datetime(s.t,'ConvertFrom','datenum');
    
        % ---- Depth mask (using absolute-value logic) ----
        depthMask = abs(s.z) >= depthRange(1) & abs(s.z) <= depthRange(2);
        S = s.S(depthMask,:);
        QVs = s.QVs(depthMask,:);
    
        % ---- Total Volume Flux ----
        totalQ = sum(QVs,1)*-1;
    
        % ---- Freshwater Export ----
        FW = max((Sref - S)./Sref, 0);
        totalFW = sum(-QVs .* FW,1);
    
        % ---- Tile 1: FW export ----
        nexttile(1);
        plot(s.t_date, totalFW, 'LineWidth',1.6, 'Color',colors(k,:)); hold on;
        ylabel('FW Export (m^3/s)');
        title(sprintf('Freshwater Export (%d–%d m depth)', depthRange(1), depthRange(2)));
        grid on;
    
        % ---- Tile 2: Volume flux (QVs) ----
        nexttile(2);
        plot(s.t_date, totalQ, 'LineWidth',1.6, 'Color',colors(k,:)); hold on;
        ylabel('Volume Flux Q_V (m^3/s)');
        title('Total Volume Flux');
        grid on;
    end
    
    nexttile(1); legend(simNames, 'Location','best');
    xlabel('Time');
    nexttile(2); xlabel('Time');

    xlabel('Time');
    ylabel('Volume export (m^3)');
    title(sprintf('Volume Export (%d–%d m depth range)', depthRange(1), depthRange(2)));
    legend('Location','best');
    grid on;

end

%% Local sub-functions
function QSalt = calcFWexport_local(s, Sref)
    FW = max((Sref - s.S) ./ Sref, 0); % avoid negative FW
    QSalt = -s.QVs .* FW;  % negative = export
end

function s2 = subsetStruct(s,mask)
    s2 = s;
    s2.t_date = s.t_date(mask);
    s2.S      = s.S(:,mask);
    s2.QVs    = s.QVs(:,mask);
end


simFiles = { ...
    'ameralik_combined_Kb1e-05_C01e+04.mat',...
    'ameralik_combined_Kb1e-04_C01e+04.mat',...
    'ameralik_combined_Kb1e-03_C01e+04.mat',...
    'ameralik_combined_Kb1e-05_C01e+05.mat',...
    'ameralik_combined_Kb1e-04_C01e+05.mat',...
    'ameralik_combined_Kb1e-03_C01e+05.mat'};

simNames = { ...
    'Low mix - Low shelfX',...
    'High mix - Low shelfX',...
    'Very high mix - Low ShelfX',...
    'Low mix - High shelfX',...
    'High mix - High shelfX',...
    'Very high mix - High ShelfX'};

plotFWexport_depth(simFiles, simNames, 33.6, [0 , 30]) % 
function colors = colors_ameralik()
%% colors_ameralik.m
% Returns a struct with all color definitions for Ameralik plots.

% ── Flux colors ──────────────────────────────────────────────────────────
nFluxes    = 5;
fluxColors = parula(nFluxes);
colors.fluxColors = fluxColors;


colors.ls.VHIGH = ':';  
colors.ls.HIGH = '--';  
colors.ls.LOW = ".-";
colors.ls.OBS = '-';

colors.c_shelf_in  = [245, 100, 118]/255;
colors.c_shelf_out = fluxColors(2,:);
colors.c_shelf_net = [44, 81, 76]/255;

% ── Simulation color definitions ─────────────────────────────────────────
lighten = @(c, f) min(c + f*(1-c), 1);

c_high  = [43, 193, 180] / 255;   % #2BC1B4  (teal)
c_vhigh = [78,  65, 143] / 255;   % #4E418F  (purple)
c_low   = [221, 117, 150] / 255;  % #DD7596  (pink)

colors.c_low = c_low;
colors.c_high = c_high;
colors.c_vhigh = c_vhigh;


simNames_all = {
% ── Standard runs ──────────────────────────────────────────────────────
'Low mix - Low shelfX',
'Low mix - High shelfX',
'High mix - Low shelfX',
'High mix - High shelfX',
'Very high mix - Low ShelfX',
'Very high mix - High ShelfX',
% ── Sensitivity: no air-sea heat flux ──────────────────────────────────
'High mix - High ShelfX - No Air-Sea Heat Flux',
'Very high mix - High ShelfX - No Air-Sea Heat Flux',
% ── Sensitivity: no runoff ─────────────────────────────────────────────
'High mix - High ShelfX - No Runoff',
'Very high mix - High ShelfX - No Runoff',
};

colorsArray = [
    lighten(c_low,   0.0);   % Low mix  - Low shelfX
    lighten(c_low,   0.0);   % Low mix  - High shelfX
    lighten(c_high,  0.0);   % High mix - Low shelfX
    lighten(c_high,  0.0);   % High mix - High shelfX
    lighten(c_vhigh, 0.0);   % Very high - Low shelfX
    lighten(c_vhigh, 0.0);   % Very high - High shelfX
    lighten(c_high,  0.45);  % High mix - no air-sea
    lighten(c_vhigh, 0.45);  % Very high - no air-sea
    lighten(c_high,  0.25);  % High mix - no runoff
    lighten(c_vhigh, 0.25);  % Very high - no runoff
];

simNames_lb = {
'Low mix -\nLow shelfX',
'Low mix -\nHigh shelfX',
'High mix -\nLow shelfX',
'High mix -\nHigh shelfX',
'Very high mix -\nLow shelfX',
'Very high mix -\nHigh shelfX',
'High mix -\nNo air-sea flux',
'Very high mix -\nNo air-sea flux',
'High mix -\nNo runoff',
'Very high mix -\nNo runoff',
};

allKeys = [simNames_all(:)', simNames_lb(:)'];
allVals = [num2cell(colorsArray, 2)', num2cell(colorsArray, 2)'];

colors.simColors  = containers.Map(allKeys, allVals);
colors.simNames_all = simNames_all;
colors.simNames_lb  = simNames_lb;

% Add aliases: replace shelfX/ShelfX with Shelf Exchange like:
colors.simColors('Low mix - High Shelf Exchange') = colors.simColors('Low mix - High shelfX');
% etc
origKeys = colors.simColors.keys;

for i = 1:numel(origKeys)
    k = origKeys{i};

    newKey = strrep(k, 'shelfX', 'Shelf Exchange');
    newKey = strrep(newKey, 'ShelfX', 'Shelf Exchange');

    if ~strcmp(k, newKey)
        colors.simColors(newKey) = colors.simColors(k);
    end
end

end



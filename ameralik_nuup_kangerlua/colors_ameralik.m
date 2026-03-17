

% Number of fluxes and consistent colormap
nFluxes = 6; % river, shelf, vert top, vert base, mix top, mix base
fluxColors = parula(nFluxes); % consistent colormap for flux terms

% Example shelf colors (optional)
c_shelf_in = [245, 100, 118]/255;
c_shelf_out = fluxColors(2,:);
c_shelf_net = [44, 81, 76]/255;

% Simulation names (normal)
simNames_for_colors = {
    'Low mix - Low shelfX',
    'Low mix - High shelfX',
    'High mix - Low shelfX', 
    'High mix - High shelfX',
    'Very high mix - Low ShelfX',
    'Very high mix - High ShelfX'
};

% Corresponding RGB colors
colorsArray = lines(length(simNames_for_colors));

% Map for normal names
simColors = containers.Map(simNames_for_colors, num2cell(colorsArray, 2));

% Map for legend names with line breaks
simNames_for_colors_w_enter = {
    'Low mix -\nLow shelfX',
    'Low mix -\nHigh shelfX',
    'High mix -\nLow shelfX', 
    'High mix -\nHigh shelfX',
    'Very high mix -\nLow ShelfX',
    'Very high mix -\nHigh ShelfX'
};

simColors_w_enter = containers.Map(simNames_for_colors_w_enter, num2cell(colorsArray, 2));

% Combine both maps
simColors = containers.Map([keys(simColors), keys(simColors_w_enter)], ...
                           [values(simColors), values(simColors_w_enter)]);

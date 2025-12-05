nFluxes = 6; % river, shelf, vert top, vert base, mix top, mix base
fluxColors = parula(nFluxes); % consistent colormap for flux terms



c_shelf_in = [245, 100, 118]/255;
c_shelf_out = fluxColors(2,:);
c_shelf_net = [44, 81, 76]/255;

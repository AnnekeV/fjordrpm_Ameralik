function s = compute_fluxes(i, p, s)

% COMPUTE_FLUXES compute fluxes in the simulation.
%   s = COMPUTE_FLUXES(i, p, s) calls functions to compute the plume 
%   fluxes, shelf fluxes, mixing fluxes, iceberg fluxes and vertical 
%   fluxes for parameters structure p and solution s at timestep i.

% calculate/impose surface fluxes
[s.QVsurf(:,i), s.QTsurf(:,i), s.QSsurf(:,i)] = get_surface_fluxes(i, p, s);

% calculate plume fluxes
[s.QVp(:,:,i), s.QTp(:,:,i), s.QSp(:,:,i), ...
    s.QEp(:,:,i), s.QMp(:,:,i), s.knb(:,i)] = get_plume_fluxes(i, p, s);

% calculate shelf fluxes
[s.QVs(:,i), s.QTs(:,i), s.QSs(:,i), s.phi(:,i)] = get_shelf_fluxes(i, p, s);

% calculate tracer vertical mixing fluxes
[s.QVk(:,i), s.QTk(:,i), s.QSk(:,i), s.Ri(:,i)] = get_mixing_fluxes(i, p, s);

% calculate iceberg fluxes
[s.QVi(:,i), s.QTi(:,i), s.QSi(:,i), s.QMi(:,i)] = get_iceberg_fluxes(i, p, s);

% calculate vertical fluxes
[s.QVv(:,i), s.QTv(:,i), s.QSv(:,i)] = get_vertical_fluxes(i, s);

end

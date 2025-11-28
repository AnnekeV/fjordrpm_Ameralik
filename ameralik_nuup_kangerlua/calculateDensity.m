function [rho_theta, theta] = calculateDensity(Spractical, Tpotential)
% CALCULATEDENSITY Compute potential density and potential temperature
% assumes p=0, lon=-51, lat=64
%
% INPUTS:
%   SP  - Practical Salinity [PSU], can be a matrix (depth x time)
%   TP  - In-situ Temperature [°C], same size as SP

%
% OUTPUTS:
%   rho_theta - Potential density referenced to 0 dbar [kg/m^3]
%   theta     - Potential temperature referenced to 0 dbar [°C]


    p = 0; lon = -51; lat = 64;

    % Convert Practical Salinity to Absolute Salinity
    SA = gsw_SA_from_SP(Spractical, p, lon, lat);

    % Convert potential temperature to Conservative Temperature
    CT = gsw_CT_from_pt(SA, Tpotential);

    % Calculate potential density referenced to 0 dbar
    rho_theta = gsw_rho(SA, CT, 0);

    % Calculate potential temperature
    theta = gsw_pt_from_CT(SA, CT);
end

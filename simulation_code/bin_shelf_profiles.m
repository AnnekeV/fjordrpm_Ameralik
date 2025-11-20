function [Ts0, Ss0] = bin_shelf_profiles(Tz, Sz, z, H0, interp_method)

% BIN_SHELF_PROFILES Interpolates shelf profile to layers.
%   [Ts0, Ss0] = BIN_SHELF_PROFILES(Tz, Sz, z, H0) bins temperature (Tz)
%   and salinity (Sz) profiles to model layers (H0) and returns a "layer
%   profile" for temperature (Ts0) and salinity (Ss0).

% Set default for interp_method
if nargin < 5 || isempty(interp_method)
    interp_method = 'pchip';
end

% remove any nan entries from the shelf profiles
nan_entries = isnan(Tz) | isnan(Sz);
Tz = Tz(~nan_entries);
Sz = Sz(~nan_entries);
z = z(~nan_entries);

% add the layer boundaries H0 into the vector of shelf z-values
z0 = unique(sort([0; z; -cumsum(H0)]));

% interpolate the shelf temperature and salinitity profiles given on sample
% points z onto the new grid zs0
S0 = interp1(z,Sz,z0,interp_method,'extrap');
T0 = interp1(z,Tz,z0,interp_method,'extrap');

% calculate shelf temperature and salinity Ts0 and Ss0 on model layers
ints = [0; -cumsum(H0)];
[Ts0, Ss0] = deal(zeros(size(H0)));
for k=1:length(ints)-1
    % find the boundaries of the layer in the shelf grid z0
    inds = find(z0<=ints(k) & z0>=ints(k+1));
    % average the temperature and salinity profiles over this layer
    Ss0(k) = trapz(z0(inds),S0(inds))/H0(k);
    Ts0(k) = trapz(z0(inds),T0(inds))/H0(k);
end
      
end
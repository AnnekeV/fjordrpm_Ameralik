% Load model output
load ameralik_combined_Kb1e-05_C01e+05.mat
s2 = s;
load ameralik_combined_Kb1e-04_C01e+05_export_Kz.mat
s3 = s;


% Assumes:
% load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-05_C01e+05_test2.mat; s2 = s;
% load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-04_C01e+05_test3_full_depth.mat; s3 = s;

% Extract t,z,S
t2 = s2.t(:); z2 = s2.z(:); S2 = s2.S;
t3 = s3.t(:); z3 = s3.z(:); S3 = s3.S;

% Ensure S arrays orientation: rows = z, cols = t
% If S is given as (t x z) transpose accordingly
if size(S2,1) == numel(t2) && size(S2,2) == numel(z2)
    S2 = S2';
end
if size(S3,1) == numel(t3) && size(S3,2) == numel(z3)
    S3 = S3';
end

% Create meshgrids for each dataset: X = t (cols), Y = z (rows)
[T2,Z2] = meshgrid(t2, z2);
[T3,Z3] = meshgrid(t3, z3);

% Interpolate S3 onto t2,z2 grid if grids differ
if ~isequal(size(T2), size(T3)) || any(abs(T2(:)-T3(:))>0) || any(abs(Z2(:)-Z3(:))>0)
    S3_on_2 = interp2(T3, Z3, S3, T2, Z2, 'linear');
else
    S3_on_2 = S3;
end

% Difference
Sdiff = S3_on_2 - S2;

% Plot
figure('Color','w','Position',[100 100 1200 420]);

% Common color limits for S plots
clim = [min([S2(:); S3_on_2(:)]), max([S2(:); S3_on_2(:)])];

subplot(1,3,1)
contourf(T2, Z2, S2, 30, 'LineColor','none')
set(gca,'YDir','normal') % ensure z increases upward; set 'reverse' if depth increases downward
% xlabel('t'); ylabel('z'); title('s2.S')
axis tight
caxis(clim)
colormap(gca,parula)
colorbar

subplot(1,3,2)
contourf(T2, Z2, S3_on_2, 30, 'LineColor','none')
set(gca,'YDir','normal')
% xlabel('t'); ylabel('z'); title('s3.S (on s2 grid)')
axis tight
caxis(clim)
colormap(gca,parula)
colorbar

subplot(1,3,3)
maxabs = prctile(abs(Sdiff(:)), 99);
contourf(T2, Z2, Sdiff, 40, 'LineColor','none')
set(gca,'YDir','normal')
% xlabel('t'); ylabel('z'); title('s3.S - s2.S')
axis tight
caxis([-maxabs maxabs])
colormap(gca,redbluecmap)
colorbar

% Local helper colormap
function cmap = redbluecmap()
    n = 64;
    r = [linspace(0,1,ceil(n/2)), linspace(1,0,floor(n/2))]';
    g = [linspace(0,1,ceil(n/2)), linspace(1,0,floor(n/2))]';
    b = [linspace(1,1,ceil(n/2)), linspace(1,0,floor(n/2))]';
    cmap = [r g b];
end


sz = size(s.Ri);
ncols = sz(2);
% Plot
figure('Color','w');
idx = 1:100:ncols;
Rsub = s3.Ri(:, idx);
contourf(idx,  s3.z, Rsub, 30, 'LineColor','none')
axis tight
clear title    % remove variable if present
ax = gca;
title(ax, 'Richardson number tidal', 'FontWeight','bold','FontSize',12);
colormap(parula)
colorbar

sz = size(s.Ri);
ncols = sz(2);
% Plot
figure('Color','w');
idx = 1:100:ncols;
Rsub = s2.Ri(:, idx);
contourf(idx,  s3.z, Rsub, 30, 'LineColor','none')
axis tight
clear title    % remove variable if present
ax = gca;
title(ax, 'Richardson number not tidal', 'FontWeight','bold','FontSize',12);
colormap(parula)
colorbar


%==== N2

figure()

gp = p.g.*(p.betaS.*(s3.S(2:end, :)-s3.S(1:end-1, :))-p.betaT.*(s3.T(2:end, :)-s3.T(1:end-1, :)));
dh = s3.H(2:end)+s3.H(1:end-1);
N2 = 2.*gp./dh;


below_z = abs(s3.z) >100
below_z_min1 = below_z(1:end-1)

figure()
contourf(s3.t, s3.z(below_z_min1), gp(below_z_min1, :))
axis tight
clear title    % remove variable if present
ax = gca;
title(ax, 'gp', 'FontWeight','bold','FontSize',12);
colormap(parula)
colorbar


figure()
contourf(s3.t, s3.z(1:end-1), N2, linspace(-1e-6, 2e-6, 31))
axis tight
clear title    % remove variable if present
ax = gca;
title(ax, 'N2', 'FontWeight','bold','FontSize',12);
colormap(parula)
colorbar


%N2/dudz
dudz = p.u_tide_max/p.dz_distribution_scale ;






Ri = N2./dudz^2;


%==== Ri
levels = linspace(-1, 2, 31);   % 30 intervals
contourf(s3.t, s3.z(1:end-1), Ri, levels, 'LineColor','none')
colormap(parula(30))
caxis([-1 5])
title(ax, 'Ri before', 'FontWeight','bold','FontSize',12);
colorbar

Ri(Ri>p.Ri0) = p.Ri0;

figure()
contourf(s3.t, s3.z(1:end-1), Ri)
axis tight
clear title    % remove variable if present
ax = gca;
title(ax, 'Ri middle', 'FontWeight','bold','FontSize',12);
colormap(parula)
colorbar


Ri(Ri<0) = 0;

figure()
contourf(s3.t, s3.z(1:end-1), Ri)
axis tight
clear title    % remove variable if present
ax = gca;
title(ax, 'Ri after', 'FontWeight','bold','FontSize',12);
colormap(parula)
colorbar

Kz = p.Kb + (Ri<p.Ri0 & Ri>=0)*p.K0.*(1-(Ri/p.Ri0).^2).^3;



figure()
contourf(s3.t, s3.z(1:end-1), Kz)
axis tight
clear title    % remove variable if present
ax = gca;
title(ax, 'Kz', 'FontWeight','bold','FontSize',12);
colormap(parula)
colorbar

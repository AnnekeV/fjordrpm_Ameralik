% Calculating tidal mixing a posteriori from mat output file 
% to determine whether mixing coefficients are in the right ball park
% U max inspired by ACEXR Gillibrand 2015/16?


close all; clear;




%% load
load ../ameralik_nuup_kangerlua/ameralik_combined_Kb1e-05_C01e+05.mat
s.t_date = datetime(s.t, "ConvertFrom","datenum");

H0 =  p.Hsill; % p.Hsill ; % m thickness  of upper layer water depth of sil
h0 =  p.H-H0 ; % m height of sill


% Parameters
T = (12 + 25/60)*60*60;   % tidal period (s), M2 tide
A = 2;                   % tidal amplitude (m)

% Range of H0 (upper layer depth over sill)
H0_graph = linspace(1,700,500);   % m
A_upstream = p.W* p.L;
Xarea_sill_graph = H0_graph *p.W;
Xarea_sill = p.Hsill*p.W;


% Velocity over sill
u_sill_graph = (2*pi .* A_upstream .* A) ./ (Xarea_sill_graph .* T);
u_tide = (2* pi *A_upstream* A) /(Xarea_sill *T);



%% set z as 

dz_mixing_scale = p.Hsill + (p.H-p.Hsill)/3;
dz_distribution_scale = dz_mixing_scale;
du = u_tide * (abs(s.z)<dz_distribution_scale);
dudz = du ./ dz_mixing_scale ;


%% Calculate utide with fixed u-tide
% z = 110; % m÷

% u_tide =1
% du = u_tide * ones(size(s.z)); % only above sill depth
% dudz = du/dz;




% required variables at timestep i
H0 = s.H; % depth per layer
T0 = s.T;
S0 = s.S;

% the net volume mixing fluxes are always zero
QVk0 = 0*H0;

% reduced gravity between layers
gp = p.g*(p.betaS*(S0(2:end,:)-S0(1:end-1,:))-p.betaT*(T0(2:end,:)-T0(1:end-1,:)));

dh = H0(2:end)+H0(1:end-1);
N2 = 2.*gp./dh;

% richardson number
Ri = N2./(dudz(1:end-1).^2);
Ri(du==0) = p.Ri0;
Ri(Ri>p.Ri0) = p.Ri0;
Ri(Ri<0) = 0;

% get diffusivity as a function of the Richardson number
Kz = p.Kb + (Ri<p.Ri0 & Ri>=0)*p.K0.*(1-(Ri/p.Ri0).^2).^3;



% % compute the mixing fluxes going in/out of each layer.
% QS = 2*p.W*p.L*Kz.*(S0(2:end)-S0(1:end-1))./(H0(2:end)+H0(1:end-1));
% QT = 2*p.W*p.L*Kz.*(T0(2:end)-T0(1:end-1))./(H0(2:end)+H0(1:end-1));

% % the final layer fluxes are the net of the interface fluxes
% QTk0 = [QT;0]-[0;QT];
% QSk0 = [QS;0]-[0;QS];



%% Plot Figure 1 : U max sill dependent on sill depth
figure
plot( u_sill_graph,H0_graph,  'LineWidth', 2)
grid on
ylabel(['Sill depth (m)'])
xlabel('u_{sill} (m s^{-1})')
title('Sill Velocity as a Function of Upper-Layer Depth')



%% Figure 2: Buoyancy frequency squared N2
figure;
[C, h] = contourf(s.t, s.z(1:end-1), N2);
clabel(C, h, 'FontSize', 8, 'Color', 'k', 'LabelSpacing', 200);
set(gca,'colorscale','log')
ylabel('Depth (m)')
xlabel('Time')
title('Buoyancy Frequency Squared N^2')
xt = linspace(s.t(1), s.t(end), 25);
xticks(xt)
xticklabels(cellstr(datestr(xt, 'yyyy-mm-dd HH:MM')))
c = colorbar;
c.Label.String = 'N^2 (s^{-2})';



%% Figure 3: Richardson number Ri
figure;
pcolor(s.t, s.z(1:end-1), Ri)
shading interp   % smooth the pcolor plot
colorbar
ylabel('Depth (m)')
xlabel('Time')
title('Gradient Richardson Number Ri')

xticks(xt)
xticklabels(cellstr(datestr(xt, 'yyyy-mm-dd HH:MM')))

c = colorbar;
c.Label.String = 'Ri';




%% Figure 4: Turbulent diffusivity Kz
figure;
contourf(s.t, s.z(1:end-1), Kz)
set(gca,'colorscale','log')
ylabel('Depth (m)')
xlabel('Time')
title('Turbulent Diffusivity K_z due to tides (a posteriori tidal mixing)')

xticks(xt)
xticklabels(cellstr(datestr(xt, 'yyyy-mm-dd HH:MM')))

c = colorbar;
c.Label.String = 'K_z (m^2/s)';
c.Label.Interpreter = 'none';


exportgraphics(gcf, 'tidal_mixing_Kz_a_posteriori.png', 'Resolution', 300);

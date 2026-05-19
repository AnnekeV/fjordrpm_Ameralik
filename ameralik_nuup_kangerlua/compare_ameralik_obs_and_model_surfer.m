
close all;
%% Load data
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_mean_daily.mat'); 
load(    'ameralik_combined_Kb1e-04_C01e+05.mat')  % tidal


%% Load data
load('/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/data/interim/Ameralik_mean_daily.mat'); 

folderfig = '/Users/annek/Library/CloudStorage/OneDrive-SharedLibraries-NIOZ/PhD Anneke Vries - General/fjord_modelling_ameralik/figures/Comparison_obs_model_Surfer_plots';

densities_shallow = [23, 24, 25, 26, 26.3, 26.5, 26.6, 26.7];
densities_deep = [26, 26.3, 26.5, 26.6, 26.7];

%% --- Run 1 ---

load('ameralik_combined_Kb1e-04_C01e+05.mat')  

fig = plotCompareObsModelSurfer(AM5, s, 'rho', densities_deep, 700, [1024.5, 1027])
exportgraphics(fig, fullfile(folderfig,'rho_deep_Kb1e-04.png'),'Resolution',300)
exportgraphics(fig, fullfile(folderfig,'rho_deep_Kb1e-04.pdf'),'Resolution',300)

fig = plotCompareObsModelSurfer(AM5, s, 'rho', densities_shallow, 50);
exportgraphics(fig, fullfile(folderfig,'rho_shallow_Kb1e-04.png'),'Resolution',300)
exportgraphics(fig, fullfile(folderfig,'rho_shallow_Kb1e-04.pdf'),'Resolution',300)


%% --- Load second model ---
load('ameralik_combined_Kb1e-03_C01e+05.mat')  

fig = plotCompareObsModelSurfer(AM5, s, 'rho', densities_deep, 700);
exportgraphics(fig, fullfile(folderfig,'rho_deep_Kb1e-03.png'),'Resolution',300)
exportgraphics(fig, fullfile(folderfig,'rho_deep_Kb1e-03.pdf'),'Resolution',300)

fig = plotCompareObsModelSurfer(AM5, s, 'rho', densities_shallow, 50);
exportgraphics(fig, fullfile(folderfig,'rho_shallow_Kb1e-03.png'),'Resolution',300)
exportgraphics(fig, fullfile(folderfig,'rho_shallow_Kb1e-03.pdf'),'Resolution',300)
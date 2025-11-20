function plotrpm_no_glacier(p, s, a, nplot, model_summary_title)

% PLOTRPM makes summary plots after the model has run.

set(groot, 'DefaultAxesFontSize', 14);
set(groot, 'DefaultTextFontSize', 16);
%% time vectors

a.A0v = a.H0*p.W; %area vertical

% time vectors
s.t_date = datetime(s.t, 'ConvertFrom','datenum');
s.t_start = datetime(s.t(1), 'ConvertFrom','datenum', 'Format','d MMM yyyy');
s.t_days_since_start = s.t - s.t(1);

% time indices to plot
ip = [1:max(1,round(length(s.t_days_since_start)/nplot)):length(s.t_days_since_start)];

% colourmaps
cmapt = parula(length(ip));
cmapz = parula(length(s.z));

% line width
lw = 2;

%% ONE BIG FIGURE
figure();
bigTile = tiledlayout(3, 4);   % 14 slots total
title(bigTile, model_summary_title)
bigTile.TileSpacing = 'compact';
bigTile.Padding = 'compact';

%% TEMPERATURE ------------------------------------------------------------

% fjord profiles
nexttile(bigTile); hold on;
for i=1:length(ip)
    plot(s.T(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('temperature (C)'); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt); 
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);
ylabel(h, sprintf('time (days since %s)', char(s.t_start))); 
ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('FJORD TEMPERATURE');

% fjord time series
nexttile(bigTile); hold on;
for i=1:length(s.z)
    plot(s.t_date,s.T(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
ylabel('temperature (C)');
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('FJORD');

% shelf profiles
nexttile(bigTile); hold on;
for i=1:length(ip)
    plot(s.Ts(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('temperature (C)'); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt);
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);
ylabel(h, sprintf('time (days since %s)', char(s.t_start))); 
ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('SHELF');

% shelf time series
nexttile(bigTile); hold on;
for i=1:length(s.z)
    plot(s.t_date,s.Ts(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
ylabel('temperature (C)');
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('SHELF');

%% SALINITY ---------------------------------------------------------------

% fjord profiles
nexttile(bigTile); hold on;
for i=1:length(ip)
    plot(s.S(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('salinity'); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt); 
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);
ylabel(h, sprintf('time (days since %s)', char(s.t_start))); 
ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('FJORD SALINITY');

% fjord time series
nexttile(bigTile); hold on;
for i=1:length(s.z)
    plot(s.t_date,s.S(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
ylabel('salinity');
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('FJORD');

% shelf profiles
nexttile(bigTile); hold on;
for i=1:length(ip)
    plot(s.Ss(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('salinity'); ylabel('depth (m)');
h = colorbar; colormap(gca,cmapt);
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);
ylabel(h,sprintf('time (days since %s)', char(s.t_start))); 
ylim([-p.H,0]);
set(gca,'box','on'); grid on; title('SHELF');

% shelf time series
nexttile(bigTile); hold on;
for i=1:length(s.z)
    plot(s.t_date,s.Ss(i,:),'color',cmapz(length(s.z)-i+1,:),'linewidth',lw);
end
ylabel('salinity');
h = colorbar; colormap(gca,cmapz); caxis([-p.H,0]);
ylabel(h,'depth (m)');
set(gca,'box','on'); grid on; title('SHELF');

%% VOLUME FLUXES ----------------------------------------------------------

s.QVp = squeeze(sum(s.QVp,1)); % multiple plumes
s.UVs = s.QVs ./ a.A0v;         % mean velocity

% shelf exchange velocity
nexttile(bigTile); hold on;
for i=1:length(ip)
    plot(s.UVs(:,ip(i)),s.z,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('exchange velocity (m/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); 
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);
ylabel(h,sprintf('time (days since %s)', char(s.t_start))); 
ylim([-p.Hsill-10,0]);
% after plotting and before finalizing axes
ax = gca;

% bottom-left
text(0.01, 0.02, sprintf('out of\nfjord'), ...
    'Units','normalized', ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','bottom', ...
    'FontSize',10, ...
    'Parent',ax);

% bottom-right
text(0.98, 0.02, sprintf('into of\nfjord'), ...
    'Units','normalized', ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'FontSize',10, ...
    'Parent',ax);

set(gca,'box','on'); grid on; title('SHELF FLUXES');

a.A0h = p.L *p.W;  % horizontal area width*length
% vertical advection
ints = -[0;cumsum(s.H(1:end-1))];
nexttile(bigTile); hold on;
for i=1:length(ip)
    Qint = -cumsum(s.QVv(:,ip(i)),'reverse');
    s.UVv = Qint ./ a.A0h;  % convert to exchagne velocity
    plot(s.UVv,ints,'color',cmapt(i,:),'linewidth',lw);
end
xlabel('exchange velocity (m/s)'); ylabel('depth (m)');
h = colorbar; colormap(cmapt); 
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);
ylabel(h,sprintf('time (days since %s)', char(s.t_start))); 
ylim([-p.Hsill-10,0]);
set(gca,'box','on'); grid on; title('VERTICAL ADVECTIVE');

%% FRESHWATER -------------------------------------------------------------

% total fluxes
nexttile(bigTile); hold on;
plot(s.t_date,s.Qr,'linewidth',lw);
ylabel('total flux (m$^3$/s)');
legend('river','location','best');
title('freshwater inputs');
set(gca,'box','on'); grid on;

% air temperature
nexttile(bigTile); hold on;
plot(s.t_date, s.Ta, 'linewidth', lw);
ylabel('Air temperature (°C)');
title('Air Temperature');
box on; grid on;

end

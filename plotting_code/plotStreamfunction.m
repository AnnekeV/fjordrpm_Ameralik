load('ameralik_combined_with_spinup_strong_mixing.mat'); 

s.t_date = datetime(s.t, 'ConvertFrom','datenum');

s.t_start = datetime(s.t(1), 'ConvertFrom','datenum', 'Format','d MMM yyyy');
s.t_days_since_start = s.t - s.t(1);

nplot=25;

ip = [1:max(1,round(length(s.t)/nplot)):length(s.t)];


s.A0v = s.H*p.W; %area vertical
s.UVs = s.QVs ./ s.A0v;         % mean velocity
s.Y = cumsum(s.UVs.*s.H);

% colourmaps
cmapt = parula(length(ip));

figure();hold on;
for i=1:length(ip)
    plot(s.Y(:,ip(i)),s.z, 'color',cmapt(i,:),'linewidth',2);
end
ylim([-p.Hsill-10 0])
h = colorbar; colormap(gca,cmapt);
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);

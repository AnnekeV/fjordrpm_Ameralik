load('ameralik_combined_with_spinup.mat'); 

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
cmapt = repmat(parula(ceil(length(ip)/2)), 2,1);


figure();hold on;
for i=1:length(ip)
    plot(s.Y(:,ip(i)),s.z, 'color',cmapt(i,:),'linewidth',2);
end
ylim([-p.Hsill-10 0])
h = colorbar; colormap(gca,cmapt);
caxis([min(s.t_days_since_start),max(s.t_days_since_start)]);



ax.Units = 'normalized';   % not required, but ensures consistency

% Add corner labels (normalized coordinates)
text(0.01, 0.99, 'in at top',    'Units','normalized', 'HorizontalAlignment','left',  'VerticalAlignment','top');
text(0.99, 0.99, 'out at top',   'Units','normalized', 'HorizontalAlignment','right', 'VerticalAlignment','top');
text(0.01, 0.01, 'out at bottom','Units','normalized', 'HorizontalAlignment','left',  'VerticalAlignment','bottom');
text(0.99, 0.01, 'in at bottom', 'Units','normalized', 'HorizontalAlignment','right', 'VerticalAlignment','bottom');

% Optional styling
% set(findall(gca,'Type','text'),'FontSize',10,'FontWeight','bold','Color','k')

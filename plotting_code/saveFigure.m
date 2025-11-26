function saveFigure(fig, filename, width, height, dpi)
% saveFigure Save a figure with specified size, resolution, and output format
%
%   saveFigure(fig, filename, width, height, dpi)
%
%   fig      : figure handle
%   filename : full file name, including extension (.png, .jpg, .pdf, ...)
%   width    : width in inches
%   height   : height in inches
%   dpi      : resolution for export (e.g., 300) [optional]

    if nargin < 5
        dpi = 300; % default dpi
    end

    % Ensure the directory exists
    folder = fileparts(filename);
    if ~isempty(folder) && ~isfolder(folder)
        mkdir(folder);
    end

    % Normalize extension
    [~,~,ext] = fileparts(filename);
    ext = lower(ext);

    % Map extension to MATLAB print device
    switch ext
        case '.png'
            device = '-dpng';
        case {'.jpg', '.jpeg'}
            device = '-djpeg';
        case '.tif'
            device = '-dtiff';
        case '.pdf'
            device = '-dpdf';
        case '.eps'
            device = '-depsc';
        case '.svg'
            device = '-dsvg';
        otherwise
            error('Unsupported file extension: %s', ext);
    end

    % Set figure size
    set(fig, 'Units', 'inches');
    set(fig, 'Position', [1 1 width height]);

    % Set paper size
    set(fig, 'PaperUnits', 'inches');
    set(fig, 'PaperPosition', [0 0 width height]);
    set(fig, 'PaperSize', [width height]);

    % Export
    print(fig, filename, device, ['-r' num2str(dpi)]);

end

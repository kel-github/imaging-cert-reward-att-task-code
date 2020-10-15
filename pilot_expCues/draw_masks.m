function [] = draw_masks(wh, rect, sc, peak, bg, glb_alph)
% inputs
% ----------------------------------------------------
% wh       = window handle
% rect     = rects for texture presentation
% sc       = scaling factor
% peak     = highest value for mask noise
% bg       = background colour
% glb_alph = global alpha - set to 0 for no masks (i.e. transparent)
             % and to 1 for mask present

    rw = rect(3) - rect(1);
    rh = rect(4) - rect(2);
    [x, y] = meshgrid(1:rw, 1:rh);
    f = exp(-((x-rw/2).^2 + (y-rh/2).^2)/(2*sc^2));
%     noise_matrix = floor(((white-grey)*rand(rw, rh)) .* f) + grey;
    noise_matrix = floor(((peak-bg)*(rand(rw, rh)*2-1)) .* f) + bg;
    noise = Screen('MakeTexture', wh, noise_matrix);
    xy_pos = get_positions(wh, 1:2);
    xy_diff = repmat([rw/2; rh/2], 1, size(xy_pos, 2));
    rects = [xy_pos - xy_diff; xy_pos + xy_diff];
    Screen('DrawTextures', wh, noise, [], rects, [], 0, glb_alph);
end

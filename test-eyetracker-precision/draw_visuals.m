function []=draw_visuals(wh, fixcolour, rectcolour, trackrect)

ppd = get_ppd();
[w, h] = Screen('WindowSize', wh);
xc = round(w / 2);
yc = round(h / 2);
radius = 0.8*ppd;

% draw fixation cross
scale = 0.5;
lines = [-radius, radius, 0, 0;
          0, 0, -radius, radius];
lines = scale * lines;
lo = repmat([xc; yc], 1, size(lines, 2));
lines = lines + lo;
Screen('DrawLines', wh, lines, 2, fixcolour);
% draw the region in which you want to make sure the eyes stay/your limits
Screen('FrameRect', wh, rectcolour, trackrect, 1);
end
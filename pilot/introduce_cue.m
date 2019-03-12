function [] = introduce_cue(wh, colour, idx)

draw_stim(wh, idx, colour);
Screen('Flip', wh);

WaitSecs(0.5);
start_ts = KbWait;

WaitSecs(0.5);

end
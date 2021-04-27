function [] = introduce_cue(wh, colour, idx, txt_rcts, probs, white)

draw_stim(wh, idx, colour);
Screen('DrawText', wh, sprintf('%d %', probs(1)*100), txt_rcts(1,1), txt_rcts(2,1), white);
Screen('DrawText', wh, sprintf('%d %', probs(2)*100), txt_rcts(1,2), txt_rcts(2,2), white);

Screen('Flip', wh);

WaitSecs(0.5);
start_ts = KbWait;

WaitSecs(0.5);

end
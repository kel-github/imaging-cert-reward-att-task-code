function [time] = get_time_in_frames(input, ifi)
% K. Garner, 2020
% given the input structure and ifi, gives time, a structure
% that has the desired timing in frames

time.blockdur = round(input.blockdur/ifi);
time.offdur = round(5/ifi);
end
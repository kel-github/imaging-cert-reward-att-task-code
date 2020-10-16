function [] = plot_data(r, rf)

subplot(1,2,1)
histogram(r, 20);
title('distance eyelink x,y from center x,y');

subplot(1,2,2);
bar([1-mean(rf), mean(rf)]);
title('proportion distance > boundary');
end
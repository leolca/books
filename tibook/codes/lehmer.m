p = 3;

function r = randomnumber(n,p)
% r = randomnumber(n,p)
% creates a vector of n random numbers using p as multiplying factor (default = 65539)
  if nargin < 2, p = 65539; endif
  r = 1;
  for i = 2 : n,
    r(i) = mod(p * r(i-1),2^32);
  endfor
endfunction

function I = rndnum2matrix(r)
  for i = 1 : length(r),
     nb = dec2bin(r(i),32);
     I(i,:) = str2num(regexprep(nb(end-31:end),'(.)',' $0'));
  endfor
endfunction

r = randomnumber(200,p);
I = rndnum2matrix(r);

f = figure("position",get(0,"screensize")./[1 1 2 3]);
subplot('position',  [0.05, 0.02, 0.125, 1]);
imagesc(I); colormap(1 - colormap('gray')); axis ("ticy");
subplot('position',  [0.25, 0.25, 0.4, 0.6]);
plot(r);
box off;
%annotation('textbox',[0.4 0.05 0.1 0.1],'string',sprintf(' multiplier %d',p));
annotation('textbox', [0.4 0.05 0.1 0.1], ...
           'String', sprintf(' multiplier %d', p), ...
           'EdgeColor', 'none');
subplot('position',  [0.65, 0.25, 0.5, 0.5]);
plot(r(1:2:end),r(2:2:end),'kx'); axis ("off","square"); title('X_k \times X_{k+1}');


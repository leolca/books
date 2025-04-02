% Define the joint probability matrix P(X,Y)
P = [1/4, 1/8, 1/16;    % Row for x1
     1/8, 1/16, 1/32;   % Row for x2
     1/16, 1/32, 1/4];  % Row for x3

% Verify the sum of probabilities equals 1
total_sum = sum(sum(P));
printf("Sum of probabilities: %.4f (should be 1)\n", total_sum);

% Compute joint entropy H(X,Y)
% H(X,Y) = -sum(P(x,y) * log2(P(x,y))) over all elements
% Replace 0 probabilities with a small value to avoid log(0), but here all are > 0
H_XY = -sum(sum(P .* log2(P)));
printf("Joint entropy H(X,Y): %.4f bits\n", H_XY);

% Compute marginal probabilities P(X) and P(Y)
P_X = sum(P, 2);  % Sum over columns (Y) for each X
P_Y = sum(P, 1);  % Sum over rows (X) for each Y

% Compute marginal entropy H(X)
H_X = -sum(P_X .* log2(P_X));
printf("Marginal entropy H(X): %.4f bits\n", H_X);

% Compute marginal entropy H(Y)
H_Y = -sum(P_Y .* log2(P_Y));
printf("Marginal entropy H(Y): %.4f bits\n", H_Y);

% Compute conditional entropy H(Y|X)
% H(Y|X) = H(X,Y) - H(X)
H_Y_given_X = H_XY - H_X;
printf("Conditional entropy H(Y|X): %.4f bits\n", H_Y_given_X);

% Verify the chain rule: H(X,Y) = H(X) + H(Y|X)
chain_rule_check = H_X + H_Y_given_X;
printf("Chain rule check H(X) + H(Y|X): %.4f (should equal H(X,Y) = %.4f)\n", chain_rule_check, H_XY);

% hyperplane: a list of feature weights describing a hyperplane
% datapoints: a list of 1s or 0s denoting the datapoints to use in calculating decision cost
% featuresp: a list of 1s or 0s denoting the features to use in calculating decision cost
% costn: a list of real values denoting the cost to use features
% Returns the decision cost associated with placing a hyperplane. The decision cost
% is the sum of the cost of misclassifying data points + the cost of applying 
% features to a population
% dc: the decision cost of placing this hyperplane
function [dc] = getDC (hyperplane, datapoints, featuresp, costn)
	global population;
	global k;
	dc = 0;

	
	% Perform hyperplane tests for the population at the node.

	% Get the datapoint attributes(have to invert the class 1 because of how 
	                               % they get stored in A matrix of Population)
	dps = [population.A(1:population.numClass0,1:population.F); 
			population.A((population.numClass0+1):population.M,1:population.F) * -1];

	% perform the hyperlane test on all datapoints we will use in this test
	% by multiplying the hyperplane weights against the datapoint attributes and summing
	%  class0 must be < 0 and class1 must be > 0
	hyperplaneTests = dps*hyperplane(1:population.F) .*datapoints';
	misclassified0 = hyperplaneTests(1:population.numClass0) > 0 ;
	misclassified1 = hyperplaneTests(population.numClass0+1:population.M) < 0 ;
	
	% dc = the used features * the size of the population at the node +
	% 		the total misclassied class0 * their misclassification cost +
	% 		the total misclassied class1 * their misclassification cost +
	dc = (sum(datapoints)*sum(featuresp.*costn) + 
	      sum(misclassified0)*population.mc(1) + 
	      sum(misclassified1)*population.mc(2));

end

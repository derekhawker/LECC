% dsId: dataset id. Refers to a line number in the dataset locations tables. 
% datac: a Population structure with the LP memebers for use by linprog 
function [datac] = createPopulation (dsId, fc_file="", mc_file="", \
				     data_file="")
  %% Either create a population from a listed dataset or create
  %% a population from the provided files
  if(dsId == 0)
    rawInstanceData=load(data_file);
    fc=load(fc_file);
    mc=load(mc_file);
  else	     
    % load table of dataset files
    [datasetFiles, fcFiles, mcFiles] = \
    textread('./inc/datasetLocationsTable.txt', '%s %s %s');
    
    % load dataset (instance data, feature costs, and misclassification costs
    fc = load (fcFiles{dsId});
    mc= load (mcFiles{dsId});
    rawInstanceData = load (datasetFiles{dsId});
  end


  % keep count of the number of class 0 and class 1 datapoints. Type 0 constraints
  % are at beginning of A matrix, Type 1 go at the end.
  numClass0 = 0;
  numClass1 = 0;

  % M = number of instances
  M = size(rawInstanceData);
  M = M(1);

  % the number of feature variable is the number of columns in the 
  % raw dataset file. This adds an extra variable because of the class column, but
  % and extra is needed anyways because of the feature variable w_0
  F = size(rawInstanceData);
  F  = F(2); 

  % Total variables in LP =  feature variables + elastic variables(1 for each
  % instance)
  N=F+M;


  % Create datapoint constraints 
  % TYPE 0 A(i) = SUM of attributes(from dataset for datapoint i) -e_i< w_0-1  
  % TYPE 1 A(i) = SUM of attributes(from dataset for datapoint i) +e_i> w_0+1 

  % create all constaints assuming type 0  
  A= [rawInstanceData(:,1:F-1) repmat([-1],M,1) repmat([0],M,M)];

  % Class 1 datapoints have to be multiplied by -1 ebcause they are greater than
  % type, but linprog expect all constraints to be less than type
  for i = 1:M
    % check if instance belongs to class 1
    if (rawInstanceData(i,F) == 1)
      A(i,:) = A(i,:) *-1;
    end
    % Add elastic variables for each row(instance)
    A(i,i+F)=-1; 
  end


  % rhs of all constraints is -1(even class 1 because we turned it to a <= constraint)
  b= [repmat([0],M,1)];
  for i = 1:M
    b(i) = -1;
  end

  % Not using these anymore  
  Aeq = [];
  % Aeq=[repmat([0],F-1,M+F)];
  % for i = 1:F-1
  %   Aeq(i,i)=1;
  % end

  beq = [];
  % beq = [repmat([0.0],F-1,1)];


  % objective function 
  % weighted sinf = SUM of elastic variables mutliplied by the misclassification cost
  % for the instance the elastic variable belongs to.
  f = [repmat([0],N,1)];
  for i = 1:M
    % determien the class
    if (rawInstanceData(i,F) == 0)
      numClass0 = numClass0 + 1;
      f(F+i) = mc(1);
    else 
      numClass1 = numClass1 + 1;
      f(F+i) = mc(2);
    end
  end


  lb = [repmat([0],N,1)];
  for i = 1:F
    lb(i) = -Inf;
  end
  lb(1:F-1) = 0; % Add all feature constraints

  ub = [repmat([Inf],N,1)];
  ub(1:F-1) = 0; % Add all feature constraints


  % Init the population struct using the values created above 
  datac = struct('F', F, 
		 'M', M,
		 'N', N,
		 'f', f,
		 'numClass0', numClass0,
		 'numClass1', numClass1,
		 'A', A,
		 'b', b,
		 'Aeq', [],
		 'beq', [],
		 'lb', lb,
		 'ub', ub,
		 'fc',fc,
		 'mc',mc,
		 'dsId',dsId,
		 'lpsSolved',0);
end

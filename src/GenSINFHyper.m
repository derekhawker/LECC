%% Generate SINF Hyperplane
%% SINF hyperplane generating function.
%% [desc0, desc1, hyperplane]= GenSINFHyper(node)
%% Inputs:
%% node Node structure containing the details of the node for which we
%% are generating a separating hyperplane.
%% Outputs:
%% desc1 Population structure containing the basic node for the points classified as class 1.
%% desc0 Population structure containing the basic node for the points classified as class 0.
%% hyperplane A vector of feature variables w0...F representing the
%% generated hyperplane.

function [ldesc rdesc hyperplane] = GenSINFHyper(node)
  global population;
  global k;
  %% create a temporary population to work with
  newNode = node;

  printf('SELECT INITIAL FEATURES\n')
  % Select initial feature(s)
  [newNode.featuresp] = selectInitFeatureChinneckInt(node);


  %% Initial setup
  %%printf('SETUP CONSTRAINTS\n')
  %% Setup feature constraints
  for i = 1:population.F-1
    %% if a feature was selected then release its constraints, otherwise
    %% constrain the feature
    if(newNode.featuresp(i) == 1)
      population.lb(i)=-Inf;
      population.ub(i)=Inf;
    else
      population.lb(i)=0;
      population.ub(i)=0;
    end
  end

  %%printf('SETUP DATAPOINTS\n')
  %% Setup datapoint constraints
  for i = 1:population.M
    %% if a point is in the current node, add the appropriate
    %% coefficient 1 to the objective function.  Otherwise set
    %% the corresponding coefficient to zero
    if(node.datapoints(i) == 1)
      population.f(i+population.F) = 1;
    else
      population.f(i+population.F) = 0;
    end
  end

  fval = Inf;
  c = 0;
  num_removed=0;

  while fval ~= 0
    %% If a feature c has been selected from the candidate process, remove that constraint
    %% permanently
    if(c ~= 0)
      %%    printf('\nPermanently remove constraint %d\n', c);
      if(c <= population.F)
	%% Remove feature constraint (add feature) by releasing the
	%% feature constraint
	newNode.featuresp(c) = 1;
	population.lb(c)=-Inf;
	population.ub(c)=Inf;
      else
	%% Remove datapoint constraint (remove datapoint), remove it
	%% from the objective function and from the list of datapoints
	%% at this node
	population.f(c) = 0;
	num_removed=num_removed+1;
	newNode.datapoints(c-population.F) = 0;
      end
    end
    

    %% Solve LP for min SINF
    %%printf('Solve LP for MIN SINF\n')
    [x fval exitflag output lambda] = linprog(population.f, population.A, \
					      population.b, population.Aeq, \
					      population.beq, population.lb, \
					      population.ub);

    SINF = fval;


    %% Check to see if it is a separating hyperplane
    if (SINF == 0)
      %% Exit, return two nodes
       
      %% Update the costs for the new nodes
      for i = 1:population.F-1
	%% if a feature was used, it is now free
	if(newNode.featuresp(i) == 1 && newNode.costn(i)~=0)
	  newNode.costn(i) = 0;
	end
      end

      %% Put correct featuresp and costn in each descendant
      ldesc= newNode;
      ldesc.class = k.CLASS_0;
      rdesc= newNode;
      rdesc.class = k.CLASS_1;

      %% Put the correct datapoints in the correct node
      ldesc.datapoints = zeros(1,population.M);
      rdesc.datapoints = zeros(1,population.M);
      ldesc.numMisClassified = 0;
      rdesc.numMisClassified = 0;
      %%     ldesc.dataCount = 0;
      %%     rdesc.dataCount = 0;
      for i = 1:population.M
	%% Look at points that are at the parent, so we consider all of
	%% the original points from the parent
	if (node.datapoints(i) == 1)
          [class, success] = classifyInstID(x(1:population.F),i);
          if(class == k.CLASS_0)
            ldesc.datapoints(i) = 1;
	    %%	  ldesc.dataCount = ldesc.dataCount+1;
            if(success == 0)
              ldesc.numMisClassified = ldesc.numMisClassified+1;
            end
          else
            rdesc.datapoints(i) = 1;
	    %%	  rdesc.dataCount = rdesc.dataCount+1;
            if(success == 0)
              rdesc.numMisClassified = rdesc.numMisClassified+1;
            end
          end
	end
      end
      hyperplane = x(1:population.F)
      return
    end

    %% Construct candidate list of constraints
    %%  printf('Construct candidate list\n')
    %% Create an empty list to fill
    candidates = zeros(1,population.N);

    %% Add candidate features, any currently unused features
    %%  printf('Identify candidate feature constraints\n')
    for i = 1:population.F-1
      if (newNode.featuresp(i) == 0)
	candidates(i) = 1;
      end
    end

    %% Add candidate datapoints, those datapoint constraints with a non-zero
    %% dual cost
    %printf('Identify candidate datapoint constraints\n')
    for i = population.F+1:population.N
      if((lambda.ineqlin(i-population.F) ~= 0) && (newNode.datapoints(i-population.F) == 1))
	candidates(i) = 1;
      end
    end

    %% Set c NULL
    c = 0;
    %% Iterate through the candidate constraints that were identified,
    %% remove them one at a time, check the impact, return the
    %% constraint and then permanently remove the one with the greatest impact
    for i = 1:population.N
      if(candidates(i) == 1)
	%%    printf('Remove constraint %d\n', i)
	%% Remove the constraint
	if(i <= population.F)
	  %% If it is a feature constraint, remove feature constraint (add feature)
	  %%    printf('Remove feature constraint %d\n', i)
	  newNode.featuresp(i) = 1;
	  population.lb(i)=-Inf;
	  population.ub(i)=Inf;
	else
	  %% If it is a datapoint, remove datapoint constraint (remove
	  %% datapoint)
	  %% Remove the coefficient from the objective
	  %%  printf('Remove datapoint constraint %d\n', i-population.F)
	  population.f(i) = 0;
	  newNode.datapoints(i-population.F) = 0;
	end

	%% Solve the LP for Min SINF
	%%    printf('Solve LP for MIN SINF with temporary constraint adjustment\n')
	[x fvalt exitflag output lambda] = linprog(population.f, population.A, \
						   population.b, population.Aeq, \
						   population.beq, population.lb, \
						   population.ub);

	%% Calculate the SINF Reduction
	i_SINFRedcn = SINF - fvalt;

	%% Check if this is the first candidate to be tested, if so set it
	%% as the initial best
	if (c == 0)
	  %%      printf('Set first candidate as initial best\n')
	  c = i;
	  c_SINFRedcn = i_SINFRedcn;
	else
	  %% If it is not the first candidate then set it as the new
	  %% best if its SINFRedcn is greater than the current best
	  if(i_SINFRedcn > c_SINFRedcn)
            c = i;
            c_SINFRedcn = i_SINFRedcn;
	  end     
	end
	
	%% Reinstate constraint i
	if(i <= population.F)
	  %% Reinstate feature constraint (remove the feature)
	  newNode.featuresp(i) = 0;
	  population.lb(i)=0;
	  population.ub(i)=0;
	else
	  %% Reinstate datapoint constraint (readd the datapoints)
	  population.f(i) = 1;
	  newNode.datapoints(i-population.F) = 1;
	end
      end
    end
  end
end


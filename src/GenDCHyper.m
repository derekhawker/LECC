%% Generate Decision Cost Hyperplane
%% DC hyperplane generating function.
%% [desc0, desc1, hyperplane]= GenDCHyper(datac)
%% Inputs:
%% datac Population structure containing the data point constraints and feature costs used in
%% generating a separating hyperplane. See 5.2.1 for a description of the population structure.
%% cand_selection_method Int value where 0=use all datapoints that are violated as candidate constraitns, 1=use top n% datapoints taht are violated as candidates where n is a values between 0 and 1 and provided as the third function argument, 2=use best two candidate method
%% cand_selection_percent Value betweeen 0 and 1 showing the percent of total available datapoint candidates to use 
%% Outputs:
%% desc1 Population structure containing data point constraints and updated feature costs for the
%% points classified as class 0.
%% desc2 Population structure containing data point constraints and updated feature costs for the
%% points classified as class 1.
%% hyperplane A vector of feature variables w0...F representing the
%% generated hyperplane.

function [ldesc rdesc hyperplane] = GenDCHyper(node, cand_selection_method=0, cand_selection_percent=0,memory=0)
global population;
global k;
%% create a temporary population to work with
newNode = node;

printf('SELECT INITIAL FEATURES\n')
% Select initial feature(s)
[newNode.featuresp] = selectInitFeature(node);


%% Initial setup
%%printf('SETUP CONSTRAINTS\n')
%% Setup feature constraints
for i = 1:population.F-1
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
  if(node.datapoints(i) == 1)
    population.f(i+population.F) = population.mc(getClass(i)+1);
  else
    population.f(i+population.F) = 0;
  end
end

fval = Inf;
c = 0;
num_removed=0;

while fval ~= 0
  %% If a feature c has been selected, remove that constraint
  %% permanently
  if(c ~= 0)
%%    printf('\nPermanently remove constraint %d\n', c);
    if(c <= population.F)
      %% Remove feature constraint (add feature)
      newNode.featuresp(c) = 1;
      population.lb(c)=-Inf;
      population.ub(c)=Inf;
    else
      %% Remove datapoint constraint (remove datapoint)
      population.f(c) = 0;
      num_removed=num_removed+1;
      newNode.datapoints(c-population.F) = 0;
    end
  end
    

  %% Solve LP for min WSINF
  %%printf('Solve LP for MIN WSINF\n')
  [x fval exitflag output lambda] = linprog(population.f, population.A, \
                        population.b, population.Aeq, \
                        population.beq, population.lb, \
                        population.ub);

  WSINF = fval;
  if(~memory)
    DCTEMP = getDC(x(1:population.F), newNode.datapoints, \
             newNode.featuresp, newNode.costn);
  else
    DCTEMP = getDC(x(1:population.F), node.datapoints, \
             newNode.featuresp, newNode.costn);
  end
%%  printf("Sensitive: %d, Removed %d, Total %d\n",rows(find(lambda.ineqlin)),num_removed,population.M);

##   %% TEST SECTION, REMOVE ALL DUALs
##   while(WSINF~=0)
##   for a = population.F+1:population.N
##       if(lambda.ineqlin(a-population.F)~=0)
## 	num_removed=num_removed+1;
## 	population.f(a) = 0;
## 	a
##       end
##   end
##   printf("TRIAL\n")
##     [x fval exitflag output lambda] = linprog(population.f, population.A, \
##                         population.b, population.Aeq, \
##                         population.beq, population.lb, \
##                         population.ub);

##   WSINF = fval
##   find(lambda.ineqlin)
##   size(population.A)
##   population.N
##   size(x)
##   size(population.f)
##   pos=population.f .* x;
##   find(pos)
##   DCTEMP = getDC(x(1:population.F), newNode.datapoints, \
##              newNode.featuresp, newNode.costn)
##   printf("Red: %d, Dual: %d, Removed %d, Total \
## 	       %%d\n",rows(find(lambda.lower)),rows(find(lambda.ineqlin)),num_removed,population.M)

##   %% CHeck matrix
##   printf("Check Matrix\n")
##   for a = population.F+1:population.N
##       if(population.A(a-population.F,a)~=1 && population.A(a-population.F,a)~=-1)
## 	printf("Unusual in data %d\n",a);
##       end
##   end

## end
##   return

  if (WSINF == 0)
     %% Exit, return two nodes
     
    %% Update the costs for the new nodes
    for i = 1:population.F-1
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
     %% Look at points that are at the parent
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
  candidates = zeros(1,population.N);

  %% Add candidate features
%%  printf('Identify candidate feature constraints\n')
  for i = 1:population.F-1
      if (newNode.featuresp(i) == 0)
     candidates(i) = 1;
      end
  end

 if(cand_selection_method == 0)
	 candidates = [candidates(1:population.F-1),0,createAllSensitiveCandidatesList(newNode, lambda.ineqlin)];
elseif(cand_selection_method == 1)
	 candidates = [candidates(1:population.F-1),0,createTopPercentCandidatesList(newNode,	lambda.ineqlin,cand_selection_percent)];
elseif(cand_selection_method == 2)
	candidates = [candidates(1:population.F-1),0,createBestTwoCandidatesList(newNode, x(population.F+1:end), lambda)];
else
	printf('ERROR: Invalid cand_selection_method given in GenDCHyper.m  -  %d\n',cand_selection_methd);
 end
  %% Set c NULL
  c = 0;
  %% Iterate through the candidate constraints
  for i = 1:population.N
      if(candidates(i) == 1)
%%    printf('Remove constraint %d\n', i)
    %% Remove the constraint
    if(i <= population.F)
      %% Remove feature constraint (add feature)
  %%    printf('Remove feature constraint %d\n', i)
      newNode.featuresp(i) = 1;
      population.lb(i)=-Inf;
      population.ub(i)=Inf;
    else
      %% Remove datapoint constraint (remove datapoint)
    %%  printf('Remove datapoint constraint %d\n', i-population.F)
      population.f(i) = 0;
      newNode.datapoints(i-population.F) = 0;
    end

    %% Solve the LP for Min WSINF
%%    printf('Solve LP for MIN WSINF with temporary constraint adjustment\n')
    [x fvalt exitflag output lambda] = linprog(population.f, population.A, \
                          population.b, population.Aeq, \
                          population.beq, population.lb, \
                          population.ub);

    %% Calculate the DC of this solution, has to use the new
    %% costs, new features but all the datapoints
%%    printf("Calculate DC with constraint %d removed\n",i)
    if(~memory)
    i_DC = getDC(x(1:population.F), newNode.datapoints, \
             newNode.featuresp, newNode.costn);
  else
    i_DC = getDC(x(1:population.F), node.datapoints, \
             newNode.featuresp, newNode.costn);
  end

    %% Calculate the WSINF Reduction
    i_WSINFRedcn = WSINF - fvalt;

    if (c == 0)
%%      printf('Set first candidate as initial best\n')
       c = i;
       c_WSINFRedcn = i_WSINFRedcn;
       c_DC = i_DC;
    else
       if (i_DC <= c_DC)
          if ((i_DC < c_DC) || (i_WSINFRedcn > c_WSINFRedcn))
%%         printf('Set constraint %d as new best\n',i)
        c = i;
        c_WSINFRedcn = i_WSINFRedcn;
        c_DC = i_DC;
          end
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
      population.f(i) = population.mc(getClass(i-population.F)+1);
      newNode.datapoints(i-population.F) = 1;
    end
      end
  end
end
end 



% Inputs:
% =node= The node we are determining a separating hyperplane for
% =dual_vars= The dual variables resulting from a solution of the linear program for
% this node
% Creates a list of datapoint candidates selecting all those datapoints that have
% been violated
% Outputs:
% =candidates= Returns a row vector of candidates where a 1 means to use that datapoint and a 
% 0 means not to use it
function [candidates] = createAllSensitiveCandidatesList(newNode, dual_vars)
	global population;

  candidates = zeros(1,population.M);
  %% Add candidate constraints, those constraints with a non-zero
  %% dual cost
  
  for i = population.F+1:population.N
      if((dual_vars(i-population.F) ~= 0) && (newNode.datapoints(i-population.F) == 1))
	candidates(i-population.F) = 1;
      end
  end

  
end

% Inputs:
% =node= The node we are determining a separating hyperplane for
% =dual_vars= The dual variables resulting from a solution of the linear program for
% this node
% =cand_selection_percent= The percentage of candidates to use (0 to 1)
% Create list of datapoint candidates based on dual_variable values, selecting only
% the top percent given by the parameter
% Outputs:
% =candidates= Returns a row vector of candidates where a 1 means to use that datapoint and a 
% 0 means not to use it
function [candidates] = createTopPercentCandidatesList(node, dual_vars, cand_selection_percent)
  global population;
  CANDIDATES_LIST_SIZE = cand_selection_percent*(population.numClass0+population.numClass1);


  defaultCandidatesList = node.datapoints .* [dual_vars ~= 0]';

  if sum(defaultCandidatesList) < CANDIDATES_LIST_SIZE
    candidates = defaultCandidatesList;
    return;
  end

  candidates = defaultCandidatesList*0;
  dual_vars = abs(dual_vars);

  n = CANDIDATES_LIST_SIZE;
  for i = 1:population.M
    if n == 0
      return;
    end
    [maxVal, index] = max(dual_vars);
    dual_vars(index) = -Inf;
    candidates(index) = 1;
    n = n - 1;
  end
  
  % problem creating 
  candidates=defaultCandidatesList;
end


% Inputs:
% =node= The node we are determining a separating hyperplane for
% =elastic_variable= The value of the elastic variable after solving the LP for the node
% =lambda= Structure containing reduced costs, dual variables for LP solution
% Create list of datapoint candidates by selecting two candidates. The first candidate
% is the violated data point with the highest dual_variable*elastic variable product
% The second candidate is the unviolated constraint with the highest dual_variable*elastic variable product
% Outputs:
% =candidates= Returns a row vector of candidates where a 1 means to use that datapoint and a 
% 0 means not to use it
function [candidates] = createBestTwoCandidatesList(node, elasticVariables, lambda)
  global population;
  elasticVariables;
  violatedConstraints  = node.datapoints ;
  unviolatedConstraints  = violatedConstraints;
  violatedConstraints = abs(violatedConstraints.* [elasticVariables.* lambda.ineqlin]');
  unviolatedConstraints = abs(unviolatedConstraints.* [[elasticVariables == 0].* lambda.ineqlin]');




  candidates = zeros(1,population.M);
  [val,i] = max(violatedConstraints);
  candidates(1,i) = 1;
  [val, i] = max(unviolatedConstraints);
  candidates(1,i) = 1;

  % pause()

end


function [statistics] = kFoldCrossVal(k, dsId, prefix, alg=1, cand_selection_method=0, cand_selection_percent=0)
  addpath('utility-scripts');
  %% Alg = 1 for LECC, Alg=2 for LECCM, Alg=3 for Chinneck Int
  %% 1) Read in dsID
  %% 2) Split the datapoints into k structures - each with a vector of
  %% 1s and a vector of 0s, make sure the proportions are relative to
  %% the original dataset
  %% 3) Combine k-1 sets into a large set and run
  %% 4) Test the 1 extra against the tree and collect data
  %% 5) Repeat 3-4 an additional k-1 times
  %% 6) Print out statistics

  % load table of dataset files
  [datasetFiles, fcFiles, mcFiles] = textread('./inc/datasetLocationsTable.txt', '%s %s %s');

  % load dataset (instance data, feature costs, and misclassification costs
  fc = load (fcFiles{dsId});
  mc= load (mcFiles{dsId});
  rawInstanceData = load (datasetFiles{dsId});

  % Copy fc and mc into folder for archive purposes
  f = sprintf('log/%s/%s.mc', prefix,prefix);
  f
  fid = fopen(f, 'w');
  fprintf(fid, '%f %f\n',mc(1), mc(2))
  fclose(fid)

  f = sprintf('log/%s/%s.fc', prefix,prefix);
  fid = fopen(f, 'w');
  for n = 1:size(fc)(2)-1
    fprintf(fid, '%f ',fc(n))
  end
  fprintf(fid, '%f',fc(size(fc)(2)))
  fprintf(fid, '\n')
  fclose(fid)


  % keep count of the number of class 0 and class 1 datapoints.
  numClass0 = 0;
  numClass1 = 0;

  % number of instances
  instances = size(rawInstanceData)(1);


  % the number of feature variable is the number of columns in the 
  % raw dataset file.  includes the class
  features = size(rawInstanceData)(2);
  numClass1 = sum(rawInstanceData(:,features));
  numClass0 = instances-numClass1;

%%  if(k*5 > instances)
  %%  printf('Error: You would have fewer than 5 points per subpop');
   %% return;
  %%end

  %% Assign to k groups
  bag = [];
  for i = 1:k
    prep.num = i;
    prep.class0 = [];
    prep.class1 = [];
    bag=[bag,prep];
  end

  %% Create a random index for class0 points
  r = rand(numClass0,1);
  [g rindex] = sort(r);

  %% Create a random index for class1 points
  r = rand(numClass1,1);
  [g oneIndex] = sort(r);
  oneIndex = oneIndex .+ repmat(numClass0, numClass1, 1);
  rindex = [rindex;oneIndex];


  %% Put values into their bags
  count = 1;
  while (count<=instances)
    for i = 1:k
      if(count>instances)
	break;
      end
      if(count <= numClass0)
	bag(i).class0 = [bag(i).class0;rawInstanceData(rindex(count),:)];
      else
	bag(i).class1 = [bag(i).class1;rawInstanceData(rindex(count),:)];
      end
      count = count + 1;
    end
  end

  printf('Some bag stats for debugging\n')
  printf('Inst: %d / C0: %d / C1: %d\n',instances,numClass0,numClass1);
  for i = 1:k
      printf('Bag %d: C0: %d --- C1: %d\n',i, rows(bag(i).class0), rows(bag(i).class1))
  end

  %% Save the bags
  groupfilename=sprintf('log/%s/groupsbag',prefix);
  save(groupfilename);

  %% Split into test and training sets and run
  mcfilename = sprintf('log/%s/mc',prefix);
  writeMisclassificationCostsToTemp(mc,0,mcfilename);
  fcfilename = sprintf('log/%s/fc',prefix);
  writeFeatureCostsToTemp(fc,0,fcfilename);
  statistics.accuracy = [];
  statistics.averagecost = [];
  for i = 1:k
      test = [bag(i).class0;bag(i).class1];
      training =[];
	for j = 1:k
	  if(j ~= i)
	    training = [training;bag(j).class0];
	  end
	end
	for j = 1:k
	  if(j ~= i)
	    training = [training;bag(j).class1];
	  end
	end

	%% Run the training
	printf('Running Training %d\n',i)
	datafilename = sprintf('log/%s/datatemp',prefix);
	writeDatapointsToTemp(training,0,datafilename);

	%% Choose algorithm
	switch(alg)
	      case(1)
		  printf('Using LECC\n');
		  [tree, unpruned, lpsSolved] = genDecTree(0,\
						cand_selection_method, \
						cand_selection_percent,0,fcfilename,mcfilename,datafilename);
	      case(2) 
		  printf('Using LECCM\n');
		  [tree, unpruned, lpsSolved] = genDecTree(0, \
						cand_selection_method, \
						cand_selection_percent,1,fcfilename,mcfilename,datafilename);
	      case(3)
		  printf('Using Chinneck Int\n');
		  if(cand_selection_method~=0)
		    printf('Using alternative selection methods with Chinneck Int is not supported\n');
		    return;
		  end
		  [tree, unpruned, lpsSolved] = genDecTreeSINF(0,fcfilename,mcfilename,datafilename);
	      otherwise
		printf('Invalid Algorithm\n');
		return;
	end

	%% Save the results
	f = sprintf('log/%s/KfoldUNPRUNED%d.txt',prefix, i);
	outputDecTreeToFile(unpruned,f);
	f = sprintf('log/%s/KfoldUNPRUNED%d.tree',prefix,i);
	decTreeTextFile(unpruned,f);
	f = sprintf('log/%s/KfoldUNPRUNED%d.out',prefix, i);
	save(f,'unpruned');
	f = sprintf('log/%s/KfoldTree%d.txt',prefix, i);
	outputDecTreeToFile(tree,f);
	f = sprintf('log/%s/KfoldTree%d.tree',prefix,i);
	decTreeTextFile(tree,f);
	f = sprintf('KfoldTree%d.out',i);
	save(strcat('log/',prefix,'/',f), 'tree');
	
	%% Run the test for unpruned
	total = 0;
	misClass = 0;
	totalCost = 0;
	features = repmat(0,1,size(fc)(2));
	for j = 1:size(test)(1)
	  class = test(j,size(test)(2));
	  [classed,cost,fp] =  classifyInstance(test(j,:),unpruned,mc,fc,numClass0,numClass1);
	  features = features .+ fp;
	  total = total+1;
	  totalCost = totalCost+cost;
	  if(class ~= classed)
	    misClass = misClass + 1;
	  end
	end
	UPtestAccuracy = (total-misClass)/total;
	UPEC = totalCost/total;

	statistics.EFU{i} = features ./ repmat(size(test)(1),1,size(fc)(2));
	printf('Test %d UNPRUNED --- Accuracy = %f --- ExpectedCost = %f --- Expected Features ',i, UPtestAccuracy,UPEC)
	printf('%f ', statistics.EFU{i})
	printf('\n')
	statistics.accuracyU(i) = UPtestAccuracy;
	statistics.averagecostU(i) = UPEC;

	%% Run the test for pruned
	total = 0;
	misClass = 0;
	totalCost = 0;
	features = repmat(0,1,size(fc)(2));
	for j = 1:size(test)(1)
	  class = test(j,size(test)(2));
	  [classed,cost,fp] = classifyInstance(test(j,:),tree,mc,fc,numClass0,numClass1);
	  features = features .+ fp;
	  total = total+1;
	  totalCost = totalCost+cost;
	  if(class ~= classed)
	    misClass = misClass + 1;
	  end
	end
	testAccuracy = (total-misClass)/total;
	EC = totalCost/total;
	statistics.EFP{i} = features ./ repmat(size(test)(1),1,size(fc)(2));
	printf('Test %d PROCESSED --- Accuracy = %f --- ExpectedCost = %f --- Expected Features ',i, testAccuracy,EC)
	printf('%f ', statistics.EFP{i})
	printf('\n')
	%% Record stats on pruned
	statistics.accuracyP(i)=testAccuracy;
	statistics.averagecostP(i)=EC;
	%save the LPs solved
	statistics.lpsSolved(i) = lpsSolved;

  end

  statistics.accuracyAverageU = mean(statistics.accuracyU);
  statistics.accuracyStdU=std(statistics.accuracyU);
  statistics.averagecostAverageU = mean(statistics.averagecostU);
  statistics.costStdU=std(statistics.averagecostU);
  printf('Statistics UNPRUNED TEST: E(accuracy): %f  STD(accuracy): %f E(E(cost)): %f  STD(E(cost)): %f\n', statistics.accuracyAverageU, statistics.accuracyStdU,statistics.averagecostAverageU, statistics.costStdU)

  statistics.accuracyAverageP = mean(statistics.accuracyP);
  statistics.accuracyStdP=std(statistics.accuracyP);
  statistics.averagecostAverageP = mean(statistics.averagecostP);
  statistics.costStdP=std(statistics.averagecostP);
  printf('Statistics PRUNED TEST: E(accuracy): %f  STD(accuracy): %f E(E(cost)): %f  STD(E(cost)): %f\n', statistics.accuracyAverageP, statistics.accuracyStdP,statistics.averagecostAverageP, statistics.costStdP)
  f = sprintf('log/%s/Stats.out',prefix);
  save(f,'statistics');
  
return

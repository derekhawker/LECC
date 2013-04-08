function [accuracy totalCost expectedCost expectedFeatures] = getTreeAccuracy(tree)
    global population;
    global k;
    stack = [];
    misClassifiedCount = 0;
    misclassificationCosts = 0;
    featureCosts = 0;
    totalCost = 0;
    featuresUsed = repmat(0,1,population.F-1);
    datapoints = sum(tree(1).datapoints);

    %% Visit Root
    if(tree(1).ldesc == k.LEAF_NODE)
        m0 = population.mc(1)*population.numClass0;
        m1 = population.mc(2)*population.numClass1;
        if (m0 > m1)
            misclassificationCosts = m1;
            misClassifiedCount = population.numClass1;
        else
            misclassificationCosts = m0;
            misClassifiedCount = population.numClass0;
        end
        featureCosts = 0;
    else
        %% Need to descend put rdesc on stack
        stack = [stack;tree(1).rdesc];
        node = tree(1).ldesc;
        while(node ~= k.LEAF_NODE ||  size(stack)(1) ~= 0)
            if(node ~= k.LEAF_NODE)
                stack = [stack; tree(node).rdesc];
                if(tree(node).ldesc == k.LEAF_NODE)
                    %% Compute for visited node
                    %% Compute misclassification at Node
                    misClassifiedCount = misClassifiedCount +  tree(node).numMisClassified;
                    if (tree(node).class == k.CLASS_0)
                        misclassificationCosts = misclassificationCosts + population.mc(2)*tree(node).numMisClassified;
                    else 
                        misclassificationCosts = misclassificationCosts + population.mc(1)*tree(node).numMisClassified;
                    end

                    %% Compute Feature costs at node
                    ancestor = tree(node).ancestor;
                    fp = tree(ancestor).featuresp;
                    ancestor = tree(ancestor).ancestor;
                    printf('Examining Leaf NODE %d %d\n', node, sum(tree(node).datapoints))
                    while (ancestor ~= 0)
                        fp = bitor(tree(ancestor).featuresp, fp);
                        printf('Ancestor %d, ',ancestor)
                        printf('%d ',tree(ancestor).featuresp)
                        printf('\n')
                        ancestor = tree(ancestor).ancestor;
                    end
                    featureCosts = featureCosts + sum(fp .* population.fc * (sum(tree(node).datapoints)));
                    featuresUsed = featuresUsed .+ (fp .* sum(tree(node).datapoints));
                    printf('USED: ')
                    printf('%f ', featuresUsed)
                    printf('\n')
                end 
                node = tree(node).ldesc;
            else
                node = stack(size(stack)(1));
                if(size(stack)(1)==1)
                    stack = [];
                else
                    stack(size(stack)(1)) = [];
                end
            end
        end
    end 

    accuracy = (datapoints-misClassifiedCount)/datapoints;
    totalCost = misclassificationCosts + featureCosts;
    expectedCost = totalCost/datapoints;
    %% Ratio of points that use a feature
    expectedFeatures = featuresUsed ./ population.M; 
    return
end

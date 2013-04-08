%% In this case all instances come in as row vectors with the real
%% values of their features in the columns
function [classv,cost, features] = classifyInstance(instance,tree,mc,fc,c0,c1)
  global k;	 
  correctClass=instance(size(instance)(2));
  instance(size(instance)(2)) = -1; %% assume a 0 point
  features = repmat(0,1,size(fc)(2));
  node = 1;

  if(tree(node).ldesc==k.LEAF_NODE && tree(node).rdesc==k.LEAF_NODE)
    m0 = sum(c0)*mc(1);
    m1 = sum(c1)*mc(2);
    features = repmat(0, 1, size(tree(node).featuresp)(2));
    if(m0 > m1)
      classv=k.CLASS_0;
    else
      classv=k.CLASS_1;
    end
  end
  while(node ~= k.LEAF_NODE)
    if(tree(node).ldesc~=k.LEAF_NODE && tree(node).rdesc~=k.LEAF_NODE)
      classv = classAtHyper(instance,tree(node).hyperplane);
      features = bitor(features,tree(node).featuresp);
      if(classv == k.CLASS_0)
	node = tree(node).ldesc;
      else
	node = tree(node).rdesc;
      end
    else
	break;
    end
  end
  if(correctClass~=classv)
    cost = features*fc'+mc(1+correctClass);
  else
    cost = features*fc';
  end
end

function [classv] = classAtHyper(instance, hyperplane)
  global k;
  test = instance * hyperplane;
  if (test > 0)
    classv=k.CLASS_1;
  else
    classv=k.CLASS_0;
  end
end

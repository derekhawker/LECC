LECC
====

Lowest Expected Cost Classifier

This project was created as a part of our fourth year Computer Systems Engineering project at Carleton University.  In the src folder you will find our implementation of a binary decision tree classifier that uses algorithms that we developed to train a decision tree in order to minimize cost.

## Creating a Dataset 
In the datasets folder, you will find datasets we used to complete our report and you may add your own by creating a new folder. 

 Three files are required for a dataset:

 1) A data file (.data): Each row in this file represents a data instance.  The features must be space separated at the front of the row and the class must be in the last column.  Class 0 points must be all at the top of the file and class 1 points must be at the bottom.

 2) A feature cost file (.fc): This contains a space separated list of the feature costs for your dataset.  The order of the features must match that used in the data file.
 
 3) A misclassification cost file (.mc): This contains two values separated by a space.  The first is the cost of misclassifying a class 0 point as a class 1 and the second is the cost of misclassifying a class 1 point as a class 0.

Once your dataset is created in the dataset folder, go to src/inc and add an appropriate line in datasetLocationsTable.txt for your dataset.  The line number of your entry is your dataset ID number.

## Creating a Single Decision Tree ##
### Choose an Algorithm ###
#### int: #### Dr. J.W. Chinneck's int method.  This was the foundation for our algorithm design.  It is an accuracy-based classifier and is included for comparison.
#### lecc:  #### This is the main variant of our algorithm and in general gives the best performance.
#### leccm:  #### In some cases this modified version of the lecc algorithm gives the best results.  It modifies the way in which nodes are divided.  We recommend that if you have the time you run this in addition to the lecc algorithm and see which has the best performance.

### Choose a Selection Method (if using lecc or leccm) ###
#### N%: #### If you enter a number between 1 and 100, the algorithm that divides nodes will used the given percentage of candidates.  This may speed up the creation of the tree but it may also lead to some increase in expected cost.  
#### Two Candidate: ####If you enter 200, the algorithm that divides nodes will only use the top two candidates.
#### Default: #### If you do not enter anything, the method will use all of the candidates (equivalent to entering 100).

A full discussion of the algorithms and selection methods may be found in our report.

### Create the Tree ###
In the src directory run:
./LECC -i <datasetID> -o <FOLDERNAME> -a <algorithm> -s <selection method>

For example, to run dataset 3 (line 3 of src/inc/datasetLocationsTable.txt) with leccm, using 50% of candidates in the node division and saving it in src/log/DATASET3 you would run:
./LECC -i 3 -o DATASET3 -a leccm -s 50

### Running K-Fold Cross Validation ###
To run k-fold cross validation enter the number of folds desired into the k option.  Using the above example with 10-fold cross validation:

./LECC -i 3 -o DATASET3 -a leccm -s 50 -k 10

### Reading the Output ###
All output is put into a subfolder of src/log.

The FOLDERNAME.log file contains the verbose log output of the program.

Each tree is outputted with 3 files: (tree) a text based tree, (out) an octave loadable copy of the tree structure and (txt) a text copy of the tree structure.

Unprocessed trees contain the text UNPRUNED and processed trees contain the text Tree.  

If you ran k-fold cross validation: a copy of the feature costs and misclassification costs are saved, all of the groups are saved in an octave loadable file 'groupsbag' and the k-fold statistics are stored in an octave loadable file 'Stats.out'.  Stats.out is the most convenient place to see your statistics to use it, enter into octave and call the following:
load('Stats.out')
statistics

## Expansion ##
Please look into the source code if you want to add algorithms or port this to a different platform.  The code is commented and should be easy to follow if you begin by reading the LECC script and following through the code.  All of the interfaces are documented in our report.
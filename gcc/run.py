from tensorflow.python.util import deprecation
deprecation._PRINT_DEPRECATION_WARNINGS = False

import time
import os
import numpy as np
import pandas as pd
from gcc.metrics import output_metrics, print_metrics
from gcc.optimizer import optimize
from gcc.utils import read_dataset, preprocess_dataset
import tensorflow as tf
from tabulate import tabulate

flags = tf.compat.v1.flags
FLAGS = flags.FLAGS

# Parameters
flags.DEFINE_string('dataset', 'cora', 'Name of the graph dataset (cora, citeseer, pubmed or wiki).')
flags.DEFINE_integer('power', 5, 'Propagation order.')
flags.DEFINE_integer('runs', 20, 'Number of runs per power.')
flags.DEFINE_integer('n_clusters', 0, 'Number of clusters (0 for ground truth).')
flags.DEFINE_integer('max_iter', 30, 'Number of iterations of the algorithm.')
flags.DEFINE_float('tol', 10e-7, 'Tolerance threshold of convergence.')

dataset = flags.FLAGS.dataset
power = flags.FLAGS.power
runs = flags.FLAGS.runs
n_clusters = flags.FLAGS.n_clusters
max_iter = flags.FLAGS.max_iter
tolerance = flags.FLAGS.tol


# Read the dataset
adj, features, labels, n_classes = read_dataset(dataset)
if n_clusters == 0: n_clusters = n_classes
# Process the dataset
tf_idf = (dataset == 'cora' or dataset == 'citeseer') # normalize binary word datasets
norm_adj, features = preprocess_dataset(adj, features, tf_idf=tf_idf)


run_metrics = []
times = []
pred_list = []

X = features

for run in range(runs):
    features = X
    t0 = time.time()
    for _ in range(power):
        features = norm_adj @ features

    G, F, W, losses = optimize(features, n_clusters, n_clusters,
                               max_iter=max_iter, tolerance=tolerance)
    time_it_took = time.time() - t0
    metrics = output_metrics(features @ W, labels, G)
    run_metrics.append(metrics + [losses[-1]])
    times.append(time_it_took)
    pred_list.append(G)


pred_label = pred_list[-1].numpy()
df = pd.DataFrame(pred_label)
print(df)

path = "/Users/ninasong/Desktop/spatialProject/literature_model/graph_convolutional_clustering/unsupervised-GCN/"
df.to_csv((os.path.join(path, "pred_label_only.csv")), index=False)

#The visualization of predicted versus true labels can be directly viewed in the terminal by following -
#true_vs_pred = list(zip(labels,pred_list[-1].numpy()))
#rows = [[labels[i], pred_label[i]] for i in range(10)]
#print(tabulate(rows, headers=["True", "Pred"], tablefmt="grid"))

#print_metrics(np.mean(run_metrics, 0), np.std(run_metrics, 0), np.mean(times), np.std(times))


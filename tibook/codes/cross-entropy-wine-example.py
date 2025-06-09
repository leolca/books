import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import load_wine
from sklearn.preprocessing import StandardScaler

# Load UCI Wine dataset
wine = load_wine()
X = wine.data  # 178 samples, 13 features
y = wine.target  # Class labels: 0, 1, 2
Y = np.zeros((y.size, 3))
Y[np.arange(y.size), y] = 1  # One-hot encoding

# Select one sample per class
samples_idx = [np.where(y == i)[0][0] for i in range(3)]
X_subset = X[samples_idx]
Y_subset = Y[samples_idx]

# Standardize features
scaler = StandardScaler()
X_subset = scaler.fit_transform(X_subset)

# Softmax function
def softmax(z):
    exp_z = np.exp(z - np.max(z))  # Numerical stability
    return exp_z / np.sum(exp_z)

# Cross-entropy loss for a single sample
def cross_entropy_loss(w_i1, w_i2, x, y_true, W_fixed, b_fixed, class_idx):
    W = np.copy(W_fixed)
    W[class_idx, 0] = w_i1  # Weight for Alcohol (feature 1)
    W[class_idx, 1] = w_i2  # Weight for Malic acid (feature 2)
    logits = x @ W.T + b_fixed
    probs = softmax(logits)
    return -np.sum(y_true * np.log(probs + 1e-10))

# Gradient descent for a single sample
def gradient_descent(x, y_true, W_init, b_init, eta=0.1, iterations=50):
    W = W_init.copy()
    b = b_init.copy()
    trajectory = [(W[class_idx, 0], W[class_idx, 1])]  # Track w_i1, w_i2
    for _ in range(iterations):
        logits = x @ W.T + b
        probs = softmax(logits)
        grad_W = np.outer(probs - y_true, x)
        grad_b = probs - y_true
        W -= eta * grad_W
        b -= eta * grad_b
        trajectory.append((W[class_idx, 0], W[class_idx, 1]))
    return np.array(trajectory)

# Initialize weights and biases
np.random.seed(42)
W_fixed = np.random.randn(3, 13) * 0.1
b_fixed = np.zeros(3)

# Create figure for three subplots
fig, axes = plt.subplots(1, 3, figsize=(18, 6))

# Plot loss contour for each class
for class_idx in range(3):
    x, y_true = X_subset[class_idx], Y_subset[class_idx]
    # Compute loss surface
    w_i1_range = np.linspace(-5, 5, 50)
    w_i2_range = np.linspace(-5, 5, 50)
    W_i1, W_i2 = np.meshgrid(w_i1_range, w_i2_range)
    losses = np.zeros(W_i1.shape)
    for i in range(W_i1.shape[0]):
        for j in range(W_i1.shape[1]):
            losses[i, j] = cross_entropy_loss(W_i1[i, j], W_i2[i, j], x, y_true, W_fixed, b_fixed, class_idx)

    # Run gradient descent
    W_init = W_fixed.copy()
    W_init[class_idx, 0], W_init[class_idx, 1] = -2, -2  # Initial point
    trajectory = gradient_descent(x, y_true, W_init, b_fixed, eta=0.1)

    # Compute initial and final probabilities
    W_temp = W_fixed.copy()
    W_temp[class_idx, 0], W_temp[class_idx, 1] = trajectory[0]
    logits_init = x @ W_temp.T + b_fixed
    probs_init = softmax(logits_init)
    loss_init = -np.log(probs_init[class_idx] + 1e-10)

    W_temp[class_idx, 0], W_temp[class_idx, 1] = trajectory[-1]
    logits_final = x @ W_temp.T + b_fixed
    probs_final = softmax(logits_final)
    loss_final = -np.log(probs_final[class_idx] + 1e-10)

    # Plot
    ax = axes[class_idx]
    contour = ax.contour(W_i1, W_i2, losses, levels=20, cmap='viridis', linewidths=1)
    ax.plot(trajectory[:, 0], trajectory[:, 1], 'r-', linewidth=1, label='Trajetória de gradiente descendente')
    ax.scatter([trajectory[0, 0]], [trajectory[0, 1]], c='red', s=25, label='Modelo inicial')
    ax.scatter([trajectory[-1, 0]], [trajectory[-1, 1]], c='blue', s=25, label='Modelo aprimorado')
    ax.set_xlabel('$w_{%d1}$ (Álcool)' % (class_idx + 1), fontsize=10)
    ax.set_ylabel('$w_{%d2}$ (Ácido Málico)' % (class_idx + 1), fontsize=10)
    ax.set_title('Classe %d (Cultivar %d)' % (class_idx + 1, class_idx + 1), fontsize=12)
    ax.legend(fontsize=8)
    ax.tick_params(labelsize=8)

plt.tight_layout()
plt.savefig('cross_entropy_contours.pdf')
plt.show()

# Print probabilities for class 1 sample
x, y_true = X_subset[0], Y_subset[0]
W_temp = W_fixed.copy()
W_temp[0, 0], W_temp[0, 1] = -2, -2
logits_init = x @ W_temp.T + b_fixed
probs_init = softmax(logits_init)
loss_init = -np.log(probs_init[0] + 1e-10)
W_temp[0, 0], W_temp[0, 1] = trajectory[-1]
logits_final = x @ W_temp.T + b_fixed
probs_final = softmax(logits_final)
loss_final = -np.log(probs_final[0] + 1e-10)

print(f"Initial probabilities (Class 1): {probs_init}")
print(f"Initial loss (Class 1): {loss_init:.3f}")
print(f"Final probabilities (Class 1): {probs_final}")
print(f"Final loss (Class 1): {loss_final:.3f}")

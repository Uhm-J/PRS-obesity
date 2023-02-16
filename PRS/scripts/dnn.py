import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

import keras
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.regularization import l2



class PRS_Model:
    def __init__(self, X, y, test_size=0.2, random_state=0):
        self.X = X
        self.y = y
        self.test_size = test_size
        self.random_state = random_state

    def preprocess_data(self):
        # Add the additional covariates
        self.X['age'] = ...  # Add the age column
        self.X['length'] = ...  # Add the length column
        self.X['lifestyle'] = ...  # Add the lifestyle column
        self.X['ethnicity'] = ...  # Add the ethnicity column

        # Split the data into training and testing sets
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(self.X, self.y,
                                                                                test_size=self.test_size,
                                                                                random_state=self.random_state)

        # Scale the data
        self.scaler = StandardScaler()
        self.X_train = self.scaler.fit_transform(self.X_train)
        self.X_test = self.scaler.transform(self.X_test)

    def build_model(self, input_dim, output_dim, hidden_layers, neurons_per_layer, activation='relu', optimizer='adam',
                    loss='mean_squared_error', dropout_rate=0.2, l2_reg=0.01):
        model = Sequential()
        model.add(Dense(neurons_per_layer, activation=activation, input_dim=input_dim, kernel_regularizer=l2(l2_reg)))

        for i in range(hidden_layers - 1):
            model.add(Dense(neurons_per_layer, activation=activation, kernel_regularizer=l2(l2_reg)))
            model.add(Dropout(dropout_rate))

        model.add(Dense(output_dim, activation='linear'))

        model.compile(optimizer=optimizer, loss=loss)

        return model

    def train_model(self, epochs, batch_size):
        self.history = self.model.fit(self.X_train, self.y_train, epochs=epochs, batch_size=batch_size,
                                      validation_data=(self.X_test, self.y_test))

    def evaluate_model(self):
        self.train_loss, self.train_acc = self.model.evaluate(self.X_train, self.y_train, verbose=False)
        self.test_loss, self.test_acc = self.model.evaluate(self.X_test, self.y_test, verbose=False)

        print("Training Loss: {:.4f}".format(self.train_loss))
        print("Training Accuracy: {:.4f}".format(self.train_acc))
        print("Testing Loss: {:.4f}".format(self.test_loss))
        print("Testing Accuracy: {:.4f}".format(self.test_acc))

    def plot_performance(self):
        plt.figure(figsize=(10, 5))
        plt.plot(self.history.history['loss'], label='Training Loss')
        plt.plot(self.history.history['val_loss'], label='Validation Loss')
        plt.xlabel('Epochs')
        plt.ylabel('Loss')
        plt.legend()
        plt.show()


if __name__ == '__main__':
    # Load the data
    X = pd.read_csv('X.csv')
    y = pd.read_csv('y.csv')

    # Initialize the model
    model = PRS_Model(X, y)

    # Preprocess the data
    model.preprocess_data()

    # Build the model
    input_dim = X.shape[1]
    output_dim = y.shape[1]
    hidden_layers = 2
    neurons_per_layer = 10
    model.build_model(input_dim, output_dim, hidden_layers, neurons_per_layer)

    # Train the model
    epochs = 50
    batch_size = 32
    m = model.train_model(epochs, batch_size)

    # Evaluate the model
    model.evaluate_model()

    # Plot the performance of the model
    model.plot_performance()

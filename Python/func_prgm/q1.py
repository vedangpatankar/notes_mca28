# 1. Define a user-defined function in Python. Write a Python program to create a function add() that accepts two numbers and returns their sum.

# A user-defined function is a block of reusable code written by the programmer
# using the def keyword. It runs only when it is called by its name.

def add(a, b):
    return a + b


num1 = int(input("Enter the first number: "))
num2 = int(input("Enter the second number: "))
print(f"The sum of {num1} and {num2} is {add(num1, num2)}.")

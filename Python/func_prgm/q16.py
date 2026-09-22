# 16. Write a Python function that accepts three numbers and returns their average.

def average(a, b, c):
    return (a + b + c) / 3


num1 = float(input("Enter the first number: "))
num2 = float(input("Enter the second number: "))
num3 = float(input("Enter the third number: "))
print(f"The average of the three numbers is {average(num1, num2, num3):.2f}.")

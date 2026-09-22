# 7. Write a Python function that accepts a number and returns its factorial.

def factorial(num):
    result = 1
    while num > 1:
        result = result * num
        num = num - 1
    return result


num = int(input("Enter a number: "))
if num < 0:
    print("Factorial is not defined for negative numbers.")
else:
    print(f"The factorial of {num} is {factorial(num)}.")

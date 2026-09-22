# 18. Write a recursive function to find the factorial of a given number.

def factorial(num):
    if num == 0 or num == 1:  # Base case, stops the recursion.
        return 1
    else:
        return num * factorial(num - 1)  # The function calls itself.


num = int(input("Enter a number: "))
if num < 0:
    print("Factorial is not defined for negative numbers.")
else:
    print(f"The factorial of {num} is {factorial(num)}.")

# 5. Write a Python function that accepts three numbers and returns the largest number among them.

def largest(a, b, c):
    if a >= b and a >= c:
        return a
    elif b >= a and b >= c:
        return b
    else:
        return c


num1 = int(input("Enter the first number: "))
num2 = int(input("Enter the second number: "))
num3 = int(input("Enter the third number: "))
print(f"The largest number is {largest(num1, num2, num3)}.")

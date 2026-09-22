# 12. Write a Python function that accepts two numbers and returns both their sum and product.

def sum_and_product(a, b):
    return a + b, a * b  # A function can return more than one value as a tuple.


num1 = int(input("Enter the first number: "))
num2 = int(input("Enter the second number: "))

total, product = sum_and_product(num1, num2)
print(f"The sum of {num1} and {num2} is {total}.")
print(f"The product of {num1} and {num2} is {product}.")

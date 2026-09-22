# 17. Write a Python program using a function to calculate the greatest common divisor (GCD) of two numbers.

def gcd(a, b):
    # Euclid's method: keep replacing the larger number by the remainder.
    while b != 0:
        remainder = a % b
        a = b
        b = remainder
    return a


num1 = int(input("Enter the first number: "))
num2 = int(input("Enter the second number: "))
print(f"The GCD of {num1} and {num2} is {gcd(num1, num2)}.")

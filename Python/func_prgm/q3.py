# 3. Write a Python program using a function with default arguments to calculate the power of a number. Use 2 as the default exponent.

def power(base, exponent=2):
    return base ** exponent


base = int(input("Enter the base number: "))

# The exponent is not passed here, so the default value 2 is used.
print(f"Using the default exponent: {base} ** 2 = {power(base)}.")

exponent = int(input("Enter the exponent: "))
print(f"Using the given exponent: {base} ** {exponent} = {power(base, exponent)}.")

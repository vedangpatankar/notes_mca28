# 6. Write a Python function that accepts a number and checks whether it is even or odd.

def check_even_odd(num):
    if num % 2 == 0:
        return "even"
    else:
        return "odd"


num = int(input("Enter a number: "))
print(f"The number {num} is {check_even_odd(num)}.")

# 9. Write a Python function that accepts a number and returns the sum of its digits.

def sum_of_digits(num):
    num = abs(num)
    total = 0
    while num > 0:
        total = total + num % 10
        num = num // 10
    return total


num = int(input("Enter a number: "))
print(f"The sum of the digits of {num} is {sum_of_digits(num)}.")

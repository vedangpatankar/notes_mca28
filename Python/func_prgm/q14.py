# 14. Write a Python function that accepts a number and returns the reverse of the number.

def reverse_number(num):
    reverse = 0
    while num > 0:
        reverse = reverse * 10 + num % 10
        num = num // 10
    return reverse


num = int(input("Enter a number: "))
print(f"The reverse of {num} is {reverse_number(num)}.")

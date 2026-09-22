# 10. Write a Python function that accepts a number and checks whether it is a prime number.

def is_prime(num):
    if num < 2:
        return False
    divisor = 2
    while divisor * divisor <= num:
        if num % divisor == 0:
            return False
        divisor = divisor + 1
    return True


num = int(input("Enter a number: "))
if is_prime(num):
    print(f"{num} is a prime number.")
else:
    print(f"{num} is not a prime number.")

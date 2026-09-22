# 13. Write a Python program using a function to check whether a given number is a palindrome.

def is_palindrome(num):
    original = num
    reverse = 0
    while num > 0:
        reverse = reverse * 10 + num % 10
        num = num // 10
    return original == reverse


num = int(input("Enter a number: "))
if is_palindrome(num):
    print(f"{num} is a palindrome number.")
else:
    print(f"{num} is not a palindrome number.")

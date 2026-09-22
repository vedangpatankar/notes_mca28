# 19. Write a recursive function to calculate the sum of numbers from 1 to n.

def sum_upto(n):
    if n <= 0:  # Base case, stops the recursion.
        return 0
    else:
        return n + sum_upto(n - 1)  # The function calls itself.


n = int(input("Enter a number: "))
print(f"The sum of numbers from 1 to {n} is {sum_upto(n)}.")

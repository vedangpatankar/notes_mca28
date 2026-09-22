# 8. Write a Python program using a function to calculate simple interest. Pass principal, rate, and time as arguments.

def simple_interest(principal, rate, time):
    return (principal * rate * time) / 100


principal = float(input("Enter the principal amount: "))
rate = float(input("Enter the rate of interest: "))
time = float(input("Enter the time in years: "))

interest = simple_interest(principal, rate, time)
print(f"The simple interest is {interest}.")
print(f"The total amount to be paid is {principal + interest}.")

# 11. Write a Python program to demonstrate the difference between a local variable and a global variable using a user-defined function.

count = 10  # This is a global variable, available everywhere in the program.


def show_local():
    count = 5  # This is a local variable, it exists only inside this function.
    print(f"Inside show_local(), the local count is {count}.")


def change_global():
    global count  # The global keyword lets the function change the global variable.
    count = count + 1
    print(f"Inside change_global(), the global count is now {count}.")


print(f"Before calling the functions, the global count is {count}.")
show_local()
print(f"After show_local(), the global count is still {count}.")
change_global()
print(f"After change_global(), the global count is {count}.")

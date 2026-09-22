# 2. Write a Python program using a function with positional arguments to calculate the area of a rectangle.

def area_of_rectangle(length, breadth):
    return length * breadth


length = float(input("Enter the length of the rectangle: "))
breadth = float(input("Enter the breadth of the rectangle: "))

# length and breadth are passed as positional arguments, so their order matters.
print(f"The area of the rectangle is {area_of_rectangle(length, breadth)}.")

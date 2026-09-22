# 4. Write a Python program using keyword arguments to display the details of a student such as name, roll number, and course.

def student_details(name, roll_number, course):
    print("--- Student Details ---")
    print(f"Name: {name}")
    print(f"Roll Number: {roll_number}")
    print(f"Course: {course}")


name = input("Enter the student's name: ")
roll_number = input("Enter the roll number: ")
course = input("Enter the course: ")

# The values are passed as keyword arguments, so the order does not matter.
student_details(course=course, name=name, roll_number=roll_number)

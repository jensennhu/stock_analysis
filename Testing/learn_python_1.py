# string
# - use three quotes for multi-line
# - x.replace("a", "b")
# - x.lower()

# index
# - type()
# - list[index]
# - list[0] first item 
# - list[-1] last item
# - list[1:3] 2nd and 3rd item
# - list[2:] items from (and including) the third index onward 
# - list[:3] items up to but not including 4th item
# - list[::2] every other item from first index onward

# Dictionary {key : value}
dict = {"a" : 1,
        "b" : 2}
dict.keys()
dict.values()
dict.items()
print(dict["a"])
dict["c"] = 3

# Set - dedupped list
set = {"a", "c", "b"}
sorted(set)
list = ["a", "b", "c", "c", "a"]
list_to_set = set(list)

# Tuple - cannot be changed (immutable)
tuple = (1, 2, 3, 4)
tuple[1]
attendees = tuple(attendees_list)

# if else
x = 7
y = 4
if x >= y;
    print("x greater than or equal to y")
elif x < y:
    print("x less than y")
else:
    print("end")

# For loops
for i in range(1,6):
    print(i)

counter = 0
for i in range(1, 11):
    counter += 1
    print(counter)

# While loop
stock = 10
while num < stock:
    num += 1
    print(num)

# IN, NOT, AND, OR
if "x" in product_dict.keys()
if "x" not in product_dict.keys()
if "x" in product_dict.keys() and min(products_dict.values()) < 5

# appending
list = []
for key, val in product_dict.items():
    if val <= 3:
        list.append(key)

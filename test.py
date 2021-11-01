from os import linesep

file_in = open("input.txt", "r")
file_out = open("output.txt", "w")
unic = {}

lines = file_in.readlines()
arr = lines[1].strip().split(" ")

for i in arr:
    check = unic.get(i)
    if check == None:
        unic[i]=1
    else:
        unic[i]=unic[i]+1

for i in list(unic.keys()):
    if unic[i] > 1:
        unic.pop(i)

file_out.write(str(len(unic)))

file_in.close()
file_out.close()


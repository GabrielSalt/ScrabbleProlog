with open('words.txt', 'r') as file:
    words = file.readlines()

wordString = ""

for word in words:
    word = word.strip()
    if len(word) > 1 and len(word) < 16:
        wordLine = "isWord :- " + word + ".\n"
        wordString = wordString + wordLine

with open('words.pl', 'w') as file:
    file.write(wordString)

print(len(wordString))
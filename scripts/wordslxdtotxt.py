import struct

data = open("UKNA.lxd", "rb").read()
header_size, nnodes = struct.unpack_from("<II", data, 0)
nodes = [
    struct.unpack_from("<I", data, header_size + i * 4)[0]
    for i in range(nnodes)
]

def letter(node):
    return chr((node >> 22) & 0x7F)

def walk(index, prefix, out):
    while True:
        node = nodes[index]
        word = prefix + letter(node)
        if node & (1 << 30):
            out.append(word)
        child = node & 0x1FFFFF
        if child:
            walk(child, word, out)
        if node & (1 << 31):
            return
        index += 1

words = []
walk(nodes[1] & 0x1FFFFF, "", words)  # children of the '*' root

with open("words.txt", "w") as f:
    f.write("\n".join(words) + "\n")

print(len(words))  # 280887
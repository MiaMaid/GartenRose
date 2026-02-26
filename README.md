# GartenRose
assembler fetch
Просто впиши

cd GartenRose

chmod +x rose

./rose




-----------------------------------------------------

Или cкомпилируй ручками

nasm -f elf64 rose.asm -o rose.o

ld -s -n -N --gc-sections rose.o -o rose

./rose

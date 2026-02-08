# GartenRose
assembler fetch
Просто впиши

cd GartenRose

chmod +x rose

./rose




-----------------------------------------------------

Или cкомпилируй ручками

nasm -f elf64 rose.asm -o rose.o

ld rose.o -o rose

./rose

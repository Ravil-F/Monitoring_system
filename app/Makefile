CC = gcc
CFLAGG = -Wall -Wextra -Werror -std=c11

MAIN = main.c
TARGET = simple_app
SOURCE = simple_app.c

# Основная цель - компиляция приложения
install: $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(MAIN)

# Очистка собранных файлов
clean:
	rm -f $(TARGET)

fix_style:
	clang-format -i $(SOURCE) $(MAIN) $(TARGET).h
CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c11

MAIN = main.c
TARGET = simple_app
SOURCE = simple_app.c


# Основная цель - компиляция приложения
$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(MAIN)

# Очистка собранных файлов
clean:
	rm -f $(TARGET)

# Установка приложения в систему
install: $(TARGET)
	cp $(TARGET) /usr/local/bin/
	chmod +x /usr/local/bin/$(TARGET)

fix_style:
	clang-format -i $(SOURCE) $(MAIN) $(TARGET).h
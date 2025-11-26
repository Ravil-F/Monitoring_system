#include "simple_app.h"
int server_socket = -1;


void startServer() {
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len = sizeof(client_addr);
    int client_socket;

    // Регистрируем обработчики сигналов
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);

    logMessage("Starting Simple Web Application on C");

    // Создаем сокет
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        logMessage("ERROR: Failed to create socket");
        exit(1);
    }

    // Настраиваем адрес сервера
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    // Биндим сокет
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        logMessage("ERROR: Failed to bind socket");
        close(server_socket);
        exit(1);
    }

    // Слушаем входящие соединения
    if (listen(server_socket, 10) < 0) {
        logMessage("ERROR: Failed to listen on socket");
        close(server_socket);
        exit(1);
    }

    logMessage("Server is listening on port 8080");

    // Основной цикл сервера
    while (1) {
        client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket < 0) {
            logMessage("ERROR: Failed to accept connection");
            continue;
        }

        // Обрабатываем запрос
        handleRequest(client_socket);
    }
}

void logMessage(const char* message) {
    FILE* log_file = fopen(LOG_FILE, "a");
    if (log_file) {
        time_t now = time(NULL);
        char time_buf[64];
        strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S", localtime(&now));
        fprintf(log_file, "[%s] %s\n", time_buf, message);
        fclose(log_file);
    }
    printf("%s\n", message);  // Исправлено
}

void signalHandler() {
    logMessage("Received shutdown signal, stopping server...");
    if (server_socket != -1) {
        close(server_socket);
    }
    exit(0);
}

void sendHttpResponse(int client_socket, int status_code,
                      const char* status_text, const char* content_type,
                      const char* body) {
  char response[BUFFER_SIZE];
  int length =
      snprintf(response, sizeof(response),
               "HTTP/1.1 %d %s\r\n"
               "Content-Type: %s\r\n"
               "Content-Length: %zu\r\n"
               "Connection: close\r\n"
               "\r\n"
               "%s",
               status_code, status_text, content_type, strlen(body), body);

  send(client_socket, response, length, 0);
}

void handleRequest(int client_socket) {
  char buffer[BUFFER_SIZE];
  ssize_t bytes_read;

  // Читаем запрос от клиента
  bytes_read = recv(client_socket, buffer, sizeof(buffer) - 1, 0);
  if (bytes_read > 0) {
    buffer[bytes_read] = '\0';

    // Логируем запрос
    logMessage("Received HTTP request");

    // Простой парсинг запроса
    if (strstr(buffer, "GET / ") != NULL ||
        strstr(buffer, "GET / HTTP") != NULL) {
      // Главная страница - возвращаем Hello World
      sendHttpResponse(client_socket, 200, "OK", "text/plain",
                       "Hello World!\n");
      logMessage("Served: Hello World");
    } else if (strstr(buffer, "GET /health ") != NULL ||
               strstr(buffer, "GET /health HTTP") != NULL) {
      // Health check endpoint
      sendHttpResponse(
          client_socket, 200, "OK", "application/json",
          "{\"status\": \"healthy\", \"service\": \"simple_app\"}\n");
      logMessage("Served: Health check");
    } else {
      // Страница не найдена
      sendHttpResponse(client_socket, 404, "Not Found", "text/plain",
                       "404 - Page Not Found\n");
      logMessage("Served: 404 Not Found");
    }
  }

  close(client_socket);
}
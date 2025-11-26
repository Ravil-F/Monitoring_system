#ifndef MONITORING_SYSTEM_APP_SYMPLE_APP_H
#define MONITORING_SYSTEM_APP_SYMPLE_APP_H

#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

#define PORT 8080
#define BUFFER_SIZE 1024
#define LOG_FILE "/var/log/simple_app.log"

void startServer();

// Глобальная переменная для сокета (для graceful shutdown)
// extern server_socket;

//ф-ция логирования
void logMessage(const char* message);

//ф-ция для обработки сигналов (graceful shutdown)
void signalHandler();

// Ф-ция для отправки HTTP ответа
void sendHttpResponse(int client_socket, int status_code,
                      const char* status_text, const char* content_type,
                      const char* body);

// Ф-ция обработки HTTP запроса
void handleRequest(int client_socket);

#endif  // MONITORING_SYSTEM_APP_SYMPLE_APP_H